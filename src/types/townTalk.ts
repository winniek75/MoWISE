/**
 * Town Talk 型定義（C-1.3 / Phase 2）
 *
 * 主参照: MoWISE_TownTalk仕様書_v1_3 §3-1（既存スキーマ準拠版）
 *
 * このファイルはシナリオ本体（`town_talk_scenarios.payload_json` に格納される
 * JSON のスキーマ）の型を定義する。テーブル行そのものの型（TownTalkLogRow 等）は
 * Phase 3 以降で必要に応じて追加する。
 */

/** NPC 識別子 */
export type TownTalkNPC = 'maria' | 'sam' | 'lily'

/** 難易度（中1/中2/中3 相当） */
export type TownTalkDifficulty = 'jh1' | 'jh2' | 'jh3'

/** プラットフォーム識別子（`played_from` カラムと一致） */
export type TownTalkPlatform = 'roblox' | 'app' | 'cluster' | 'webgl'

/** 承認ステータス（`approval_status` カラムと一致） */
export type TownTalkApprovalStatus =
  | 'auto_passed'
  | 'pending_review'
  | 'approved'
  | 'rejected'

/**
 * 1 シナリオ全体（`town_talk_scenarios.payload_json` の中身）
 *
 * DB 行のメタ情報（reward_coins / reward_friendship / mowi_message など）は
 * テーブル列にも持つが、payload_json 内にも同じ値が入っている前提
 * （世代管理のため scenario 単位で自己完結させる）。
 */
export interface TownTalkScenario {
  scenario_id: string
  pattern_no: string
  npc_id: TownTalkNPC
  place: string
  theme: string
  difficulty: TownTalkDifficulty
  reward_coins: number
  reward_friendship: number
  mowi_message: string
  total_turns: number
  turns: TownTalkTurn[]
  created_at: string
  version: number
}

/** 1 ターン分の会話単位 */
export interface TownTalkTurn {
  /** 1〜5 */
  turn_no: number
  /** NPC が発話する英語音声テキスト */
  npc_audio: string
  /** OR 判定。1つでも含まれていれば発話成功フラグ */
  required_keywords: string[]
  /** 正解選択時の NPC 反応セリフ */
  npc_reaction_correct: string
  /** 4 つの選択肢（option_id=1〜4、DB 上は固定 ID。表示順はクライアント側でシャッフル） */
  options: TownTalkOption[]
}

/** 1 選択肢 */
export interface TownTalkOption {
  /** 1〜4。DB 上の固定 ID（生成時の脚本記載順） */
  option_id: number
  /** 学習者向けに表示される英文 */
  text: string
  /** 完全な正解（◯） */
  is_correct: boolean
  /** 受容可（◯ または △）。Lily のみ △ が出る */
  is_acceptable: boolean
  /** 不正解・△ 時の解説（30 字以内）。正解時は null */
  explanation: string | null
}
