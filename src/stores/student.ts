// ============================================================
// stores/student.ts - Student-side state (assignments, ranking)
// ============================================================
import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Assignment {
  id: string
  class_id: string
  teacher_id: string
  game_id: string
  title?: string
  instructions?: string
  due_date?: string
  config: Record<string, unknown>
  status: string
  created_at: string
  // Joined fields
  game_title_ja?: string
  game_icon?: string
  game_url?: string
  class_name?: string
  // Progress
  my_best_score?: number
  my_completed?: boolean
}

export interface LeaderboardEntry {
  user_id: string
  display_name: string
  avatar_url?: string
  total_score: number
  total_xp: number
  games_played: number
  avg_accuracy?: number
  rank?: number
}

export const useStudentStore = defineStore('student', () => {
  const myAssignments = ref<Assignment[]>([])
  const leaderboard = ref<LeaderboardEntry[]>([])
  const myClasses = ref<any[]>([])
  const loading = ref(false)

  async function fetchMyClasses(userId: string) {
    const { data, error } = await supabase
      .from('class_members')
      .select('class_id, status, classes(id, class_name, class_code, teacher_id, users!teacher_id(display_name))')
      .eq('user_id', userId)
      .eq('status', 'approved')
    if (error) { console.error('[student] fetchMyClasses:', error); return }
    myClasses.value = data ?? []
  }

  async function joinClass(userId: string, classCode: string) {
    // Find class by code
    const { data: cls, error: findErr } = await supabase
      .from('classes')
      .select('id')
      .eq('class_code', classCode.toUpperCase())
      .eq('status', 'active')
      .single()
    if (findErr || !cls) {
      throw new Error('クラスが見つかりません。コードを確認してください。')
    }
    // Join
    const { error: joinErr } = await supabase
      .from('class_members')
      .insert({
        class_id: cls.id,
        user_id: userId,
        status: 'pending',
        joined_via_code: classCode.toUpperCase(),
      })
    if (joinErr) {
      if (joinErr.code === '23505') throw new Error('既にこのクラスに参加済みです。')
      throw new Error(joinErr.message)
    }
    return cls.id
  }

  async function fetchMyAssignments(userId: string) {
    loading.value = true
    // Get user's class IDs
    const { data: memberships } = await supabase
      .from('class_members')
      .select('class_id')
      .eq('user_id', userId)
      .eq('status', 'approved')
    if (!memberships || memberships.length === 0) {
      myAssignments.value = []
      loading.value = false
      return
    }
    const classIds = memberships.map(m => m.class_id)

    // Fetch assignments with game info
    const { data, error } = await supabase
      .from('assignments')
      .select('*, game_catalog!game_id(title_ja, icon, url), classes!class_id(class_name)')
      .in('class_id', classIds)
      .eq('status', 'active')
      .order('created_at', { ascending: false })
    if (error) { console.error('[student] fetchAssignments:', error); loading.value = false; return }

    // Get my scores for these assignments
    const assignmentIds = (data ?? []).map(a => a.id)
    let myScores: Record<string, { score: number; completed: boolean }> = {}
    if (assignmentIds.length > 0) {
      const { data: scores } = await supabase
        .from('game_scores')
        .select('assignment_id, score, completed')
        .eq('user_id', userId)
        .in('assignment_id', assignmentIds)
      if (scores) {
        for (const s of scores) {
          if (!myScores[s.assignment_id] || s.score > myScores[s.assignment_id].score) {
            myScores[s.assignment_id] = { score: s.score, completed: s.completed }
          }
        }
      }
    }

    myAssignments.value = (data ?? []).map(a => ({
      ...a,
      game_title_ja: (a as any).game_catalog?.title_ja,
      game_icon: (a as any).game_catalog?.icon,
      game_url: (a as any).game_catalog?.url,
      class_name: (a as any).classes?.class_name,
      my_best_score: myScores[a.id]?.score,
      my_completed: myScores[a.id]?.completed ?? false,
    }))
    loading.value = false
  }

  async function fetchClassLeaderboard(classId: string) {
    const { data, error } = await supabase
      .from('class_leaderboard')
      .select('*')
      .eq('class_id', classId)
      .order('total_xp', { ascending: false })
      .limit(50)
    if (error) { console.error('[student] fetchLeaderboard:', error); return }
    leaderboard.value = (data ?? []).map((entry, i) => ({
      ...entry,
      rank: i + 1,
    }))
  }

  return {
    myAssignments, leaderboard, myClasses, loading,
    fetchMyClasses, joinClass, fetchMyAssignments, fetchClassLeaderboard,
  }
})
