/**
 * Town Talk payload validator (C-1.3 / Phase 4)
 *
 * 実装ガイド §3 Phase 4 検算ルール 9 項目を機械検証する。
 * 検算落ちが1件でもあれば exit 1 で停止（実装ガイド §8 準拠）。
 *
 * 使い方:  npx -y tsx scripts/validate_town_talk_payload.ts
 */

import { readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'

// ─── 型定義（generator と同期）────────────
interface Option {
  option_id: number
  text: string
  is_correct: boolean
  is_acceptable: boolean
  explanation: string | null
}
interface Turn {
  turn_no: number
  npc_audio: string
  required_keywords: string[]
  npc_reaction_correct: string
  options: Option[]
}
interface Scenario {
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
  turns: Turn[]
  created_at: string
  version: number
}

// ─── 結果収集 ────────────────────────────────
interface CheckResult {
  scenario_id: string
  rule: string
  status: 'PASS' | 'FAIL'
  detail?: string
}

const PAYLOAD_DIR = 'scripts/town_talk_payloads'
const VALID_NPC = ['maria', 'sam', 'lily']
const VALID_DIFF = ['jh1', 'jh2', 'jh3']
const EXPLANATION_MAX = 30

const files = readdirSync(PAYLOAD_DIR).filter((f) => f.endsWith('.json')).sort()
const results: CheckResult[] = []

/** UTF コードポイント単位の文字数（絵文字や全角もそれぞれ1） */
function charLength(s: string): number {
  return [...s].length
}

for (const file of files) {
  const path = join(PAYLOAD_DIR, file)
  const scenario = JSON.parse(readFileSync(path, 'utf-8')) as Scenario
  const sid = scenario.scenario_id
  const isLily = scenario.npc_id === 'lily'

  // Rule 1: turns.length === 5
  results.push({
    scenario_id: sid,
    rule: '1.turns_length_5',
    status: scenario.turns.length === 5 ? 'PASS' : 'FAIL',
    detail: scenario.turns.length === 5 ? undefined : `actual=${scenario.turns.length}`,
  })

  // Rule 2: each turn options.length === 4
  for (const turn of scenario.turns) {
    results.push({
      scenario_id: sid,
      rule: `2.turn${turn.turn_no}_options_length_4`,
      status: turn.options.length === 4 ? 'PASS' : 'FAIL',
      detail: turn.options.length === 4 ? undefined : `actual=${turn.options.length}`,
    })
  }

  // Rule 3: each turn has exactly one is_correct: true
  for (const turn of scenario.turns) {
    const cnt = turn.options.filter((o) => o.is_correct).length
    results.push({
      scenario_id: sid,
      rule: `3.turn${turn.turn_no}_correct_count_1`,
      status: cnt === 1 ? 'PASS' : 'FAIL',
      detail: cnt === 1 ? undefined : `actual=${cnt}`,
    })
  }

  // Rule 4: Lily: each turn has exactly one (is_correct:false, is_acceptable:true)
  if (isLily) {
    for (const turn of scenario.turns) {
      const cnt = turn.options.filter((o) => !o.is_correct && o.is_acceptable).length
      results.push({
        scenario_id: sid,
        rule: `4.turn${turn.turn_no}_lily_acceptable_count_1`,
        status: cnt === 1 ? 'PASS' : 'FAIL',
        detail: cnt === 1 ? undefined : `actual=${cnt}`,
      })
    }
  }

  // Rule 5: Maria/Sam: no △ (is_acceptable:true & is_correct:false should not exist)
  if (!isLily) {
    for (const turn of scenario.turns) {
      const cnt = turn.options.filter((o) => !o.is_correct && o.is_acceptable).length
      results.push({
        scenario_id: sid,
        rule: `5.turn${turn.turn_no}_no_acceptable_for_${scenario.npc_id}`,
        status: cnt === 0 ? 'PASS' : 'FAIL',
        detail: cnt === 0 ? undefined : `${cnt} △ found`,
      })
    }
  }

  // Rule 6: correct option's explanation is null
  for (const turn of scenario.turns) {
    const correct = turn.options.find((o) => o.is_correct)
    const ok = !!correct && correct.explanation === null
    results.push({
      scenario_id: sid,
      rule: `6.turn${turn.turn_no}_correct_explanation_null`,
      status: ok ? 'PASS' : 'FAIL',
      detail: ok ? undefined : `correct.explanation=${JSON.stringify(correct?.explanation)}`,
    })
  }

  // Rule 7: ❌/△ explanations ≤ 30 chars
  for (const turn of scenario.turns) {
    for (const opt of turn.options) {
      if (opt.is_correct) continue
      const len = charLength(opt.explanation ?? '')
      const ok = len > 0 && len <= EXPLANATION_MAX
      results.push({
        scenario_id: sid,
        rule: `7.turn${turn.turn_no}_opt${opt.option_id}_explanation_<=30`,
        status: ok ? 'PASS' : 'FAIL',
        detail: ok ? undefined : `length=${len} (text="${opt.explanation ?? ''}")`,
      })
    }
  }

  // Rule 8: required_keywords not empty
  for (const turn of scenario.turns) {
    results.push({
      scenario_id: sid,
      rule: `8.turn${turn.turn_no}_keywords_not_empty`,
      status: turn.required_keywords.length > 0 ? 'PASS' : 'FAIL',
      detail: turn.required_keywords.length > 0 ? undefined : 'empty',
    })
  }

  // Rule 9: meta valid
  const metaOk =
    scenario.total_turns === 5 &&
    VALID_NPC.includes(scenario.npc_id) &&
    VALID_DIFF.includes(scenario.difficulty)
  results.push({
    scenario_id: sid,
    rule: '9.meta_valid',
    status: metaOk ? 'PASS' : 'FAIL',
    detail: metaOk
      ? undefined
      : `total_turns=${scenario.total_turns}, npc_id=${scenario.npc_id}, difficulty=${scenario.difficulty}`,
  })
}

// ─── レポート ────────────────────────────────────
const fails = results.filter((r) => r.status === 'FAIL')
const passes = results.length - fails.length

console.log('\n=== Town Talk payload validation ===')
console.log(`Total checks : ${results.length}`)
console.log(`Passed       : ${passes}`)
console.log(`Failed       : ${fails.length}`)

// シナリオ別サマリー
const bySid = new Map<string, { pass: number; fail: number }>()
for (const r of results) {
  const cur = bySid.get(r.scenario_id) ?? { pass: 0, fail: 0 }
  if (r.status === 'PASS') cur.pass++
  else cur.fail++
  bySid.set(r.scenario_id, cur)
}
console.log('\n--- per scenario ---')
for (const [sid, cnt] of bySid.entries()) {
  const mark = cnt.fail === 0 ? '✓' : '✗'
  console.log(`  ${mark} ${sid}: pass=${cnt.pass} fail=${cnt.fail}`)
}

if (fails.length > 0) {
  console.log('\n=== FAILURES ===')
  for (const f of fails) {
    console.log(`  ✗ [${f.scenario_id}] ${f.rule}: ${f.detail ?? ''}`)
  }
  console.log('\n→ Validation FAILED. Fix and rerun.')
  process.exit(1)
}

console.log('\n→ All validation rules PASSED. ✓')
