/**
 * Town Talk seeds SQL builder (C-1.3 / Phase 5)
 *
 * scripts/town_talk_payloads/*.json を読み込んで、
 * seeds/town_talk_scenarios.sql を自動生成する。
 *
 * 仕様:
 *   - PostgreSQL dollar-quoted string にシナリオ毎のユニークタグを使用
 *     (タグ: $tt_{scenario_id}$)
 *   - 各 INSERT 行のメタフィールドは JSON から読み取って埋める
 *   - ON CONFLICT (scenario_id) DO UPDATE で冪等化
 *   - dollar-quote タグ衝突を起動時に検証（衝突時は exit 1）
 *
 * 主参照: 仕様書 v1.3 §12-2 雛形
 * 使い方:  npx -y tsx scripts/build_town_talk_seeds_sql.ts
 */

import { readFileSync, writeFileSync, mkdirSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

// 入力 JSON の最低限の型（メタ抽出に必要な範囲）
interface ScenarioMeta {
  scenario_id: string
  pattern_no: string
  npc_id: string
  place: string
  theme: string
  difficulty: string
  reward_coins: number
  reward_friendship: number
  mowi_message: string
  total_turns: number
}

const PAYLOAD_DIR = 'scripts/town_talk_payloads'
const OUT_DIR = 'seeds'
const OUT_FILE = 'town_talk_scenarios.sql'

const files = readdirSync(PAYLOAD_DIR)
  .filter((f) => f.endsWith('.json'))
  .sort()

if (files.length !== 9) {
  console.error(`FATAL: expected 9 payload files in ${PAYLOAD_DIR}, found ${files.length}`)
  process.exit(1)
}

// SQL 文字列リテラル（シングルクォート escape）
function sqlStr(s: string): string {
  return `'${s.replace(/'/g, "''")}'`
}

// 各シナリオを読み込んで VALUES 行を構築
const valuesRows: string[] = []
let totalPayloadBytes = 0

for (const file of files) {
  const raw = readFileSync(join(PAYLOAD_DIR, file), 'utf-8')
  const scenario = JSON.parse(raw) as ScenarioMeta
  const sid = scenario.scenario_id

  // ユニーク dollar-quote タグ
  const tag = `$tt_${sid}$`

  // 衝突検証：タグが JSON 本体に含まれないこと
  if (raw.includes(tag)) {
    console.error(`FATAL: dollar-quote tag collision in ${sid} (tag="${tag}" found inside JSON body)`)
    process.exit(1)
  }

  // payload_json は JSON ファイル全体（pretty-print 2-space indent のまま）
  const payloadLiteral = `${tag}${raw.trimEnd()}${tag}::jsonb`
  totalPayloadBytes += raw.length

  const cols = [
    sqlStr(sid),
    sqlStr(scenario.pattern_no),
    sqlStr(scenario.npc_id),
    sqlStr(scenario.place),
    sqlStr(scenario.theme),
    sqlStr(scenario.difficulty),
    String(scenario.reward_coins),
    String(scenario.reward_friendship),
    sqlStr(scenario.mowi_message),
    String(scenario.total_turns),
    payloadLiteral,
  ]

  valuesRows.push(`-- ${sid}\n(\n  ${cols.slice(0, 10).join(', ')},\n  ${cols[10]}\n)`)
}

// SQL 全体を組み立て
const header = `-- =====================================================
-- C-1.3 Phase 5: Town Talk seed data
-- 9 シナリオを town_talk_scenarios に投入
--
-- 自動生成: scripts/build_town_talk_seeds_sql.ts
-- 入力    : scripts/town_talk_payloads/*.json (9 ファイル)
-- 主参照  : MoWISE_TownTalk仕様書_v1_3 §12-2 雛形
--
-- 冪等性: ON CONFLICT (scenario_id) DO UPDATE で再実行可能
-- 安全性: dollar-quote タグはシナリオ毎にユニーク (\$tt_<id>\$)
-- =====================================================

INSERT INTO town_talk_scenarios (
  scenario_id, pattern_no, npc_id, place, theme, difficulty,
  reward_coins, reward_friendship, mowi_message, total_turns, payload_json
) VALUES
`

const conflictClause = `
ON CONFLICT (scenario_id) DO UPDATE SET
  payload_json      = EXCLUDED.payload_json,
  pattern_no        = EXCLUDED.pattern_no,
  npc_id            = EXCLUDED.npc_id,
  place             = EXCLUDED.place,
  theme             = EXCLUDED.theme,
  difficulty        = EXCLUDED.difficulty,
  reward_coins      = EXCLUDED.reward_coins,
  reward_friendship = EXCLUDED.reward_friendship,
  mowi_message      = EXCLUDED.mowi_message,
  total_turns       = EXCLUDED.total_turns,
  updated_at        = now();
`

const sql = header + valuesRows.join(',\n') + conflictClause

mkdirSync(OUT_DIR, { recursive: true })
writeFileSync(join(OUT_DIR, OUT_FILE), sql, 'utf-8')

console.log(`Built ${OUT_DIR}/${OUT_FILE}`)
console.log(`  Scenarios       : ${files.length}`)
console.log(`  SQL size        : ${sql.length} bytes (${(sql.length / 1024).toFixed(1)} KB)`)
console.log(`  SQL lines       : ${sql.split('\n').length}`)
console.log(`  Payload total   : ${totalPayloadBytes} bytes`)
console.log(`  Tag collisions  : 0 (verified)`)
