/**
 * MoWISE パターンレジストリ
 * 全パターンのデータを一元管理するインデックス
 *
 * 新パターン追加時はここに import + 登録するだけで
 * useGameMode が自動的にデータを取得できる
 */

import type { Layer2Question, Layer3Question } from './p001Questions'
import type { Layer0Question, Layer1Question } from './layerTypes'

import { p001Layer2Questions, p001Layer3Questions, p001PatternInfo } from './p001Questions'
import { p002Layer2Questions, p002Layer3Questions, p002PatternInfo } from './p002Questions'
import { p003Layer2Questions, p003Layer3Questions, p003PatternInfo } from './p003Questions'
import { p004Layer2Questions, p004Layer3Questions, p004PatternInfo } from './p004Questions'
import { p005Layer2Questions, p005Layer3Questions, p005PatternInfo } from './p005Questions'

import { p001Layer0Questions, p001Layer1Questions } from './p001Layer01'
import { p002Layer0Questions, p002Layer1Questions } from './p002Layer01'
import { p003Layer0Questions, p003Layer1Questions } from './p003Layer01'
import { p004Layer0Questions, p004Layer1Questions } from './p004Layer01'
import { p005Layer0Questions, p005Layer1Questions } from './p005Layer01'

// ─────────────────────────────────────────────
// 型定義
// ─────────────────────────────────────────────

export interface PatternInfo {
  id: string
  label: string
  labelJa: string
  rarity: number
  area: string
  layer2QuestionCount: number
  layer3QuestionCount: number
  layer2PassThreshold: number
  layer3PassThreshold: number
}

export interface PatternData {
  info: PatternInfo
  layer0Questions: Layer0Question[]
  layer1Questions: Layer1Question[]
  layer2Questions: Layer2Question[]
  layer3Questions: Layer3Question[]
}

// ─────────────────────────────────────────────
// レジストリ
// ─────────────────────────────────────────────

const registry: Record<string, PatternData> = {
  P001: {
    info: p001PatternInfo,
    layer0Questions: p001Layer0Questions,
    layer1Questions: p001Layer1Questions,
    layer2Questions: p001Layer2Questions,
    layer3Questions: p001Layer3Questions,
  },
  P002: {
    info: p002PatternInfo,
    layer0Questions: p002Layer0Questions,
    layer1Questions: p002Layer1Questions,
    layer2Questions: p002Layer2Questions,
    layer3Questions: p002Layer3Questions,
  },
  P003: {
    info: p003PatternInfo,
    layer0Questions: p003Layer0Questions,
    layer1Questions: p003Layer1Questions,
    layer2Questions: p003Layer2Questions,
    layer3Questions: p003Layer3Questions,
  },
  P004: {
    info: p004PatternInfo,
    layer0Questions: p004Layer0Questions,
    layer1Questions: p004Layer1Questions,
    layer2Questions: p004Layer2Questions,
    layer3Questions: p004Layer3Questions,
  },
  P005: {
    info: p005PatternInfo,
    layer0Questions: p005Layer0Questions,
    layer1Questions: p005Layer1Questions,
    layer2Questions: p005Layer2Questions,
    layer3Questions: p005Layer3Questions,
  },
}

// ─────────────────────────────────────────────
// API
// ─────────────────────────────────────────────

/**
 * パターンIDからデータを取得
 * 将来的にはSupabase fetch に差し替え可能
 */
export function getPatternData(patternId: string): PatternData | null {
  return registry[patternId] ?? null
}

/**
 * Layer 0 の問題データを取得
 */
export function getLayer0Questions(patternId: string): Layer0Question[] {
  return registry[patternId]?.layer0Questions ?? []
}

/**
 * Layer 1 の問題データを取得
 */
export function getLayer1Questions(patternId: string): Layer1Question[] {
  return registry[patternId]?.layer1Questions ?? []
}

/**
 * Layer 2 の問題データを取得
 */
export function getLayer2Questions(patternId: string): Layer2Question[] {
  return registry[patternId]?.layer2Questions ?? []
}

/**
 * Layer 3 の問題データを取得
 */
export function getLayer3Questions(patternId: string): Layer3Question[] {
  return registry[patternId]?.layer3Questions ?? []
}

/**
 * パターン情報を取得
 */
export function getPatternInfo(patternId: string): PatternInfo | null {
  return registry[patternId]?.info ?? null
}

/**
 * 登録済みの全パターンIDを返す
 */
export function getAvailablePatternIds(): string[] {
  return Object.keys(registry)
}
