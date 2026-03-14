/**
 * MoWISE useGameMode Composable
 * セッション中のゲームモードを管理する
 *
 * 責務:
 *  - パターンID + Layer から問題データをロード
 *  - 問題の進行管理（現在のindex、正解数）
 *  - Layer 2 → Layer 3 の遷移判定
 *  - 将来のSupabase接続への差し替えポイント
 */

import { ref, type Ref } from 'vue'
import { getPatternData } from '@/data/patternRegistry'
import type { Layer2Question, Layer3Question } from '@/data/p001Questions'
import type { PatternInfo } from '@/data/patternRegistry'

// ─────────────────────────────────────────────
// 型
// ─────────────────────────────────────────────

export interface UseGameModeReturn {
  // state
  patternId: Ref<string>
  patternInfo: Ref<PatternInfo | null>
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
// Composable
// ─────────────────────────────────────────────

export function useGameMode(): UseGameModeReturn {
  const patternId      = ref('')
  const patternInfo    = ref<PatternInfo | null>(null)
  const layer2Questions = ref<Layer2Question[]>([])
  const layer3Questions = ref<Layer3Question[]>([])
  const isLoading      = ref(false)
  const loadError      = ref<string | null>(null)

  /**
   * パターンデータをロードする
   * 現在はローカルレジストリから取得。
   * Supabase 接続時はここを fetch に差し替えるだけでOK。
   */
  async function loadPattern(id: string): Promise<void> {
    isLoading.value = true
    loadError.value = null

    try {
      // ── ローカルレジストリから取得 ──
      const data = getPatternData(id)
      if (!data) {
        loadError.value = `パターン ${id} が見つかりません`
        return
      }

      patternId.value       = id
      patternInfo.value     = data.info
      layer2Questions.value = data.layer2Questions
      layer3Questions.value = data.layer3Questions

      // ── 将来: Supabase から取得 ──
      // const { data: rows, error } = await supabase
      //   .from('pattern_content')
      //   .select('*')
      //   .eq('pattern_no', id)
      //   .order('layer', { ascending: true })
      //   .order('question_no', { ascending: true })
      //
      // if (error) throw error
      // layer2Questions.value = transformToLayer2(rows.filter(r => r.layer === 2))
      // layer3Questions.value = transformToLayer3(rows.filter(r => r.layer === 3))

    } catch (e) {
      loadError.value = e instanceof Error ? e.message : 'データ読み込みに失敗しました'
      console.error('[useGameMode] loadPattern error:', e)
    } finally {
      isLoading.value = false
    }
  }

  /**
   * Layer 2 のクリア判定
   */
  function isLayer2Passed(correctCount: number): boolean {
    const threshold = patternInfo.value?.layer2PassThreshold ?? 5
    return correctCount >= threshold
  }

  /**
   * Layer 3 のクリア判定
   */
  function isLayer3Passed(correctCount: number): boolean {
    const threshold = patternInfo.value?.layer3PassThreshold ?? 5
    return correctCount >= threshold
  }

  return {
    patternId,
    patternInfo,
    layer2Questions,
    layer3Questions,
    isLoading,
    loadError,
    loadPattern,
    isLayer2Passed,
    isLayer3Passed,
  }
}
