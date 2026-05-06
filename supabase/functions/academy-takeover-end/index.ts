/**
 * academy-takeover-end
 *
 * 引き継ぎを終了する。
 *
 * 認証 : Authorization: Bearer ${ROBLOX_API_KEY}
 * Method : POST
 * Body   : { session_id, teacher_id }
 * Reply  : { session_id, ended_at, duration_sec }
 *
 * 処理ロジック (実装ガイド §4-2-3):
 *   1. ROBLOX_API_KEY 検証
 *   2. UPDATE academy_npc_takeovers SET ended_at = now()
 *      WHERE id = session_id AND teacher_id = teacher_id AND ended_at IS NULL
 *   3. 影響行 0 → 404
 *   4. 影響行 1 → started_at から duration_sec を計算して返却
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
  let body: { session_id?: string; teacher_id?: string }
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const { session_id, teacher_id } = body
  if (!session_id || !teacher_id) {
    return jsonResponse({ error: 'missing_required_fields' }, 400)
  }

  // ── DB クライアント (Service Role) ────────────
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500)
  }
  const supabase = createClient(supabaseUrl, serviceKey)

  // ── UPDATE: 影響行 1 のみ通す（ended_at IS NULL かつ teacher_id 一致） ─
  const nowIso = new Date().toISOString()
  const { data: updated, error: upErr } = await supabase
    .from('academy_npc_takeovers')
    .update({ ended_at: nowIso })
    .eq('id', session_id)
    .eq('teacher_id', teacher_id)
    .is('ended_at', null)
    .select('id, started_at, ended_at')

  if (upErr) {
    return jsonResponse({ error: 'db_error', detail: upErr.message }, 500)
  }
  if (!updated || updated.length === 0) {
    return jsonResponse({ error: 'session_not_found_or_already_ended' }, 404)
  }

  const row = updated[0] as { id: string; started_at: string; ended_at: string }
  const startedAtMs = new Date(row.started_at).getTime()
  const endedAtMs   = new Date(row.ended_at).getTime()
  const durationSec = Math.max(0, Math.floor((endedAtMs - startedAtMs) / 1000))

  return jsonResponse({
    session_id:   row.id,
    ended_at:     row.ended_at,
    duration_sec: durationSec,
  })
})
