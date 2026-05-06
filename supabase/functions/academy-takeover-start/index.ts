/**
 * academy-takeover-start
 *
 * 先生が NPC を引き継ぎ開始する。
 *
 * 認証 : Authorization: Bearer ${ROBLOX_API_KEY}
 * Method : POST
 * Body   : { teacher_id, class_id, npc_id }
 * Reply  : { session_id, started_at }
 *
 * 処理ロジック (実装ガイド §4-2-2):
 *   1. ROBLOX_API_KEY 検証
 *   2. teacher_id が class_id の担当先生であることを検証
 *   3. 同 NPC で既存アクティブセッションがあれば 409
 *   4. INSERT INTO academy_npc_takeovers
 *   5. id を session_id として返却
 *
 * エラー応答:
 *   401 API キー不正 / 403 teacher_id 不一致 / 409 同 NPC が引き継ぎ中 / 500 DB
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
  let body: { teacher_id?: string; class_id?: string; npc_id?: string }
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const { teacher_id, class_id, npc_id } = body
  if (!teacher_id || !class_id || !npc_id) {
    return jsonResponse({ error: 'missing_required_fields' }, 400)
  }
  if (!VALID_NPCS.includes(npc_id as Npc)) {
    return jsonResponse({ error: 'invalid_npc_id' }, 400)
  }

  // ── DB クライアント (Service Role) ────────────
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500)
  }
  const supabase = createClient(supabaseUrl, serviceKey)

  // ── 1. teacher_id が class_id の担当先生か検証 ─
  const { data: cls, error: clsErr } = await supabase
    .from('classes')
    .select('id')
    .eq('id', class_id)
    .eq('teacher_id', teacher_id)
    .maybeSingle()

  if (clsErr) {
    return jsonResponse({ error: 'db_error', detail: clsErr.message }, 500)
  }
  if (!cls) {
    return jsonResponse({ error: 'forbidden_not_class_teacher' }, 403)
  }

  // ── 2. 同 NPC でアクティブセッション存在チェック ─
  const { data: active, error: actErr } = await supabase
    .from('academy_npc_takeovers')
    .select('id')
    .eq('npc_id', npc_id)
    .is('ended_at', null)
    .limit(1)
    .maybeSingle()

  if (actErr) {
    return jsonResponse({ error: 'db_error', detail: actErr.message }, 500)
  }
  if (active) {
    return jsonResponse({ error: 'conflict_active_takeover_exists' }, 409)
  }

  // ── 3. INSERT 新規セッション ──────────────────
  const { data: inserted, error: insErr } = await supabase
    .from('academy_npc_takeovers')
    .insert({ teacher_id, class_id, npc_id })
    .select('id, started_at')
    .single()

  if (insErr || !inserted) {
    return jsonResponse({ error: 'insert_failed', detail: insErr?.message }, 500)
  }

  return jsonResponse({
    session_id: (inserted as { id: string }).id,
    started_at: (inserted as { started_at: string }).started_at,
  })
})
