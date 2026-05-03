/**
 * Layer 表記の日本語ラベル
 * 内部コード・DB カラムは layer (0/1/2/3) を保持し、UI 表示のみ日本語化する。
 * 将来 i18n 化する際は本ファイルを vue-i18n のメッセージ定義に置き換える。
 */

export type LayerNumber = 0 | 1 | 2 | 3

export const LAYER_LABELS_SHORT: Record<LayerNumber, string> = {
  0: '聞く',
  1: 'まねる',
  2: 'つくる',
  3: '話す',
}

export const LAYER_LABELS_LONG: Record<LayerNumber, string> = {
  0: '聞いて掴む',
  1: 'まねて口に出す',
  2: '自分で組み立てる',
  3: 'とっさに話す',
}

export function layerLabel(n: number): string {
  return LAYER_LABELS_SHORT[n as LayerNumber] ?? `Layer ${n}`
}

export function layerLabelLong(n: number): string {
  return LAYER_LABELS_LONG[n as LayerNumber] ?? `Layer ${n}`
}
