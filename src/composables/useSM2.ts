// ============================================================
// composables/useSM2.ts — SM-2スペースドリピティションアルゴリズム
// MoWISE スキーマ v1.0 仕様準拠
// ============================================================

export interface SM2Update {
  ease_factor:   number   // 現在のEF（初期: 2.50）
  interval_days: number   // 現在の間隔（初期: 1）
  times_seen:    number   // 連続正解数（初期: 0）
  quality:       number   // 回答品質 0〜5
}

/**
 * SM-2 アルゴリズムで次の interval と ease_factor を計算する
 */
export function calculateSM2(current: SM2Update): SM2Update {
  const { ease_factor, interval_days, times_seen, quality } = current

  let new_interval:    number
  let new_ease_factor: number
  let new_times_seen:  number = times_seen + 1

  if (quality < 3) {
    // 不正解・タイムアウト → リセット
    new_interval    = 1
    new_ease_factor = Math.max(1.30, ease_factor - 0.20)
    new_times_seen  = 0
  } else {
    // 正解時の interval 計算
    if (times_seen === 0) {
      new_interval = 1
    } else if (times_seen === 1) {
      new_interval = 6
    } else {
      new_interval = Math.round(interval_days * ease_factor)
    }

    // EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
    new_ease_factor = ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    new_ease_factor = Math.min(5.00, Math.max(1.30, new_ease_factor))
  }

  return {
    ease_factor:   parseFloat(new_ease_factor.toFixed(2)),
    interval_days: new_interval,
    times_seen:    new_times_seen,
    quality,
  }
}

/**
 * 回答品質スコア（0〜5）を決定する
 * MoWISE 独自のルール（スキーマ v1.0 SM-2ガイド準拠）
 */
export function calcQualityRating(
  is_correct:          boolean,
  response_time_ms:    number,
  time_limit_ms:       number,
  hint_used:           boolean,
  consecutive_wrong:   number,
): number {
  if (!is_correct) {
    if (response_time_ms >= time_limit_ms) return 2    // タイムアウト
    if (consecutive_wrong >= 3)           return 0    // 連続3回以上不正解
    return 1                                           // 通常不正解
  }
  if (hint_used)                               return 3  // ヒント使用で正解
  if (response_time_ms <= time_limit_ms * 0.5) return 5  // 制限時間の50%以内
  return 4                                              // 通常正解
}
