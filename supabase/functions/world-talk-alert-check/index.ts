/**
 * world-talk-alert-check
 *
 * 採点ダッシュボード用：教師が指定 classroom の生徒について
 * 4 種のアラートを返す。
 *
 * 認証: Supabase JWT（教師の access_token）
 * Method: GET
 * Query : ?classroom_id={uuid}
 * Reply : { alerts: [{ user_id, student_name, alert_type, details, last_played_at, log_ids_to_review? }, ...] }
 *
 * 認可（実装ガイド追加指示）:
 *   1. JWT から auth_user_id を取得
 *   2. classes.id = classroom_id AND teacher_id = auth_user_id を確認
 *   3. 該当行が無ければ即 403 forbidden（class_members を読みにいかない）
 *   4. 認可後にのみ class_members → 生徒一覧 → アラート判定
 *
 * 4 種アラート（§9-3）:
 *   - high_fail_rate    : 直近5回で fail_count >= 3 が3件以上（緊急度: 高）
 *   - pattern_stuck     : 同一 scenario_id で fail_count >= 2 の連続 3 回（緊急度: 高）
 *   - long_silence      : last_played_at が 14 日以上前（緊急度: 中）
 *   - first_completion  : 該当生徒で初めて success_count が 1 になった scenario あり（緊急度: 低／祝福系）
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
}
const JSON_HEADERS = { ...CORS_HEADERS, 'Content-Type': 'application/json' }

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS })
}

type AlertType = 'high_fail_rate' | 'pattern_stuck' | 'long_silence' | 'first_completion'

const ALERT_PRIORITY: Record<AlertType, number> = {
  high_fail_rate:   0,
  pattern_stuck:    1,
  long_silence:     2,
  first_completion: 3,
}

interface Alert {
  user_id: string
  student_name: string
  alert_type: AlertType
  details: string
  last_played_at: string | null
  log_ids_to_review?: string[]
}

interface MemberRow {
  user_id: string
}

interface UserRow {
  id: string
  display_name: string | null
}

interface LogRow {
  id: string
  user_id: string
  scenario_id: string
  fail_count: number
  is_completed: boolean
  created_at: string
}

interface ProgressRow {
  user_id: string
  scenario_id: string
  success_count: number
  last_played_at: string | null
  last_success_at: string | null
}

const HIGH_FAIL_RECENT_N           = 5  // ç´è¿5å
const HIGH_FAIL_FAIL_THRESHOLD     = 3  // 1åã®ã»ãã·ã§ã³ã§3ä»¥ä¸å¤±æ
const HIGH_FAIL_OCCURRENCE         = 3  // ã®ã»ãã·ã§ã³ã3ä»¶ä»¥ä¸
const PATTERN_STUCK_FAIL_THRESHOLD = 2  // åä¸ã·ããªãª 2ä»¥ä¸å¤±æ
const PATTERN_STUCK_CONSECUTIVE    = 3  // ã3åé£ç¶
const LONG_SILENCE_DAYS            = 14
const FIRST_COMPLETION_LOOKBACK_MS = 7 * 24 * 60 * 60 * 1000 // ç´è¿7æ¥ã§ã®é海

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS })
  }
  if (req.method !== 'GET') {
    return jsonResponse({ error: 'method_not_allowed' }, 405)
  }

  // ── classroom_id 取得 ───────────────────────────
  const url = new URL(req.url)
  const classroomId = url.searchParams.get('classroom_id')
  if (!classroomId) {
    return jsonResponse({ error: 'missing_classroom_id' }, 400)
  }

  // ── JWT 取得 ───────────────────────────────────
  const authHeader = req.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) {
    return jsonResponse({ error: 'unauthorized' }, 401)
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey  = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  const anonKey     = Deno.env.get('SUPABASE_ANON_KEY')
  if (!supabaseUrl || !serviceKey || !anonKey) {
    return jsonResponse({ error: 'server_misconfigured' }, 500)
  }

  // 教師 JWT を検証するクライアント（anon key + Authorization ヘッダ）
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  })
  const { data: userRes, error: userErr } = await userClient.auth.getUser()
  if (userErr || !userRes?.user) {
    return jsonResponse({ error: 'unauthorized' }, 401)
  }
  const teacherId = userRes.user.id

  // ── 以降は service_role でデータ取得（RLS バイパス） ──
  const supabase = createClient(supabaseUrl, serviceKey)

  // ── 認可：classes.id = classroom_id AND teacher_id = teacherId ──
  const { data: classRow, error: cErr } = await supabase
    .from('classes')
    .select('id')
    .eq('id', classroomId)
    .eq('teacher_id', teacherId)
    .maybeSingle()

  if (cErr) {
    return jsonResponse({ error: 'db_error', detail: cErr.message }, 500)
  }
  if (!classRow) {
    return jsonResponse({ error: 'forbidden' }, 403)
  }

  // ── 認可OK後にのみ生徒一覧を取得（class_members には display_name がないので2段階）──
  const { data: members, error: mErr } = await supabase
    .from('class_members')
    .select('user_id')
    .eq('class_id', classroomId)
    .eq('status', 'approved')

  if (mErr) {
    return jsonResponse({ error: 'db_error', detail: mErr.message }, 500)
  }
  const studentIds = ((members ?? []) as MemberRow[]).map((m) => m.user_id)
  if (studentIds.length === 0) {
    return jsonResponse({ alerts: [] })
  }

  // display_name は public.users から JOIN なしで別取得
  const { data: userRows, error: uErr } = await supabase
    .from('users')
    .select('id, display_name')
    .in('id', studentIds)

  if (uErr) {
    return jsonResponse({ error: 'db_error', detail: uErr.message }, 500)
  }

  const nameMap = new Map<string, string>()
  for (const u of (userRows ?? []) as UserRow[]) {
    nameMap.set(u.id, u.display_name ?? '(名前未設定)')
  }

  // ── 必要データを一括取得 ──────────────────────
  // 1. 全生徒の最近の town_talk_logs（時系列で必要）
  const sinceForLongSilence = new Date(Date.now() - LONG_SILENCE_DAYS * 24 * 60 * 60 * 1000)
  const { data: logs, error: lErr } = await supabase
    .from('town_talk_logs')
    .select('id, user_id, scenario_id, fail_count, is_completed, created_at')
    .in('user_id', studentIds)
    .order('created_at', { ascending: false })
    .limit(2000)

  if (lErr) {
    return jsonResponse({ error: 'db_error', detail: lErr.message }, 500)
  }

  // 2. 全生徒の town_talk_progress（last_played_at / last_success_at）
  const { data: progress, error: pErr } = await supabase
    .from('town_talk_progress')
    .select('user_id, scenario_id, success_count, last_played_at, last_success_at')
    .in('user_id', studentIds)

  if (pErr) {
    return jsonResponse({ error: 'db_error', detail: pErr.message }, 500)
  }

  // 生徒別にログを集約
  const logsByUser = new Map<string, LogRow[]>()
  for (const l of (logs ?? []) as LogRow[]) {
    const arr = logsByUser.get(l.user_id) ?? []
    arr.push(l)
    logsByUser.set(l.user_id, arr)
  }

  // 生徒別 progress を集約
  const progressByUser = new Map<string, ProgressRow[]>()
  for (const p of (progress ?? []) as ProgressRow[]) {
    const arr = progressByUser.get(p.user_id) ?? []
    arr.push(p)
    progressByUser.set(p.user_id, arr)
  }

  const alerts: Alert[] = []
  const now = Date.now()

  for (const studentId of studentIds) {
    const studentName = nameMap.get(studentId) ?? '(不明)'
    const userLogs = logsByUser.get(studentId) ?? []
    const userProgress = progressByUser.get(studentId) ?? []
    const lastPlayedAt = userLogs[0]?.created_at ?? null

    // ── high_fail_rate ──
    const recentLogs = userLogs.slice(0, HIGH_FAIL_RECENT_N)
    const highFailLogs = recentLogs.filter((l) => l.fail_count >= HIGH_FAIL_FAIL_THRESHOLD)
    if (highFailLogs.length >= HIGH_FAIL_OCCURRENCE) {
      alerts.push({
        user_id: studentId,
        student_name: studentName,
        alert_type: 'high_fail_rate',
        details: `直近${HIGH_FAIL_RECENT_N}回で失敗${HIGH_FAIL_FAIL_THRESHOLD}回以上が${highFailLogs.length}件`,
        last_played_at: lastPlayedAt,
        log_ids_to_review: highFailLogs.map((l) => l.id),
      })
    }

    // ── pattern_stuck ──
    // シナリオ別に直近 PATTERN_STUCK_CONSECUTIVE 件が全て fail_count >= 2 か
    const logsByScenario = new Map<string, LogRow[]>()
    for (const l of userLogs) {
      const arr = logsByScenario.get(l.scenario_id) ?? []
      arr.push(l)
      logsByScenario.set(l.scenario_id, arr)
    }
    for (const [sid, sLogs] of logsByScenario.entries()) {
      const recent = sLogs.slice(0, PATTERN_STUCK_CONSECUTIVE)
      if (
        recent.length >= PATTERN_STUCK_CONSECUTIVE &&
        recent.every((l) => l.fail_count >= PATTERN_STUCK_FAIL_THRESHOLD)
      ) {
        alerts.push({
          user_id: studentId,
          student_name: studentName,
          alert_type: 'pattern_stuck',
          details: `${sid} で${PATTERN_STUCK_CONSECUTIVE}回連続で失敗${PATTERN_STUCK_FAIL_THRESHOLD}回以上`,
          last_played_at: recent[0].created_at,
          log_ids_to_review: recent.map((l) => l.id),
        })
        break // 1 シナリオで成立すれば十分
      }
    }

    // ── long_silence ──
    // last_played_at が 14日以上前、または記録なし
    if (lastPlayedAt && new Date(lastPlayedAt) < sinceForLongSilence) {
      alerts.push({
        user_id: studentId,
        student_name: studentName,
        alert_type: 'long_silence',
        details: `Town Talk を${LONG_SILENCE_DAYS}日間プレイしていない`,
        last_played_at: lastPlayedAt,
      })
    }

    // ── first_completion ──
    // success_count == 1 かつ last_success_at が直近7日以内
    const recentFirsts = userProgress.filter((p) => {
      if (p.success_count !== 1 || !p.last_success_at) return false
      return now - new Date(p.last_success_at).getTime() <= FIRST_COMPLETION_LOOKBACK_MS
    })
    for (const p of recentFirsts) {
      alerts.push({
        user_id: studentId,
        student_name: studentName,
        alert_type: 'first_completion',
        details: `${p.scenario_id} を初めてクリア`,
        last_played_at: p.last_success_at,
      })
    }
  }

  // ── 緊急度順に並べ替え ────────────────────────
  alerts.sort((a, b) => ALERT_PRIORITY[a.alert_type] - ALERT_PRIORITY[b.alert_type])

  return jsonResponse({ alerts })
})
