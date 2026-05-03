/**
 * チェックイン選択肢（B-4再定義版）
 *
 * 質問の主語を英語からコンディションに振り替え、5段（ポジ2/中立1/ネガ2）に拡張。
 * 旧ID（v3.0: morning_confident/okay/anxious/unsure, evening_said_it/fun/hard/not_quite）
 * から新IDへ移行する。スキーマは TEXT のまま。
 *
 * 内部コード・DB カラム名は `morning_feeling` / `evening_feeling` を保持。
 * UI 表示は本ファイルの定数を真実の源として参照する。
 */

export type MorningFeelingId =
  | 'morning_great'
  | 'morning_doable'
  | 'morning_normal'
  | 'morning_heavy'
  | 'morning_nope'

export type EveningFeelingId =
  | 'evening_done'
  | 'evening_came_out'
  | 'evening_normal'
  | 'evening_drained'
  | 'evening_nope'

export type CheckinOptionId = MorningFeelingId | EveningFeelingId

export interface CheckinOption {
  id: CheckinOptionId
  ja: string
  en: string
  emoji: string
  score: 1 | 2 | 3 | 4 | 5
}

export const MORNING_OPTIONS: CheckinOption[] = [
  { id: 'morning_great',  ja: 'いい朝',     en: 'Feeling good', emoji: '✨',     score: 5 },
  { id: 'morning_doable', ja: 'いけそう',   en: 'Doable',       emoji: '🙂',     score: 4 },
  { id: 'morning_normal', ja: 'ふつう',     en: 'Just normal',  emoji: '😐',     score: 3 },
  { id: 'morning_heavy',  ja: 'だるい',     en: 'A bit heavy',  emoji: '😮‍💨',   score: 2 },
  { id: 'morning_nope',   ja: '無理かも',   en: 'Not today',    emoji: '😵',     score: 1 },
]

export const EVENING_OPTIONS: CheckinOption[] = [
  { id: 'evening_done',      ja: 'やりきった',   en: 'Got it done',          emoji: '🎉', score: 5 },
  { id: 'evening_came_out',  ja: '出せた感じ',   en: 'Something came out',   emoji: '💬', score: 4 },
  { id: 'evening_normal',    ja: 'ふつう',       en: 'Just normal',          emoji: '😐', score: 3 },
  { id: 'evening_drained',   ja: '疲れた',       en: 'Drained',              emoji: '😩', score: 2 },
  { id: 'evening_nope',      ja: 'もう無理',     en: "Can't anymore",        emoji: '🚫', score: 1 },
]

const ALL_OPTIONS: CheckinOption[] = [...MORNING_OPTIONS, ...EVENING_OPTIONS]

/** ID → スコア（1〜5）への変換。未知IDは中央値3にフォールバック。 */
export function feelingToScore(id: CheckinOptionId | string | null | undefined): number {
  if (!id) return 3
  return ALL_OPTIONS.find(o => o.id === id)?.score ?? 3
}

/** ID → ラベル/絵文字辞書を Record 形式で返す（既存コードからの参照用） */
export const MORNING_FEELING_LABELS: Record<MorningFeelingId, { ja: string; en: string; emoji: string }> =
  Object.fromEntries(
    MORNING_OPTIONS.map(o => [o.id, { ja: o.ja, en: o.en, emoji: o.emoji }])
  ) as Record<MorningFeelingId, { ja: string; en: string; emoji: string }>

export const EVENING_FEELING_LABELS: Record<EveningFeelingId, { ja: string; en: string; emoji: string }> =
  Object.fromEntries(
    EVENING_OPTIONS.map(o => [o.id, { ja: o.ja, en: o.en, emoji: o.emoji }])
  ) as Record<EveningFeelingId, { ja: string; en: string; emoji: string }>

export const CHECKIN_HEADERS = {
  morning: { ja: '今日、調子どう？',                en: "How's your day starting?" },
  evening: { ja: '今日もお疲れさま。どうだった？', en: 'Nice work today. How was it?' },
} as const

/**
 * 新ID 5件分の個別 Mowi セリフは未確定（B-4 では暫定対応・別タスクで本実装）。
 * 共通フォールバックを朝/夜それぞれ1種ずつ用意。
 */
export const FALLBACK_MOWI_LINE = {
  morning: { ja: '今日も、ここから始めよう。', en: 'Starting from here.' },
  evening: { ja: 'お疲れさま。',               en: 'Good work today.' },
} as const
