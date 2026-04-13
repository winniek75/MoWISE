/**
 * MoWISE Session Store
 * Step M-2：練習セッション状態管理
 *
 * 参照設計書：
 *   MoWISE_H2_コアゲームループUI設計_v1_0.md（コンボ・輝度ロジック）
 *   MoWISE_実装開始_引き継ぎ_20260311.md（M-2仕様）
 */

import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
// import { supabase } from '@/lib/supabase'  // Step K で接続済みの場合に有効化

// ─────────────────────────────────────────────
// 型定義
// ─────────────────────────────────────────────

export interface SessionPattern {
  patternId: string        // 'P001'
  patternLabel: string     // '[代名詞] + be動詞 + [状態/情報]'
  patternJa: string        // '〜は…です'
  currentStar: number      // 現在の★数
  startLayer: 0 | 1 | 2 | 3  // どのLayerから始めるか
  isWeakPoint?: boolean    // AI弱点補強フラグ
}

export type MowiEmotionState = 'idle' | 'cheer' | 'joy' | 'sad' | 'think' | 'grow'

// ─────────────────────────────────────────────
// Store
// ─────────────────────────────────────────────

export const useSessionStore = defineStore('session', () => {

  // ── セッション識別子 ──
  const sessionId = ref<string | null>(null)

  // ── パターン構成 ──
  const sessionPatterns = ref<SessionPattern[]>([])
  const currentPatternIndex = ref(0)
  const currentLayer = ref<0 | 1 | 2 | 3>(0)

  // ── スコア ──
  const combo = ref(0)
  const maxCombo = ref(0)
  const totalQuestions = ref(0)
  const correctCount = ref(0)
  const wrongCount = ref(0)
  const xpEarned = ref(0)

  // ── Mowi感情ステート ──
  const mowiEmotionState = ref<MowiEmotionState>('cheer')
  const mowiDialogue = ref<string>('')

  // ── セッション状態 ──
  const isActive = ref(false)
  const layer2Cleared = ref(false)
  const layer3Cleared = ref(false)

  // ── ★UP / 新パターン解禁（PATTERN_MASTER / PATTERN_UNLOCK 用） ──
  /** セッション中に★5に到達したパターン（null = なし） */
  const masteredPattern = ref<{ patternId: string; patternLabel: string; patternJa: string; evolutionId?: string; evolutionText?: string } | null>(null)
  /** セッション中に新たに解禁されたパターン（null = なし） */
  const unlockedPattern = ref<{ patternId: string; patternLabel: string; patternJa: string } | null>(null)

  // ─────────────────────────────────────────────
  // Computed
  // ─────────────────────────────────────────────

  const accuracy = computed(() =>
    totalQuestions.value > 0
      ? Math.round((correctCount.value / totalQuestions.value) * 100)
      : 0
  )

  const currentPattern = computed(() =>
    sessionPatterns.value[currentPatternIndex.value] ?? null
  )

  /**
   * コンボ → 輝度レベル（0〜10）
   * H2設計書 ⑪ compute_brightness() ロジック準拠
   */
  const brightness = computed(() => {
    const c = combo.value
    if (c === 0)  return 3
    if (c <= 2)   return 4
    if (c <= 4)   return 6
    if (c <= 6)   return 7
    if (c <= 9)   return 9
    return 10
  })

  /**
   * コンボ → ゲージカラー
   * H2設計書 ⑤ コンボゲージビジュアル仕様準拠
   */
  const comboColor = computed(() => {
    const c = combo.value
    if (c >= 10) return 'rainbow'
    if (c >= 7)  return '#FF9800'
    if (c >= 5)  return '#9C27B0'
    if (c >= 3)  return '#64B5F6'
    return '#9E9E9E'
  })

  const comboLabel = computed(() => {
    const c = combo.value
    if (c >= 10) return '限界が、広がってる。'
    if (c >= 7)  return '止まれない。'
    if (c >= 5)  return 'どんどん出てくる。'
    if (c >= 3)  return 'つながってる。'
    return ''
  })

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  /**
   * セッション開始
   */
  async function startSession(patterns: SessionPattern[]) {
    sessionPatterns.value = patterns
    currentPatternIndex.value = 0
    currentLayer.value = patterns[0]?.startLayer ?? 0
    combo.value = 0
    maxCombo.value = 0
    totalQuestions.value = 0
    correctCount.value = 0
    wrongCount.value = 0
    xpEarned.value = 0
    layer2Cleared.value = false
    layer3Cleared.value = false
    isActive.value = true
    mowiEmotionState.value = 'cheer'
    mowiDialogue.value = '今日のセッション、始まる。'

    // Supabase: sessions テーブルに INSERT
    // const { data, error } = await supabase
    //   .from('sessions')
    //   .insert({
    //     user_id: authStore.user.id,
    //     session_date: new Date().toISOString().split('T')[0],
    //     pattern_ids: patterns.map(p => p.patternId),
    //     status: 'in_progress',
    //   })
    //   .select()
    //   .single()
    // sessionId.value = data?.id ?? null

    sessionId.value = `local-${Date.now()}`
  }

  /**
   * 正解・不正解の記録
   * @param isCorrect 正解か
   */
  function recordAnswer(isCorrect: boolean) {
    totalQuestions.value++

    if (isCorrect) {
      correctCount.value++
      combo.value++
      if (combo.value > maxCombo.value) {
        maxCombo.value = combo.value
      }
      // XP: 基本5 + コンボボーナス
      const baseXp = 5
      const bonus = combo.value >= 10 ? 15
                  : combo.value >= 5  ? 6
                  : combo.value >= 3  ? 3
                  : 0
      xpEarned.value += baseXp + bonus

      // Mowi感情更新
      mowiEmotionState.value = 'joy'
      const joyLines = [
        '出た。ちゃんと出た。',
        '体に入った。もう忘れない。',
        '自然に出た。',
        '口が、覚えてる。',
        '迷わなかった。',
      ]
      mowiDialogue.value = joyLines[Math.floor(Math.random() * joyLines.length)]

      // コンボマイルストーン
      if (combo.value === 3)  mowiDialogue.value = 'つながってる。'
      if (combo.value === 5)  mowiDialogue.value = 'どんどん出てくる。'
      if (combo.value === 7)  mowiDialogue.value = '止まれない。'
      if (combo.value === 10) mowiDialogue.value = '限界が、広がってる。'

    } else {
      wrongCount.value++
      const prevCombo = combo.value
      combo.value = 0
      xpEarned.value += 1 // 慰め XP

      mowiEmotionState.value = 'sad'
      mowiDialogue.value = prevCombo >= 3
        ? '止まった。また積む。'
        : '…なんか変。'
    }

    // Supabase: question_logs テーブルに INSERT
    // await supabase.from('question_logs').insert({
    //   session_id: sessionId.value,
    //   user_id: authStore.user.id,
    //   pattern_id: currentPattern.value?.patternId,
    //   layer: currentLayer.value,
    //   is_correct: isCorrect,
    //   combo_at_time: combo.value,
    // })
  }

  /**
   * Layer 2 完了通知
   */
  function completeLayer2() {
    layer2Cleared.value = true
    currentLayer.value = 3
    mowiEmotionState.value = 'grow'
    mowiDialogue.value = '並びが見えてきた'
  }

  /**
   * Layer 3 完了通知
   */
  function completeLayer3() {
    layer3Cleared.value = true
    mowiEmotionState.value = 'grow'
    mowiDialogue.value = '口が先に動いた'
  }

  /**
   * セッション終了
   */
  async function endSession() {
    isActive.value = false

    // Supabase: sessions テーブルを更新
    // await supabase
    //   .from('sessions')
    //   .update({
    //     ended_at: new Date().toISOString(),
    //     total_questions: totalQuestions.value,
    //     correct_count: correctCount.value,
    //     wrong_count: wrongCount.value,
    //     max_combo: maxCombo.value,
    //     xp_earned: xpEarned.value,
    //     status: 'completed',
    //   })
    //   .eq('id', sessionId.value)
  }

  /**
   * ストア初期化
   */
  function $reset() {
    sessionId.value = null
    sessionPatterns.value = []
    currentPatternIndex.value = 0
    currentLayer.value = 0
    combo.value = 0
    maxCombo.value = 0
    totalQuestions.value = 0
    correctCount.value = 0
    wrongCount.value = 0
    xpEarned.value = 0
    layer2Cleared.value = false
    layer3Cleared.value = false
    masteredPattern.value = null
    unlockedPattern.value = null
    isActive.value = false
    mowiEmotionState.value = 'idle'
    mowiDialogue.value = ''
  }

  return {
    // state
    sessionId,
    sessionPatterns,
    currentPatternIndex,
    currentLayer,
    combo,
    maxCombo,
    totalQuestions,
    correctCount,
    wrongCount,
    xpEarned,
    mowiEmotionState,
    mowiDialogue,
    isActive,
    layer2Cleared,
    layer3Cleared,
    masteredPattern,
    unlockedPattern,
    // computed
    accuracy,
    currentPattern,
    brightness,
    comboColor,
    comboLabel,
    // actions
    startSession,
    recordAnswer,
    completeLayer2,
    completeLayer3,
    endSession,
    $reset,
  }
})
