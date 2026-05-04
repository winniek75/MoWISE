#!/usr/bin/env bash
# =============================================================================
# Town Talk cURL test script (C-1.3 / Phase 6)
#
# 3 つの Edge Function を本番デプロイ環境に対してテストし、
# 仕様書 §5 / 実装ガイド §4 で定義された 10 ケース（7 正常系 + 3 異常系）を検証する。
#
# 使い方:
#   1. 必要な環境変数をセット（後述）
#   2. ./scripts/curl_test_town_talk.sh で実行
#
# 必要な環境変数:
#   SUPABASE_URL       : https://yytxgxlhgotscwztlsqj.supabase.co
#   ROBLOX_API_KEY     : mowise_roblox_2026
#   TEST_USER_ID       : 既存生徒の auth.users.id (UUID)
#   TEST_CLASSROOM_ID  : 既存 classes.id (UUID)、TEST_USER_ID が approved 状態で所属
#   TEST_TEACHER_JWT   : 教師の Supabase access_token（1時間で失効）
#
# 任意:
#   TEST_TEACHER_ID    : 文脈表示のみ（実検証では使用しない）
#
# JWT 失効時の再取得手順:
#   1. Web アプリ (https://mowise.vercel.app) に教師アカウントでログイン
#   2. ブラウザの DevTools → Application → Local Storage → mowise.vercel.app
#   3. キー sb-yytxgxlhgotscwztlsqj-auth-token の値（JSON）から
#      "access_token" フィールドを抽出
#   4. export TEST_TEACHER_JWT="eyJ..." して再実行
#
# 依存ツール:
#   - bash (macOS 標準)
#   - curl (macOS 標準)
#   - jq (brew install jq)
# =============================================================================

set -uo pipefail

# ─── env チェック ─────────────────────────────────
: "${SUPABASE_URL:?Missing SUPABASE_URL}"
: "${ROBLOX_API_KEY:?Missing ROBLOX_API_KEY}"
: "${TEST_USER_ID:?Missing TEST_USER_ID}"
: "${TEST_CLASSROOM_ID:?Missing TEST_CLASSROOM_ID}"
: "${TEST_TEACHER_JWT:?Missing TEST_TEACHER_JWT}"

# 依存ツール確認
command -v jq >/dev/null 2>&1 || { echo "FATAL: jq is required. brew install jq" >&2; exit 1; }

# ─── 定数 ─────────────────────────────────────────
DUMMY_CLASSROOM="00000000-0000-0000-0000-000000000000"
FN_FETCH="$SUPABASE_URL/functions/v1/world-talk-scenario-fetch"
FN_SUBMIT="$SUPABASE_URL/functions/v1/world-talk-submit"
FN_ALERT="$SUPABASE_URL/functions/v1/world-talk-alert-check"

# ─── カラー出力 ──────────────────────────────────
if [ -t 1 ]; then
  C_GREEN='\033[32m'; C_RED='\033[31m'; C_YELLOW='\033[33m'; C_BLUE='\033[34m'; C_RESET='\033[0m'
else
  C_GREEN=''; C_RED=''; C_YELLOW=''; C_BLUE=''; C_RESET=''
fi

# ─── 結果収集 ────────────────────────────────────
declare -a RESULTS

# ─── 共通実行関数 ────────────────────────────────
# 引数:  $1=case番号 $2=case名 $3=expected_http $4=jq式（"ok" を返せば PASS）
#        以降は curl に渡す引数
run_case() {
  local num="$1" name="$2" expected_http="$3" jq_expr="$4"
  shift 4

  echo
  printf "${C_BLUE}=== Case %s: %s ===${C_RESET}\n" "$num" "$name"

  local resp http body
  resp=$(curl -sS -w $'\n%{http_code}' "$@" 2>&1)
  http="${resp##*$'\n'}"
  body="${resp%$'\n'*}"

  echo "HTTP: $http"
  if [ -n "$body" ]; then
    echo "Body:"
    echo "$body" | jq . 2>/dev/null || echo "$body"
  fi

  local check
  if [ -z "$body" ]; then
    check="empty_body"
  else
    check=$(echo "$body" | jq -r "$jq_expr" 2>/dev/null || echo "jq_failed")
  fi

  if [ "$http" = "$expected_http" ] && [ "$check" = "ok" ]; then
    printf "${C_GREEN}  ✓ PASS${C_RESET}\n"
    RESULTS+=("PASS|$num|$name")
  else
    printf "${C_RED}  ✗ FAIL (http=%s expected=%s, check=%s)${C_RESET}\n" "$http" "$expected_http" "$check"
    RESULTS+=("FAIL|$num|$name (http=$http, check=$check)")
  fi
}

echo
printf "${C_YELLOW}┌────────────────────────────────────────────────────────┐${C_RESET}\n"
printf "${C_YELLOW}│ Town Talk cURL test (C-1.3 Phase 6)                    │${C_RESET}\n"
printf "${C_YELLOW}│ Target: %-46s │${C_RESET}\n" "$SUPABASE_URL"
printf "${C_YELLOW}│ Student: %-45s │${C_RESET}\n" "$TEST_USER_ID"
printf "${C_YELLOW}│ Classroom: %-43s │${C_RESET}\n" "$TEST_CLASSROOM_ID"
printf "${C_YELLOW}└────────────────────────────────────────────────────────┘${C_RESET}\n"

# ============================================================
# 正常系 7 ケース
# ============================================================

# Case 1: 初回 fetch (maria) → first_play
# 期待: HTTP 200, selection_reason="first_play", scenario_id="maria_*"
run_case 1 "fetch maria first_play" 200 \
  'if .selection_reason == "first_play" and (.scenario_id | startswith("maria_")) then "ok" else "got reason=\(.selection_reason) sid=\(.scenario_id)" end' \
  -X POST "$FN_FETCH" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$TEST_USER_ID\",\"npc_id\":\"maria\",\"platform\":\"roblox\"}"

# Case 2: 初回 fetch (sam) → first_play
# 期待: HTTP 200, selection_reason="first_play", scenario_id="sam_*"
run_case 2 "fetch sam first_play" 200 \
  'if .selection_reason == "first_play" and (.scenario_id | startswith("sam_")) then "ok" else "got reason=\(.selection_reason) sid=\(.scenario_id)" end' \
  -X POST "$FN_FETCH" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$TEST_USER_ID\",\"npc_id\":\"sam\",\"platform\":\"roblox\"}"

# Case 3: 初回 fetch (lily) → first_play
# 期待: HTTP 200, selection_reason="first_play", scenario_id="lily_*"
run_case 3 "fetch lily first_play" 200 \
  'if .selection_reason == "first_play" and (.scenario_id | startswith("lily_")) then "ok" else "got reason=\(.selection_reason) sid=\(.scenario_id)" end' \
  -X POST "$FN_FETCH" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$TEST_USER_ID\",\"npc_id\":\"lily\",\"platform\":\"roblox\"}"

# Case 4: 全問正解 submit (maria_cafe_order_v1)
# 期待: HTTP 200, approval_status="auto_passed", rewards.coins_granted=50
run_case 4 "submit all-correct (maria_cafe_order_v1)" 200 \
  'if .approval_status == "auto_passed" and .rewards.coins_granted == 50 then "ok" else "got status=\(.approval_status) coins=\(.rewards.coins_granted)" end' \
  -X POST "$FN_SUBMIT" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\":\"$TEST_USER_ID\",
    \"scenario_id\":\"maria_cafe_order_v1\",
    \"selections\":[
      {\"turn\":1,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true},
      {\"turn\":2,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true},
      {\"turn\":3,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true},
      {\"turn\":4,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true},
      {\"turn\":5,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true}
    ],
    \"audio_urls\":[],
    \"duration_sec\":360,
    \"platform\":\"roblox\"
  }"

# Case 5: 3問失敗 submit (maria_cafe_morning_v2) → pending_review
# 期待: HTTP 200, approval_status="pending_review"
#       (fail_count=3 が FAIL_THRESHOLD_FOR_REVIEW=3 に達するため)
run_case 5 "submit 3-fails (maria_cafe_morning_v2) → pending_review" 200 \
  'if .approval_status == "pending_review" then "ok" else "got status=\(.approval_status)" end' \
  -X POST "$FN_SUBMIT" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"user_id\":\"$TEST_USER_ID\",
    \"scenario_id\":\"maria_cafe_morning_v2\",
    \"selections\":[
      {\"turn\":1,\"option_id\":2,\"is_correct\":false,\"is_acceptable\":false},
      {\"turn\":2,\"option_id\":3,\"is_correct\":false,\"is_acceptable\":false},
      {\"turn\":3,\"option_id\":4,\"is_correct\":false,\"is_acceptable\":false},
      {\"turn\":4,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true},
      {\"turn\":5,\"option_id\":1,\"is_correct\":true,\"is_acceptable\":true}
    ],
    \"audio_urls\":[],
    \"duration_sec\":480,
    \"platform\":\"roblox\"
  }"

# Case 6: alert-check (教師JWT, 自クラス)
# 期待: HTTP 200, alerts 配列に TEST_USER_ID が含まれる
#       (Case 5 で fail_count=3 が記録されるが high_fail_rate ルールは
#        「直近5回で fail≥3 が3件以上」のため 1 件では発動しない。
#        first_completion (Case 4 で初クリア) または long_silence の可能性あり。
#        → 配列に user_id が含まれていれば PASS とする緩い条件)
run_case 6 "alert-check teacher self-class" 200 \
  '.alerts | if length == 0 then "no_alerts (試走直後では正常な場合もある)" elif (map(.user_id == "'"$TEST_USER_ID"'") | any) then "ok" else "test_user_not_in_alerts" end' \
  -X GET "$FN_ALERT?classroom_id=$TEST_CLASSROOM_ID" \
  -H "Authorization: Bearer $TEST_TEACHER_JWT"

# Case 7: 同 user_id × maria 再 fetch
# 期待: HTTP 200, scenario_id != "maria_cafe_order_v1" (Case 4 でプレイ済みのため)
#       残り 2 シナリオから first_play で別物が返るか、復習タイミングなら spaced_review
run_case 7 "fetch maria re-call (skip already-played)" 200 \
  'if .scenario_id != "maria_cafe_order_v1" and (.scenario_id | startswith("maria_")) then "ok" else "got sid=\(.scenario_id) reason=\(.selection_reason)" end' \
  -X POST "$FN_FETCH" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$TEST_USER_ID\",\"npc_id\":\"maria\",\"platform\":\"roblox\"}"

# ============================================================
# 異常系 3 ケース
# ============================================================

# Case 8: 認証なし fetch
# 期待: HTTP 401, error="unauthorized"
run_case 8 "fetch without auth → 401" 401 \
  'if .error == "unauthorized" then "ok" else "got error=\(.error)" end' \
  -X POST "$FN_FETCH" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$TEST_USER_ID\",\"npc_id\":\"maria\"}"

# Case 9: 不正な npc_id ("bob")
# 期待: HTTP 400, error="invalid_npc_id"
run_case 9 "fetch invalid npc_id → 400" 400 \
  'if .error == "invalid_npc_id" then "ok" else "got error=\(.error)" end' \
  -X POST "$FN_FETCH" \
  -H "Authorization: Bearer $ROBLOX_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$TEST_USER_ID\",\"npc_id\":\"bob\"}"

# Case 10: 他クラスの classroom_id (ダミー UUID)
# 期待: HTTP 403, error="forbidden"
#       (認可確認の厳格化検証: 教師が他人のクラスを覗けない)
run_case 10 "alert-check other classroom → 403 forbidden" 403 \
  'if .error == "forbidden" then "ok" else "got error=\(.error)" end' \
  -X GET "$FN_ALERT?classroom_id=$DUMMY_CLASSROOM" \
  -H "Authorization: Bearer $TEST_TEACHER_JWT"

# ============================================================
# サマリ
# ============================================================
echo
printf "${C_YELLOW}┌────────────────────────────────────────────────────────┐${C_RESET}\n"
printf "${C_YELLOW}│ Test Summary                                           │${C_RESET}\n"
printf "${C_YELLOW}└────────────────────────────────────────────────────────┘${C_RESET}\n"

PASS_COUNT=0
FAIL_COUNT=0
for r in "${RESULTS[@]}"; do
  status="${r%%|*}"
  rest="${r#*|}"
  num="${rest%%|*}"
  name="${rest#*|}"
  if [ "$status" = "PASS" ]; then
    printf "  ${C_GREEN}✓ Case %s: %s${C_RESET}\n" "$num" "$name"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    printf "  ${C_RED}✗ Case %s: %s${C_RESET}\n" "$num" "$name"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done

TOTAL=${#RESULTS[@]}
echo
printf "Total: %d / Passed: ${C_GREEN}%d${C_RESET} / Failed: ${C_RED}%d${C_RESET}\n" "$TOTAL" "$PASS_COUNT" "$FAIL_COUNT"
echo

if [ "$FAIL_COUNT" -gt 0 ]; then
  echo "→ Some cases failed. Review the output above for details."
  exit 1
fi
echo "→ All cases passed. ✓"
exit 0
