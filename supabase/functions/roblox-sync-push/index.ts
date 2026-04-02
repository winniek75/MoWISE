import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'Content-Type, X-MoWISE-API-Key, X-MoWISE-Link-Token, X-Roblox-User-Id, Authorization',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
      },
    })
  }

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

  // Link Token → user_id
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
  const body   = await req.json()

  const { session, pattern_updates, mowi_update, town_state } = body

  // ── セキュリティ検証 ─────────────────────────────────────────
  // 1セッションで ★+0.5 を超える更新は拒否
  if (pattern_updates) {
    for (const upd of pattern_updates) {
      if ((upd.mastery_delta ?? 0) > 0.5) {
        return new Response(JSON.stringify({ error: 'MASTERY_DELTA_EXCEEDED' }), { status: 400 })
      }
    }
  }
  // 回答数検証
  if (session && session.correct_count > session.total_flash_output) {
    return new Response(JSON.stringify({ error: 'INVALID_CORRECT_COUNT' }), { status: 400 })
  }

  const updatedPatterns: string[] = []
  const newMastery: Record<string, number> = {}

  // ── pattern_progress 更新 ────────────────────────────────────
  if (pattern_updates && pattern_updates.length > 0) {
    for (const upd of pattern_updates) {
      const { data: existing } = await supabase
        .from('pattern_progress')
        .select('mastery_level, roblox_flash_output_count, roblox_mastery_bonus')
        .eq('user_id', userId)
        .eq('pattern_no', upd.pattern_no)
        .single()

      const currentMastery = existing?.mastery_level ?? 0
      const delta          = upd.mastery_delta ?? 0

      // 競合解決：max(web, roblox) — Roblox側★が大きければ採用
      const newLevel = Math.max(currentMastery, currentMastery + delta)

      const upsertData = {
        user_id:                   userId,
        pattern_no:                upd.pattern_no,
        mastery_level:             newLevel,
        roblox_flash_output_count: (existing?.roblox_flash_output_count ?? 0) + (upd.flash_output_total ?? 0),
        roblox_npc_missions_done:  upd.npc_mission_completed ? 1 : 0,
        roblox_mastery_bonus:      (existing?.roblox_mastery_bonus ?? 0) + delta,
        last_practiced_at:         new Date().toISOString(),
      }

      await supabase
        .from('pattern_progress')
        .upsert(upsertData, { onConflict: 'user_id,pattern_no' })

      updatedPatterns.push(upd.pattern_no)
      newMastery[upd.pattern_no] = newLevel
    }
  }

  // ── mowi_state 更新 ─────────────────────────────────────────
  if (mowi_update) {
    const { data: mowiCurrent } = await supabase
      .from('mowi_state')
      .select('happiness, total_xp')
      .eq('user_id', userId)
      .single()

    const newHappiness = Math.min(100, Math.max(0, (mowiCurrent?.happiness ?? 50) + (mowi_update.happiness_delta ?? 0)))
    const newXP        = (mowiCurrent?.total_xp ?? 0) + (mowi_update.xp_earned ?? 0)

    await supabase
      .from('mowi_state')
      .upsert({
        user_id:              userId,
        happiness:            newHappiness,
        total_xp:             newXP,
        last_roblox_sync_at:  new Date().toISOString(),
      }, { onConflict: 'user_id' })
  }

  // ── roblox_sessions 記録 ─────────────────────────────────────
  if (session) {
    await supabase.from('roblox_sessions').upsert({
      user_id:               userId,
      roblox_user_id:        parseInt(robloxId),
      started_at:            session.started_at,
      ended_at:              session.ended_at ?? new Date().toISOString(),
      duration_seconds:      session.duration_seconds ?? 0,
      flash_output_total:    session.total_flash_output ?? 0,
      flash_output_correct:  session.correct_count ?? 0,
      max_combo:             session.max_combo ?? 0,
      word_coins_earned:     session.word_coins_earned ?? 0,
      word_coins_spent:      session.word_coins_spent ?? 0,
      buildings_built:       session.buildings_built ?? [],
      npc_missions_done:     session.npc_missions_completed ?? [],
      pattern_updates:       pattern_updates ?? [],
      town_state:            town_state ?? {},
    }, { onConflict: 'user_id,started_at' })
  }

  // ── roblox_town_state 更新 ───────────────────────────────────
  if (town_state) {
    await supabase.from('roblox_town_state').upsert({
      user_id:                userId,
      zone1_buildings:        town_state.zone1_buildings ?? 0,
      zone2_buildings:        town_state.zone2_buildings ?? 0,
      total_npc_friendship:   town_state.total_npc_friendship ?? 0,
      updated_at:             new Date().toISOString(),
    }, { onConflict: 'user_id' })
  }

  return new Response(JSON.stringify({
    synced:           true,
    updated_patterns: updatedPatterns,
    new_mastery:      newMastery,
    server_time:      new Date().toISOString(),
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  })
})
