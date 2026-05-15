// supabase/functions/roblox-heartbeat/index.ts
// Roblox側から60秒ごとの接続確認 + ブースト状態取得
// v8: パイロット準備6 拡張
//     X-MoWISE-Link-Token 不在でも X-Roblox-User-Id 単独で連携状態を判定する
//     シナリオ：Webで初回連携完了後、Roblox サーバーが linkToken をまだ保有していないタイミングでも
//     heartbeat が linked=true を返せるようにする。API キー認証は維持、roblox_links は service_role で読む

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ROBLOX_API_KEY = Deno.env.get("ROBLOX_API_KEY") ?? "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "Content-Type, X-MoWISE-API-Key, X-MoWISE-Link-Token, X-Roblox-User-Id",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: CORS_HEADERS });
}

function unlinkedBody() {
  return {
    linked: false,
    user_id: null,
    boost_active: false,
    coin_multiplier: 1.0,
    teacher_message: null,
    web_pattern_updates: [],
    server_time: new Date().toISOString(),
    daily_login_bonus_available: false,
  };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  // API Key 検証
  const apiKey = req.headers.get("X-MoWISE-API-Key");
  if (apiKey !== ROBLOX_API_KEY) {
    return respond({ error: "Unauthorized" }, 401);
  }

  try {
    const robloxUserId = req.headers.get("X-Roblox-User-Id");
    const linkToken = req.headers.get("X-MoWISE-Link-Token");

    const { current_zone, current_coins, play_time_seconds } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // robloxUserId も不在なら unlinked
    if (!robloxUserId) {
      return respond(unlinkedBody(), 200);
    }

    const robloxUserIdNum = parseInt(robloxUserId);

    // 連携行検索：linkToken ありなら token + roblox_user_id 、なければ roblox_user_id だけで active 行を追跡
    let linkQuery = supabase
      .from("roblox_links")
      .select("*")
      .eq("roblox_user_id", robloxUserIdNum)
      .eq("status", "active");

    if (linkToken) {
      linkQuery = linkQuery.eq("link_token", linkToken);
    }

    const { data: link, error: linkError } = await linkQuery.maybeSingle();

    if (linkError || !link) {
      return respond(unlinkedBody(), 200);
    }

    // トークン有効期限チェック
    if (new Date(link.token_expires_at) < new Date()) {
      return respond({
        ...unlinkedBody(),
        error: "TOKEN_EXPIRED",
      }, 200);
    }

    // 最終同期時刻を更新
    await supabase
      .from("roblox_links")
      .update({
        last_sync_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq("id", link.id);

    // users テーブルの最終プレイ時刻更新
    await supabase
      .from("users")
      .update({ roblox_last_played_at: new Date().toISOString() })
      .eq("id", link.user_id);

    return respond({
      linked: true,
      user_id: link.user_id ?? null,
      boost_active: true,
      coin_multiplier: 1.5,
      teacher_message: null,
      web_pattern_updates: [],
      server_time: new Date().toISOString(),
      daily_login_bonus_available: false,
      // Roblox 側に最新 linkToken を返す（初回連携検知時に保存可能）
      link_token: link.link_token,
    }, 200);
  } catch (err) {
    console.error("Heartbeat error:", err);
    return respond({ error: "Internal server error" }, 500);
  }
});
