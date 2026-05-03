import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase, isOfflineMode } from '@/lib/supabase'
import { useAuthStore } from './auth'
import {
  MORNING_FEELING_LABELS,
  EVENING_FEELING_LABELS,
  type MorningFeelingId,
  type EveningFeelingId,
} from '@/data/checkinOptions'

// ─── Types ────────────────────────────────────────────────────

export type { MorningFeelingId, EveningFeelingId }

export interface CheckinRecord {
  id: string
  user_id: string
  type: 'morning' | 'evening'
  feeling: MorningFeelingId | EveningFeelingId
  mowi_quote_ja: string
  mowi_quote_en: string
  session_date: string // YYYY-MM-DD
  created_at: string
  streak_days?: number
}

interface SaveMorningPayload {
  feeling: MorningFeelingId
  mowiQuoteJa: string
  mowiQuoteEn: string
}

interface SaveEveningPayload {
  feeling: EveningFeelingId
  mowiQuoteJa: string
  mowiQuoteEn: string
}

// ─── ラベル（B-4 再定義版・src/data/checkinOptions.ts を真実の源とする）──

export { MORNING_FEELING_LABELS, EVENING_FEELING_LABELS }

// ─── Store ────────────────────────────────────────────────────

export const useCheckinStore = defineStore('checkin', () => {
  const authStore = useAuthStore()

  // ── State ──────────────────────────────────────────────────
  const todayMorning = ref<CheckinRecord | null>(null)
  const todayEvening = ref<CheckinRecord | null>(null)
  const streakDays = ref(0)
  const isSaving = ref(false)
  const error = ref<string | null>(null)

  // ── Getters ────────────────────────────────────────────────
  const hasMorningCheckin = computed(() => !!todayMorning.value)
  const hasEveningCheckin = computed(() => !!todayEvening.value)
  const hasFullCheckin = computed(
    () => hasMorningCheckin.value && hasEveningCheckin.value
  )

  /** 今日のセッション日付文字列（YYYY-MM-DD・JST） */
  const todayDateStr = computed<string>(() => {
    const now = new Date()
    // 時間帯制御: 04:00起点
    if (now.getHours() < 4) {
      now.setDate(now.getDate() - 1)
    }
    return now.toISOString().slice(0, 10)
  })

  // ── Actions ────────────────────────────────────────────────

  /** 朝チェックイン保存 */
  async function saveMorningCheckin(payload: SaveMorningPayload) {
    if (!authStore.user || isOfflineMode) return
    isSaving.value = true
    error.value = null
    try {
      const { data, error: sbError } = await supabase
        .from('checkins')
        .insert({
          user_id: authStore.user.id,
          type: 'morning',
          feeling: payload.feeling,
          mowi_quote_ja: payload.mowiQuoteJa,
          mowi_quote_en: payload.mowiQuoteEn,
          session_date: todayDateStr.value,
        })
        .select()
        .single()

      if (sbError) throw sbError
      todayMorning.value = data
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Unknown error'
      console.error('[checkin] saveMorningCheckin failed:', e)
    } finally {
      isSaving.value = false
    }
  }

  /** 夜チェックイン保存 */
  async function saveEveningCheckin(payload: SaveEveningPayload) {
    if (!authStore.user || isOfflineMode) return
    isSaving.value = true
    error.value = null
    try {
      const { data, error: sbError } = await supabase
        .from('checkins')
        .insert({
          user_id: authStore.user.id,
          type: 'evening',
          feeling: payload.feeling,
          mowi_quote_ja: payload.mowiQuoteJa,
          mowi_quote_en: payload.mowiQuoteEn,
          session_date: todayDateStr.value,
        })
        .select()
        .single()

      if (sbError) throw sbError
      todayEvening.value = data
    } catch (e: unknown) {
      error.value = e instanceof Error ? e.message : 'Unknown error'
      console.error('[checkin] saveEveningCheckin failed:', e)
    } finally {
      isSaving.value = false
    }
  }

  /** 今日のチェックイン状態をDBから取得 */
  async function fetchTodayCheckins() {
    if (!authStore.user || isOfflineMode) return
    try {
      const { data, error: sbError } = await supabase
        .from('checkins')
        .select('*')
        .eq('user_id', authStore.user.id)
        .eq('session_date', todayDateStr.value)
        .order('created_at', { ascending: true })

      if (sbError) throw sbError

      todayMorning.value = data.find((c: CheckinRecord) => c.type === 'morning') ?? null
      todayEvening.value = data.find((c: CheckinRecord) => c.type === 'evening') ?? null
    } catch (e) {
      console.error('[checkin] fetchTodayCheckins failed:', e)
    }
  }

  /** ストリーク日数取得 */
  async function fetchStreakDays() {
    if (!authStore.user || isOfflineMode) {
      streakDays.value = 0
      return
    }
    try {
      const { data, error: sbError } = await supabase
        .from('checkins')
        .select('session_date')
        .eq('user_id', authStore.user.id)
        .order('session_date', { ascending: false })
        .limit(60)

      if (sbError) throw sbError
      if (!data || data.length === 0) {
        streakDays.value = 0
        return
      }

      // ユニーク日付
      const dates = [...new Set(data.map((c: { session_date: string }) => c.session_date))].sort().reverse()

      let streak = 0
      const cursor = new Date(todayDateStr.value)

      for (const dateStr of dates) {
        const cursorStr = cursor.toISOString().slice(0, 10)
        if (dateStr === cursorStr) {
          streak++
          cursor.setDate(cursor.getDate() - 1)
        } else {
          break
        }
      }

      streakDays.value = streak
    } catch (e) {
      console.error('[checkin] fetchStreakDays failed:', e)
      streakDays.value = 0
    }
  }

  /** 過去チェックイン履歴取得（週次ビュー用） */
  async function fetchRecentCheckins(days = 14) {
    if (!authStore.user || isOfflineMode) return []
    try {
      const from = new Date()
      from.setDate(from.getDate() - days)
      const fromStr = from.toISOString().slice(0, 10)

      const { data, error: sbError } = await supabase
        .from('checkins')
        .select('*')
        .eq('user_id', authStore.user.id)
        .gte('session_date', fromStr)
        .order('session_date', { ascending: false })
        .order('created_at', { ascending: false })

      if (sbError) throw sbError
      return data ?? []
    } catch (e) {
      console.error('[checkin] fetchRecentCheckins failed:', e)
      return []
    }
  }

  // ── Reset ──────────────────────────────────────────────────
  function $reset() {
    todayMorning.value = null
    todayEvening.value = null
    streakDays.value = 0
    isSaving.value = false
    error.value = null
  }

  return {
    // state
    todayMorning,
    todayEvening,
    streakDays,
    isSaving,
    error,
    // getters
    hasMorningCheckin,
    hasEveningCheckin,
    hasFullCheckin,
    todayDateStr,
    // actions
    saveMorningCheckin,
    saveEveningCheckin,
    fetchTodayCheckins,
    fetchStreakDays,
    fetchRecentCheckins,
    $reset,
  }
})
