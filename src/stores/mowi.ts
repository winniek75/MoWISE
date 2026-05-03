import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase, isOfflineMode } from '@/lib/supabase'
import { useAuthStore } from './auth'
import type { MorningFeelingId, EveningFeelingId } from './checkin'

// ─── Types ────────────────────────────────────────────────────

/**
 * Mowiの感情ステート
 * - idle   : 通常浮遊（ホーム待機）
 * - joy    : 正解・ストリーク・自信がある
 * - sad    : 不正解・不安
 * - think  : ヒント・わからない
 * - grow   : ↑アップ・レベルアップ
 * - sleep  : 3日以上未ログイン
 * - cheer  : 課題開始
 * - tomorrow : セッション終了
 */
export type MowiEmotionState =
  | 'idle'
  | 'joy'
  | 'sad'
  | 'think'
  | 'grow'
  | 'sleep'
  | 'cheer'
  | 'tomorrow'

// ─── 朝チェックイン → Mowi感情マップ（B-4再定義版・5択） ────
const MORNING_FEELING_TO_STATE: Record<MorningFeelingId, MowiEmotionState> = {
  morning_great:  'joy',
  morning_doable: 'cheer',
  morning_normal: 'idle',
  morning_heavy:  'sad',
  morning_nope:   'think',
}

// ─── 夜チェックイン → Mowi感情マップ（B-4再定義版・5択） ────
const EVENING_FEELING_TO_STATE: Record<EveningFeelingId, MowiEmotionState> = {
  evening_done:     'joy',
  evening_came_out: 'cheer',
  evening_normal:   'idle',
  evening_drained:  'sad',
  evening_nope:     'sleep',
}

// ─── 朝×夜の組み合わせによるhappiness変化（25通り）────────────
// 「逆転演出」を踏襲：朝が低いほど夜のポジ結果で大きく加点
const COMBO_HAPPINESS_DELTA: Record<string, number> = {
  // evening_done（やりきった: 5）
  'morning_great-evening_done':   +8,
  'morning_doable-evening_done':  +8,
  'morning_normal-evening_done':  +9,
  'morning_heavy-evening_done':   +10,
  'morning_nope-evening_done':    +12, // 最大逆転演出（無理かも → やりきった）
  // evening_came_out（出せた感じ: 4）
  'morning_great-evening_came_out':   +6,
  'morning_doable-evening_came_out':  +7,
  'morning_normal-evening_came_out':  +7,
  'morning_heavy-evening_came_out':   +8,
  'morning_nope-evening_came_out':    +10,
  // evening_normal（ふつう: 3）
  'morning_great-evening_normal':   +1,
  'morning_doable-evening_normal':  +2,
  'morning_normal-evening_normal':  +2,
  'morning_heavy-evening_normal':   +3,
  'morning_nope-evening_normal':    +4,
  // evening_drained（疲れた: 2）
  'morning_great-evening_drained':   -1,
  'morning_doable-evening_drained':   0,
  'morning_normal-evening_drained':   0,
  'morning_heavy-evening_drained':   +1,
  'morning_nope-evening_drained':    +2,
  // evening_nope（もう無理: 1）
  'morning_great-evening_nope':   -3,
  'morning_doable-evening_nope':  -2,
  'morning_normal-evening_nope':  -1,
  'morning_heavy-evening_nope':    0,
  'morning_nope-evening_nope':    +1, // 一貫してネガでも、来た事実
}

// ─── Store ────────────────────────────────────────────────────
export const useMowiStore = defineStore('mowi', () => {
  const authStore = useAuthStore()

  // ── State ──────────────────────────────────────────────────
  const happiness = ref(50)      // 0-100
  const growthStage = ref(1)     // 0-5
  const brightness = ref(5)      // 0-10
  const lastInteractionAt = ref<string | null>(null)
  const emotionState = ref<MowiEmotionState>('idle')
  const isLoading = ref(false)

  // 今日のチェックインフィーリング（combo計算用）
  const todayMorningFeeling = ref<MorningFeelingId | null>(null)
  const todayEveningFeeling = ref<EveningFeelingId | null>(null)

  // M4: ベースレベル（毎日リセット想定）
  const baseLevel = ref(5)

  // ── Getters ────────────────────────────────────────────────

  /** brightness (0-10) を 0.0-1.0 に正規化 */
  const normalizedBrightness = computed(() => brightness.value / 10)

  /** happiness を 0.0-1.0 に正規化 */
  const normalizedHappiness = computed(() => happiness.value / 100)

  /**
   * CSS filter: grayscale(%) → growthStage 0=完全グレー、5=フルカラー
   */
  const grayscaleFilter = computed(() => {
    const percent = Math.max(0, (5 - growthStage.value) * 20)
    return `grayscale(${percent}%)`
  })

  /** 朝・夜両方チェックイン済みか */
  const hasBothCheckins = computed(() =>
    todayMorningFeeling.value !== null && todayEveningFeeling.value !== null
  )

  /** ホーム用brightness（brightnessのエイリアス） */
  const homeBrightness = computed(() => brightness.value)

  /** コンボ輝きカラー */
  const comboColor = computed(() => {
    if (brightness.value >= 10) return 'rainbow'
    if (brightness.value >= 7)  return '#FF9800'
    if (brightness.value >= 5)  return '#9C27B0'
    if (brightness.value >= 3)  return '#64B5F6'
    return '#4A7AFF'
  })

  // ── Actions ────────────────────────────────────────────────

  /** DBからMowi状態を取得 */
  async function fetchMowiState() {
    if (!authStore.user || isOfflineMode) return
    isLoading.value = true
    try {
      const { data, error } = await supabase
        .from('mowi_state')
        .select('*')
        .eq('user_id', authStore.user.id)
        .single()

      if (error && error.code !== 'PGRST116') throw error

      if (data) {
        happiness.value = data.happiness ?? 50
        growthStage.value = data.growth_stage ?? 1
        brightness.value = data.brightness ?? 5
        lastInteractionAt.value = data.last_interaction_at
      } else {
        await upsertMowiState()
      }
    } catch (e) {
      console.error('[mowi] fetchMowiState failed:', e)
    } finally {
      isLoading.value = false
    }
  }

  /** 朝チェックインに応じてMowi状態更新 */
  async function updateAfterMorningCheckin(feeling: MorningFeelingId) {
    todayMorningFeeling.value = feeling
    emotionState.value = MORNING_FEELING_TO_STATE[feeling]

    const delta = feeling === 'morning_great' ? +3
      : feeling === 'morning_doable' ? +2
      : feeling === 'morning_normal' ? +1
      : feeling === 'morning_heavy' ? -1
      : feeling === 'morning_nope' ? -2
      : 0

    happiness.value = clamp(happiness.value + delta, 0, 100)
    await upsertMowiState()
  }

  /** 夜チェックインに応じてMowi状態更新（朝×夜コンボ計算含む） */
  async function updateAfterEveningCheckin(feeling: EveningFeelingId) {
    todayEveningFeeling.value = feeling
    emotionState.value = EVENING_FEELING_TO_STATE[feeling]

    let delta = 0
    if (todayMorningFeeling.value) {
      const comboKey = `${todayMorningFeeling.value}-${feeling}`
      delta = COMBO_HAPPINESS_DELTA[comboKey] ?? 0
    }

    happiness.value = clamp(happiness.value + delta, 0, 100)
    brightness.value = Math.round(happiness.value / 10)
    await upsertMowiState()
  }

  /** 練習セッション正解によるbrightnessアップ */
  async function incrementBrightness(amount = 1) {
    brightness.value = clamp(brightness.value + amount, 0, 10)
    happiness.value  = clamp(happiness.value + amount * 2, 0, 100)
    emotionState.value = 'joy'
    await upsertMowiState()
  }

  /** 練習セッション不正解によるbrightnessわずかな下降 */
  async function decrementBrightness(amount = 1) {
    brightness.value = clamp(brightness.value - amount, 0, 10)
    emotionState.value = 'sad'
    await upsertMowiState()
  }

  /** emotionStateだけ変更（DB保存なし） */
  function setEmotionState(state: MowiEmotionState) {
    emotionState.value = state
  }

  // ── M4: brightness計算ロジック ─────────────────────────────

  /** M4 brightness計算ヘルパー */
  function _computeHomeBrightness(correctRate?: number): number {
    const morningOffset: Record<MorningFeelingId, number> = {
      morning_great:  +2,
      morning_doable: +1,
      morning_normal:  0,
      morning_heavy:  -1,
      morning_nope:   -2,
    }
    const eveningOffset: Record<EveningFeelingId, number> = {
      evening_done:     +2,
      evening_came_out: +2,
      evening_normal:    0,
      evening_drained:  -1,
      evening_nope:     -2,
    }

    let score = baseLevel.value
    if (todayMorningFeeling.value) score += morningOffset[todayMorningFeeling.value]
    if (todayEveningFeeling.value) score += eveningOffset[todayEveningFeeling.value]
    if (correctRate !== undefined) {
      if (correctRate >= 0.8) score += 1
      else if (correctRate < 0.5) score -= 1
    }
    return clamp(score, 1, 10)
  }

  /**
   * チェックイン後にbrightnessを再計算してDB保存
   * type: 'morning' | 'night'
   */
  async function updateMowiStateAfterCheckin(
    type: 'morning' | 'night',
    feelingId: MorningFeelingId | EveningFeelingId,
  ) {
    if (type === 'morning') {
      todayMorningFeeling.value = feelingId as MorningFeelingId
      emotionState.value = MORNING_FEELING_TO_STATE[feelingId as MorningFeelingId]
    } else {
      todayEveningFeeling.value = feelingId as EveningFeelingId
      emotionState.value = EVENING_FEELING_TO_STATE[feelingId as EveningFeelingId]
    }
    brightness.value = _computeHomeBrightness()
    happiness.value = clamp(brightness.value * 10, 0, 100)
    await upsertMowiState()
  }

  /** セッション終了後にbrightnessを正解率で更新 */
  async function updateAfterSession(correctRate: number) {
    brightness.value = _computeHomeBrightness(correctRate)
    happiness.value = clamp(brightness.value * 10, 0, 100)
    if (correctRate >= 0.8) emotionState.value = 'grow'
    else if (correctRate >= 0.5) emotionState.value = 'joy'
    else emotionState.value = 'idle'
    await upsertMowiState()
  }

  /** オンボーディング: 初めての正解でMowiが光る */
  async function unlockFirstLight(_userId?: string) {
    brightness.value = 3
    happiness.value = 30
    growthStage.value = 1
    emotionState.value = 'grow'
    await upsertMowiState()
  }

  /** Supabase upsert */
  async function upsertMowiState() {
    if (!authStore.user || isOfflineMode) return
    try {
      await supabase
        .from('mowi_state')
        .upsert({
          user_id: authStore.user.id,
          happiness: happiness.value,
          growth_stage: growthStage.value,
          brightness: brightness.value,
          last_interaction_at: new Date().toISOString(),
        }, { onConflict: 'user_id' })
    } catch (e) {
      console.error('[mowi] upsertMowiState failed:', e)
    }
  }

  // ── Helpers ────────────────────────────────────────────────
  function clamp(val: number, min: number, max: number): number {
    return Math.min(Math.max(val, min), max)
  }

  // ── Reset ──────────────────────────────────────────────────
  function $reset() {
    happiness.value = 50
    growthStage.value = 1
    brightness.value = 5
    baseLevel.value = 5
    lastInteractionAt.value = null
    emotionState.value = 'idle'
    todayMorningFeeling.value = null
    todayEveningFeeling.value = null
  }

  return {
    // state
    happiness,
    growthStage,
    brightness,
    baseLevel,
    lastInteractionAt,
    emotionState,
    isLoading,
    todayMorningFeeling,
    todayEveningFeeling,
    // getters
    normalizedBrightness,
    normalizedHappiness,
    grayscaleFilter,
    comboColor,
    hasBothCheckins,
    homeBrightness,
    // actions
    fetchMowiState,
    updateAfterMorningCheckin,
    updateAfterEveningCheckin,
    updateMowiStateAfterCheckin,
    updateAfterSession,
    unlockFirstLight,
    incrementBrightness,
    decrementBrightness,
    setEmotionState,
    upsertMowiState,
    $reset,
  }
})
