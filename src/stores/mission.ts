// ============================================================
// stores/mission.ts — Daily missions & login streaks
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface MissionDefinition {
  id: string
  title_ja: string
  description_ja: string
  condition_type: string
  condition_value: number
  reward_type: string
  reward_amount: number
  difficulty: number
}

export interface UserMission {
  id: string
  user_id: string
  mission_id: string
  mission_date: string
  progress: number
  target: number
  completed: boolean
  reward_claimed: boolean
  completed_at?: string
  // Joined
  mission_definitions?: MissionDefinition
}

export interface StreakInfo {
  streak: number
  milestone?: string
  reward_coins?: number
  reward_tickets?: number
  already_logged?: boolean
}

export const useMissionStore = defineStore('mission', () => {
  const todayMissions = ref<UserMission[]>([])
  const streakInfo = ref<StreakInfo | null>(null)
  const loading = ref(false)

  const completedCount = computed(() => todayMissions.value.filter(m => m.completed).length)
  const totalCount = computed(() => todayMissions.value.length)
  const allCompleted = computed(() => totalCount.value > 0 && completedCount.value === totalCount.value)
  const allClaimed = computed(() => todayMissions.value.every(m => m.reward_claimed))

  const difficultyLabel = (d: number) => ['', '★', '★★', '★★★'][d] ?? ''
  const difficultyColor = (d: number) => ['', 'text-neon-green', 'text-neon-yellow', 'text-neon-pink'][d] ?? ''

  async function fetchTodayMissions(userId: string) {
    loading.value = true
    // Generate if not exists, then fetch
    const { data } = await supabase.rpc('generate_daily_missions', { p_user_id: userId })
    if (data) {
      // Re-fetch with joined definitions
      const { data: missions } = await supabase
        .from('user_daily_missions')
        .select('*, mission_definitions(*)')
        .eq('user_id', userId)
        .eq('mission_date', new Date().toISOString().slice(0, 10))
        .order('created_at')
      todayMissions.value = missions ?? []
    }
    loading.value = false
  }

  async function updateMissionProgress(userId: string, conditionType: string, value: number = 1, extra?: string) {
    // Find matching uncompleted missions
    for (const m of todayMissions.value) {
      if (m.completed) continue
      const def = m.mission_definitions
      if (!def || def.condition_type !== conditionType) continue
      if (def.condition_extra && def.condition_extra !== extra) continue

      let newProgress = m.progress

      if (conditionType === 'accuracy_above') {
        // For accuracy, check if value meets threshold
        if (value >= def.condition_value) {
          newProgress = 1
        }
      } else if (conditionType === 'play_category') {
        // Track unique categories played today (stored in metadata)
        newProgress = value // caller passes unique category count
      } else {
        newProgress = m.progress + value
      }

      const completed = newProgress >= m.target

      await supabase
        .from('user_daily_missions')
        .update({
          progress: newProgress,
          completed,
          completed_at: completed ? new Date().toISOString() : null,
        })
        .eq('id', m.id)

      m.progress = newProgress
      m.completed = completed
      if (completed) m.completed_at = new Date().toISOString()
    }
  }

  async function claimReward(missionId: string): Promise<{ reward_type: string; reward_amount: number } | null> {
    const { data, error } = await supabase.rpc('claim_mission_reward', { p_mission_id: missionId })
    if (error) { console.error('[mission] claim:', error); return null }
    // Update local state
    const m = todayMissions.value.find(m => m.id === missionId)
    if (m) m.reward_claimed = true
    return data as { reward_type: string; reward_amount: number }
  }

  async function updateLoginStreak(userId: string): Promise<StreakInfo | null> {
    const { data, error } = await supabase.rpc('update_login_streak', { p_user_id: userId })
    if (error) { console.error('[mission] streak:', error); return null }
    streakInfo.value = data as StreakInfo
    return streakInfo.value
  }

  return {
    todayMissions, streakInfo, loading,
    completedCount, totalCount, allCompleted, allClaimed,
    difficultyLabel, difficultyColor,
    fetchTodayMissions, updateMissionProgress, claimReward, updateLoginStreak,
  }
})
