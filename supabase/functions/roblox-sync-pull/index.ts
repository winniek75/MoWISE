import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, X-MoWISE-API-Key, X-MoWISE-Link-Token, X-Roblox-User-Id, Authorization',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
      },
    })
  }

  // 認証チェック
  const apiKey    = req.headers.get('X-MoWISE-API-Key')
  const linkToken = req.headers.get('X-MoWISE-Link-Token')
  const robloxId  = req.headers.get('X-Roblox-User-Id')

  if (apiKey !== Deno.env.get('ROBLOX_API_KEY')) {
    return new Response('Unauthorized', { status: 401 })
  }
  if (!linkToken || !robloxId) {
    return new Response(JSON.stringify({ error: 'NOT_LINKED' }), { status: 403 })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Link Token → user_id を取得
  const { data: link } = await supabase
    .from('roblox_links')
    .select('user_id, status, token_expires_at')
    .eq('link_token', linkToken)
    .eq('roblox_user_id', parseInt(robloxId))
    .single()

  if (!link || link.status !== 'active' || new Date(link.token_expires_at) < new Date()) {
    return new Response(JSON.stringify({ error: 'TOKEN_INVALID' }), { status: 401 })
  }

  const userId = link.user_id

  // ── pattern_progress 取得（全パターン） ──────────────────────
  const { data: patterns } = await supabase
    .from('pattern_progress')
    .select('pattern_no, mastery_level, layer0_done, layer1_done, layer2_done, layer3_done, last_practiced_at, roblox_mastery_bonus')
    .eq('user_id', userId)
    .order('pattern_no')

  // ── mowi_state 取得 ─────────────────────────────────────────
  const { data: mowi } = await supabase
    .from('mowi_state')
    .select('happiness, growth_stage, brightness_level, current_combo')
    .eq('user_id', userId)
    .single()

  // ── chart_badges 取得 ────────────────────────────────────────
  const { data: badges } = await supabase
    .from('chart_badges')
    .select('area_id, status, approved_at')
    .eq('student_id', userId)

  // ── 今日のチェックイン ──────────────────────────────────────
  const todayJST = new Date(Date.now() + 9 * 3600 * 1000).toISOString().slice(0, 10)
  const { data: checkin } = await supabase
    .from('checkins')
    .select('session_type, feeling')
    .eq('user_id', userId)
    .gte('created_at', todayJST + 'T00:00:00+09:00')
    .order('created_at', { ascending: false })

  const morningCheckin = checkin?.find(c => c.session_type === 'morning')
  const eveningCheckin = checkin?.find(c => c.session_type === 'evening')

  // last_sync_at 更新
  await supabase
    .from('roblox_links')
    .update({ last_sync_at: new Date().toISOString() })
    .eq('link_token', linkToken)

  return new Response(JSON.stringify({
    patterns: (patterns ?? []).map(p => ({
      pattern_no:       p.pattern_no,
      mastery_level:    p.mastery_level ?? 0,
      layer0_done:      p.layer0_done ?? false,
      layer1_done:      p.layer1_done ?? false,
      layer2_done:      p.layer2_done ?? false,
      layer3_done:      p.layer3_done ?? false,
      last_practiced_at: p.last_practiced_at,
      roblox_bonus:     p.roblox_mastery_bonus ?? 0,
    })),
    mowi: mowi ?? { happiness: 50, growth_stage: 1, brightness_level: 1, current_combo: 0 },
    badges: (badges ?? []).map(b => ({
      area_id:     b.area_id,
      status:      b.status,
      approved_at: b.approved_at,
    })),
    checkin_today: {
      morning_done:    !!morningCheckin,
      evening_done:    !!eveningCheckin,
      morning_feeling: morningCheckin?.feeling ?? null,
    },
    boosts: {
      coin_multiplier:    1.5,
      premium_materials:  true,
    },
    synced_at: new Date().toISOString(),
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
