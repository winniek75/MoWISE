/**
 * world-talk-submit
 *
 * 1 セッションの結果を受け取り、ログ・進捗・報酬・LRU を一括処理する。
 *
 * 認証: Authorization: Bearer ${ROBLOX_API_KEY}
 * Method: POST
 *
 * Request:
 * {
 *   user_id, scenario_id,
 *   selections: [{turn, option_id, is_correct, is_acceptable}, ...],
 *   audio_urls?: [{turn, url}, ...],
 *   duration_sec?, platform?: 'roblox' | 'app' | 'cluster' | 'webgl'
 * }
 *
 * Response:
 * {
 *   log_id, approval_status,
 *   rewards: { coins_granted, friendship_delta, mowi_message },
 *   next_review_at
 * }
 *
 * 5 ステップ厳守 (実装ガイド追加指示):
 *   1. town_talk_logs INSERT  (失敗 → 5xx で即返却)
 *   2. アラート判定 → fail >= 3 なら approval_status='pending_review' に UPDATE
 *   3. town_talk_progress UPSERT  (§7-2 calcNextReview)  (失敗 → ログのみ残し続行)
 *   4. 報酬 JSON 返却
 *   5. LRU 100件超過分の audio_urls を NULL 化  (§8-2)  (失敗 → ログのみ残し続行)
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

const VALID_PLATFORMS = ['roblox', 'app', 'cluster', 'webgl'] as const
type Platform = typeof VALID_PLATFORMS[number]

const FAIL_THRESHOLD_FOR_REVIEW = 3 // §9-3: ç´è¿5åã§3åä»¥ä¸ã®å¤±æ → pending_review

interface SelectionInput {
  turn: number
  option_id: number
  is_correct: boolean
  is_acceptable: boolean
}

interface AudioUrlInput {
  turn: number
  url: string
}

interface ScenarioRow {
  scenario_id: string
  pattern_no: string
  npc_id: string
  total_turns: number
  reward_coins: number
  reward_friendship: number
  mowi_message: string
}

interface ProgressRow {
  spaced_interval_days: number
  play_count: number
  success_count: number
  friendship_npc: number
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
  let body: {
    user_id?: string
    scenario_id?: string
    selections?: SelectionInput[]
    audio_urls?: AudioUrlInput[]
    duration_sec?: number
    platform?: Platform
  }
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const {
    user_id,
    scenario_id,
    selections,
    audio_urls,
    duration_sec,
    platform = 'roblox',
  } = body
  if (!user_id || !scenario_id || !Array.isArray(selections) || selections.length === 0) {
    return jsonResponse({ error: 'missing_required_fields' }, 400)
  }
  if (!VALID_PLATFORMS.includes(platform)) {
    return jsonResponse({ error: 'invalid_platform' }, 400)
  }

  // ── DB クライアント ───────────────────────────
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500)
  }
  const supabase = createClient(supabaseUrl, serviceKey)

  // ── シナリオメタ取得（報酬・パターン情報の真実の源）──
  const { data: scenarioRow, error: sErr } = await supabase
    .from('town_talk_scenarios')
    .select('scenario_id, pattern_no, npc_id, total_turns, reward_coins, reward_friendship, mowi_message')
    .eq('scenario_id', scenario_id)
    .maybeSingle()

  if (sErr) {
    return jsonResponse({ error: 'db_error', detail: sErr.message }, 500)
  }
  if (!scenarioRow) {
    return jsonResponse({ error: 'scenario_not_found' }, 404)
  }
  const scenario = scenarioRow as ScenarioRow

  // 集計
  const totalTurns      = selections.length
  const correctCount    = selections.filter((s) => s.is_correct).length
  const acceptableCount = selections.filter((s) => !s.is_correct && s.is_acceptable).length
  const failCount       = selections.filter((s) => !s.is_correct && !s.is_acceptable).length
  const isCompleted     = totalTurns >= scenario.total_turns

  const initialApprovalStatus =
    failCount >= FAIL_THRESHOLD_FOR_REVIEW ? 'pending_review' : 'auto_passed'

  // ─────────────────────────────────────────────
  // STEP 1: town_talk_logs INSERT  (失敗 → 5xx)
  // ─────────────────────────────────────────────
  const { data: logInsert, error: logErr } = await supabase
    .from('town_talk_logs')
    .insert({
      user_id,
      scenario_id,
      pattern_no:       scenario.pattern_no,
      npc_id:           scenario.npc_id,
      total_turns:      totalTurns,
      correct_count:    correctCount,
      acceptable_count: acceptableCount,
      fail_count:       failCount,
      is_completed:     isCompleted,
      selections,
      audio_urls:       audio_urls ?? null,
      approval_status:  initialApprovalStatus,
      played_from:      platform,
      duration_sec:     duration_sec ?? null,
    })
    .select('id')
    .single()

  if (logErr || !logInsert) {
    return jsonResponse({ error: 'log_insert_failed', detail: logErr?.message }, 500)
  }
  const logId = (logInsert as { id: string }).id

  // ─────────────────────────────────────────────
  // STEP 2: アラート判定はすでに STEP 1 で initialApprovalStatus に反映済み
  //         （submit 単発の判定。クロス分析は world-talk-alert-check）
  // ─────────────────────────────────────────────
  const finalApprovalStatus = initialApprovalStatus

  // ─────────────────────────────────────────────
  // STEP 3: town_talk_progress UPSERT（§7-2）失敗してもログのみ
  // ─────────────────────────────────────────────
  let nextReviewAtIso: string | null = null
  try {
    const { data: existing } = await supabase
      .from('town_talk_progress')
      .select('spaced_interval_days, play_count, success_count, friendship_npc')
      .eq('user_id', user_id)
      .eq('scenario_id', scenario_id)
      .maybeSingle()

    const prev = (existing ?? null) as ProgressRow | null
    const currentInterval = prev?.spaced_interval_days ?? 1
    const { nextDays, nextReviewAt } = calcNextReview(currentInterval, failCount)
    nextReviewAtIso = nextReviewAt.toISOString()

    const isSuccess = failCount === 0
    const nowIso = new Date().toISOString()

    const upsertRow = {
      user_id,
      scenario_id,
      play_count:           (prev?.play_count ?? 0) + 1,
      success_count:        (prev?.success_count ?? 0) + (isSuccess ? 1 : 0),
      last_played_at:       nowIso,
      last_success_at:      isSuccess ? nowIso : (prev ? undefined : null),
      next_review_at:       nextReviewAtIso,
      spaced_interval_days: nextDays,
      friendship_npc:       (prev?.friendship_npc ?? 0) + (isCompleted ? scenario.reward_friendship : 0),
      updated_at:           nowIso,
    }

    const { error: upErr } = await supabase
      .from('town_talk_progress')
      .upsert(upsertRow, { onConflict: 'user_id,scenario_id' })

    if (upErr) {
      console.warn('[world-talk-submit] progress upsert failed:', upErr.message)
    }
  } catch (e) {
    console.warn('[world-talk-submit] progress upsert exception:', e)
  }

  // ─────────────────────────────────────────────
  // STEP 4: 報酬 JSON を構築（返却用、後続失敗があっても返却する）
  // ─────────────────────────────────────────────
  const responseBody = {
    log_id:          logId,
    approval_status: finalApprovalStatus,
    rewards: {
      coins_granted:    isCompleted ? scenario.reward_coins : 0,
      friendship_delta: isCompleted ? scenario.reward_friendship : 0,
      mowi_message:     scenario.mowi_message,
    },
    next_review_at: nextReviewAtIso,
  }

  // ─────────────────────────────────────────────
  // STEP 5: LRU 100件超過の audio_urls を NULL 化（§8-2）失敗してもログのみ
  // ─────────────────────────────────────────────
  try {
    const { data: oldLogs, error: lruSelErr } = await supabase
      .from('town_talk_logs')
      .select('id')
      .eq('user_id', user_id)
      .not('audio_urls', 'is', null)
      .order('created_at', { ascending: false })
      .range(100, 999) // 101件目以降

    if (lruSelErr) {
      console.warn('[world-talk-submit] LRU select failed:', lruSelErr.message)
    } else if (oldLogs && oldLogs.length > 0) {
      const ids = (oldLogs as { id: string }[]).map((r) => r.id)
      const { error: lruUpdErr } = await supabase
        .from('town_talk_logs')
        .update({ audio_urls: null })
        .in('id', ids)

      if (lruUpdErr) {
        console.warn('[world-talk-submit] LRU update failed:', lruUpdErr.message)
      }
    }
  } catch (e) {
    console.warn('[world-talk-submit] LRU exception:', e)
  }

  return jsonResponse(responseBody)
})

/**
 * §7-2 ééåå¾©ã®æ´æ°å¼
 * - å¨åæ­£è§£(failCount=0):  next = min(current * 2, 30)
 * - 1ã2åå¤±æ:              next = current
 * - 3åä»¥ä¸å¤±æ:             next = max(floor(current / 2), 1)
 */
function calcNextReview(
  currentInterval: number,
  failCount: number,
): { nextDays: number; nextReviewAt: Date } {
  let next = currentInterval
  if (failCount === 0)        next = Math.min(next * 2, 30)
  else if (failCount <= 2)    next = next
  else                        next = Math.max(Math.floor(next / 2), 1)

  const reviewAt = new Date()
  reviewAt.setDate(reviewAt.getDate() + next)
  return { nextDays: next, nextReviewAt: reviewAt }
}
