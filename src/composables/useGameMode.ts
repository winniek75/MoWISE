/**
 * MoWISE useGameMode Composable
 * セッション中のゲームモードを管理する
 *
 * データ取得の優先順位:
 *   1. Supabase pattern_content テーブル（P006〜P035 はここにしかない）
 *   2. ローカル patternRegistry（P001〜P005 のフォールバック / オフライン時）
 */

import { ref, type Ref } from 'vue'
import { supabase, isOfflineMode } from '@/lib/supabase'
import { getPatternData } from '@/data/patternRegistry'
import type { Layer2Question, Layer2Choice, Layer3Question, Layer3Tile } from '@/data/p001Questions'
import type { Layer0Question, Layer1Question } from '@/data/layerTypes'
import type { PatternInfo } from '@/data/patternRegistry'
import type { PatternContentRow, PatternRow } from '@/types/database'

// ─────────────────────────────────────────────
// 型
// ─────────────────────────────────────────────

export interface UseGameModeReturn {
  // state
  patternId: Ref<string>
  patternInfo: Ref<PatternInfo | null>
  layer0Questions: Ref<Layer0Question[]>
  layer1Questions: Ref<Layer1Question[]>
  layer2Questions: Ref<Layer2Question[]>
  layer3Questions: Ref<Layer3Question[]>
  isLoading: Ref<boolean>
  loadError: Ref<string | null>

  // actions
  loadPattern: (id: string) => Promise<void>
  isLayer2Passed: (correctCount: number) => boolean
  isLayer3Passed: (correctCount: number) => boolean
}

// ─────────────────────────────────────────────
// DB Row → 各Layer型への変換
// ─────────────────────────────────────────────

interface ChoiceJson {
  text: string
  is_correct: boolean
  explanation?: string
}

function transformToLayer0(rows: PatternContentRow[]): Layer0Question[] {
  return rows.map((r, i) => {
    const choices = (r.choices ?? []) as unknown as ChoiceJson[]
    return {
      id: `${r.pattern_no}-L0-${i + 1}`,
      slowText: r.tts_text_a ?? r.prompt_en ?? '',
      naturalText: r.correct_answer ?? '',
      meaningJa: r.prompt_ja ?? '',
      slowAudio: r.audio_url_a ?? undefined,
      naturalAudio: r.audio_url_b ?? undefined,
      quiz: {
        options: choices.length >= 2
          ? choices.map((c, ci) => ({ id: String.fromCharCode(97 + ci), text: c.text, isNatural: c.is_correct }))
          : [
              { id: 'a', text: r.correct_answer ?? '', isNatural: true },
              { id: 'b', text: r.tts_text_a ?? r.prompt_en ?? '', isNatural: false },
            ],
        explanation: r.explanation_ja ?? r.mowi_quote_correct ?? '',
      },
    }
  })
}

function transformToLayer1(rows: PatternContentRow[]): Layer1Question[] {
  return rows.map((r, i) => {
    const choices = (r.choices ?? []) as unknown as ChoiceJson[]
    return {
      id: `${r.pattern_no}-L1-${i + 1}`,
      sentence: r.correct_answer ?? '',
      hintJa: r.prompt_ja ?? undefined,
      audio: r.audio_url_main ?? undefined,
      choices: choices.map((c, ci) => ({
        id: String.fromCharCode(97 + ci),
        text: c.text,
        isCorrect: c.is_correct,
      })),
      explanation: r.explanation_ja ?? r.mowi_quote_correct ?? undefined,
    }
  })
}

function transformToLayer2(rows: PatternContentRow[]): Layer2Question[] {
  return rows.map((r, i) => {
    const choices = (r.choices ?? []) as unknown as ChoiceJson[]
    // display_text might be "I'm ___" — split into prefix/suffix
    const display = r.display_text ?? r.prompt_en ?? ''
    const blankIdx = display.indexOf('___')
    const slotPrefix = blankIdx >= 0 ? display.substring(0, blankIdx).trim() : display
    const slotSuffix = blankIdx >= 0 ? display.substring(blankIdx + 3).trim() || undefined : undefined

    return {
      id: `${r.pattern_no}-L2-${i + 1}`,
      slotPrefix,
      slotSuffix,
      promptJa: r.prompt_ja ?? '',
      fullSentence: r.correct_answer ?? '',
      correctAudio: r.audio_url_main ?? undefined,
      choices: choices.map((c, ci): Layer2Choice => ({
        id: String.fromCharCode(97 + ci),
        text: c.text,
        isCorrect: c.is_correct,
        wrongReason: c.explanation,
      })),
      explanation: r.explanation_ja ?? r.mowi_quote_correct ?? '',
    }
  })
}

function transformToLayer3(rows: PatternContentRow[]): Layer3Question[] {
  return rows.map((r, i) => {
    const choices = (r.choices ?? []) as unknown as ChoiceJson[]
    const correctSentence = r.correct_answer ?? ''
    const answerWords = correctSentence.split(/\s+/)

    // choices からタイル生成（正解 + ダミー）
    const tiles: Layer3Tile[] = choices.length > 0
      ? choices.map((c, ci): Layer3Tile => ({
          id: `t${ci + 1}`,
          word: c.text,
          isDecoy: !c.is_correct,
        }))
      : answerWords.map((w, wi): Layer3Tile => ({
          id: `t${wi + 1}`,
          word: w,
          isDecoy: false,
        }))

    return {
      id: `${r.pattern_no}-L3-${i + 1}`,
      promptJa: r.prompt_ja ?? '',
      tiles,
      answer: answerWords,
      correctSentence,
      hint: r.context_text ?? undefined,
      timeLimitSec: r.time_limit_sec ?? 8,
      correctAudio: r.audio_url_main ?? undefined,
    }
  })
}

// ─────────────────────────────────────────────
// Composable
// ─────────────────────────────────────────────

export function useGameMode(): UseGameModeReturn {
  const patternId       = ref('')
  const patternInfo     = ref<PatternInfo | null>(null)
  const layer0Questions = ref<Layer0Question[]>([])
  const layer1Questions = ref<Layer1Question[]>([])
  const layer2Questions = ref<Layer2Question[]>([])
  const layer3Questions = ref<Layer3Question[]>([])
  const isLoading       = ref(false)
  const loadError       = ref<string | null>(null)

  /**
   * パターンデータをロードする
   * Supabase 優先 → ローカルフォールバック
   */
  async function loadPattern(id: string): Promise<void> {
    isLoading.value = true
    loadError.value = null

    try {
      patternId.value = id

      // ── 1. Supabase から取得を試みる ──
      if (!isOfflineMode) {
        const { data: rows, error } = await supabase
          .from('pattern_content')
          .select('*')
          .eq('pattern_no', id)
          .order('layer', { ascending: true })
          .order('question_order', { ascending: true })

        if (!error && rows && rows.length > 0) {
          const typed = rows as unknown as PatternContentRow[]
          layer0Questions.value = transformToLayer0(typed.filter(r => r.layer === 0))
          layer1Questions.value = transformToLayer1(typed.filter(r => r.layer === 1))
          layer2Questions.value = transformToLayer2(typed.filter(r => r.layer === 2))
          layer3Questions.value = transformToLayer3(typed.filter(r => r.layer === 3))

          // パターン基本情報も取得
          const { data: patternRow } = await supabase
            .from('patterns')
            .select('*')
            .eq('pattern_no', id)
            .single()

          const pr = patternRow as unknown as PatternRow | null
          if (pr) {
            patternInfo.value = {
              id: pr.pattern_no,
              label: pr.pattern_text,
              labelJa: pr.japanese,
              rarity: pr.rarity,
              area: pr.area,
              layer2QuestionCount: layer2Questions.value.length,
              layer3QuestionCount: layer3Questions.value.length,
              layer2PassThreshold: Math.max(1, layer2Questions.value.length - 1),
              layer3PassThreshold: Math.max(1, layer3Questions.value.length - 2),
            }
          }

          return // Supabase 取得成功
        }
      }

      // ── 2. ローカルフォールバック（P001〜P005） ──
      const data = getPatternData(id)
      if (!data) {
        loadError.value = `パターン ${id} が見つかりません`
        return
      }

      patternInfo.value     = data.info
      layer0Questions.value = data.layer0Questions
      layer1Questions.value = data.layer1Questions
      layer2Questions.value = data.layer2Questions
      layer3Questions.value = data.layer3Questions

    } catch (e) {
      // Supabase エラー時もローカルフォールバック
      console.warn('[useGameMode] Supabase fetch failed, falling back to local:', e)
      const data = getPatternData(id)
      if (data) {
        patternInfo.value     = data.info
        layer0Questions.value = data.layer0Questions
        layer1Questions.value = data.layer1Questions
        layer2Questions.value = data.layer2Questions
        layer3Questions.value = data.layer3Questions
      } else {
        loadError.value = e instanceof Error ? e.message : 'データ読み込みに失敗しました'
      }
    } finally {
      isLoading.value = false
    }
  }

  function isLayer2Passed(correctCount: number): boolean {
    const threshold = patternInfo.value?.layer2PassThreshold ?? 5
    return correctCount >= threshold
  }

  function isLayer3Passed(correctCount: number): boolean {
    const threshold = patternInfo.value?.layer3PassThreshold ?? 5
    return correctCount >= threshold
  }

  return {
    patternId,
    patternInfo,
    layer0Questions,
    layer1Questions,
    layer2Questions,
    layer3Questions,
    isLoading,
    loadError,
    loadPattern,
    isLayer2Passed,
    isLayer3Passed,
  }
}
