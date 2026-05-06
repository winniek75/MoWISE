/**
 * academy-check-teacher-role
 *
 * プレイヤー入室時に先生ロールを判定する。
 *
 * 認証 : Authorization: Bearer ${ROBLOX_API_KEY}
 * Method : POST
 * Body   : { user_id }
 * Reply  : { is_teacher, class_ids, teacher_id? }
 *
 * 処理ロジック (実装ガイド §4-2-1):
 *   1. ROBLOX_API_KEY 検証
 *   2. SELECT id FROM classes WHERE teacher_id = $user_id
 *   3. >=1件 → is_teacher: true + class_ids[]
 *   4. 0件   → is_teacher: false + class_ids: []
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
  let body: { user_id?: string }
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }
  const { user_id } = body
  if (!user_id) {
    return jsonResponse({ error: 'missing_required_fields' }, 400)
  }

  // ── DB クライアント (Service Role) ────────────
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (!supabaseUrl || !serviceKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500)
  }
  const supabase = createClient(supabaseUrl, serviceKey)

  // ── classes WHERE teacher_id = user_id ────────
  const { data: rows, error } = await supabase
    .from('classes')
    .select('id')
    .eq('teacher_id', user_id)

  if (error) {
    return jsonResponse({ error: 'db_error', detail: error.message }, 500)
  }

  const classIds = (rows ?? []).map((r: { id: string }) => r.id)
  const isTeacher = classIds.length > 0

  return jsonResponse({
    is_teacher: isTeacher,
    class_ids:  classIds,
    teacher_id: isTeacher ? user_id : undefined,
  })
})
