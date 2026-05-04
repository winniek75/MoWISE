/**
 * world-talk-scenario-fetch
 *
 * NPC ID を受け取り、対象生徒に最適な 1 シナリオを返す。
 * 出題優先度 (仕様書 §7-1):
 *   1. first_play     : そのNPCで未プレイのシナリオ
 *   2. spaced_review  : next_review_at <= now() のシナリオ
 *   3. random         : それ以外はランダム
 *
 * 認証: Authorization: Bearer ${ROBLOX_API_KEY}
 * Method: POST
 * Body  : { user_id, npc_id, platform? }
 * Reply : { scenario_id, scenario, selection_reason }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const JSON_HEADERS = { ...CORS_HEADERS, 'Content-Type': 'application/json' }

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS })
}

const VALID_NPCS = ['maria', 'sam', 'lily'] as const
type Npc = typeof VALID_NPCS[number]

interface ScenarioRow {
  scenario_id: string
  npc_id: Npc
  payload_json: unknown
}

interface ProgressRow {
  scenario_id: string
  next_review_at: string | null
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS })
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405)
  }

  // ── 認証 ───────────────────────────────────────
  const auth = req.headers.get('Authorization') ?? ''
  const expected = `Bearer ${Deno.env.get('ROBLOX_API_KEY') ?? ''}`
  if (!Deno.env.get('ROBLOX_API_KEY') || auth !== expected) {
    return jsonResponse({ error: 'unauthorized' }, 401)
  }

  // ── パース・バリデーション ─────────────────────
  let body: { user_id?: string; npc_id?: string; platform?: string }
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const { user_id, npc_id } = body
  if (!user_id || !npc_id) {
    return jsonResponse({ error: 'missing_required_fields' }, 400)
  }
  if (!VALID_NPCS.includes(npc_id as Npc)) {
    return jsonResponse({ error: 'invalid_npc_id' }, 400)
  }

  // ── DB クライアント ───────────────────────────
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500)
  }
  const supabase = createClient(supabaseUrl, serviceKey)

  // ── 1. NPC のアクティブシナリオ全取得 ──────────
  const { data: scenarios, error: sErr } = await supabase
    .from('town_talk_scenarios')
    .select('scenario_id, npc_id, payload_json')
    .eq('npc_id', npc_id)
    .eq('is_active', true)
    .order('scenario_id', { ascending: true })

  if (sErr) {
    return jsonResponse({ error: 'db_error', detail: sErr.message }, 500)
  }
  if (!scenarios || scenarios.length === 0) {
    return jsonResponse({ error: 'no_scenario' }, 404)
  }

  // ── 2. ユーザー進捗を取得 ──────────────────────
  const scenarioIds = (scenarios as ScenarioRow[]).map((s) => s.scenario_id)
  const { data: progress, error: pErr } = await supabase
    .from('town_talk_progress')
    .select('scenario_id, next_review_at')
    .eq('user_id', user_id)
    .in('scenario_id', scenarioIds)

  if (pErr) {
    return jsonResponse({ error: 'db_error', detail: pErr.message }, 500)
  }

  const progressMap = new Map<string, ProgressRow>()
  for (const p of (progress ?? []) as ProgressRow[]) {
    progressMap.set(p.scenario_id, p)
  }

  // ── 3. 出題ロジック §7-1 ───────────────────────
  const result = selectScenario(scenarios as ScenarioRow[], progressMap)
  return jsonResponse({
    scenario_id: result.scenario.scenario_id,
    scenario:    result.scenario.payload_json,
    selection_reason: result.reason,
  })
})

/** 出題優先度に従って 1 シナリオ選定 */
function selectScenario(
  scenarios: ScenarioRow[],
  progressMap: Map<string, ProgressRow>,
): { scenario: ScenarioRow; reason: 'first_play' | 'spaced_review' | 'random' } {
  // 優先度1: 未プレイ
  const unplayed = scenarios.filter((s) => !progressMap.has(s.scenario_id))
  if (unplayed.length > 0) {
    return { scenario: unplayed[0], reason: 'first_play' }
  }

  // 優先度2: 復習タイミング到来
  const now = Date.now()
  const dueForReview = scenarios.filter((s) => {
    const p = progressMap.get(s.scenario_id)
    return p?.next_review_at && new Date(p.next_review_at).getTime() <= now
  })
  if (dueForReview.length > 0) {
    return { scenario: dueForReview[0], reason: 'spaced_review' }
  }

  // 優先度3: ランダム
  const idx = Math.floor(Math.random() * scenarios.length)
  return { scenario: scenarios[idx], reason: 'random' }
}
