// supabase/functions/roblox-heartbeat/index.ts
// Roblox側から60秒ごとの接続確認 + ブースト状態取得

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ROBLOX_API_KEY = Deno.env.get("ROBLOX_API_KEY") ?? "";

Deno.serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers":
          "Content-Type, X-MoWISE-API-Key, X-MoWISE-Link-Token, X-Roblox-User-Id",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  // API Key 検証
  const apiKey = req.headers.get("X-MoWISE-API-Key");
  if (apiKey !== ROBLOX_API_KEY) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const robloxUserId = req.headers.get("X-Roblox-User-Id");
    const linkToken = req.headers.get("X-MoWISE-Link-Token");

    const { current_zone, current_coins, play_time_seconds } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 連携未済（トークンなし）の場合
    if (!linkToken || !robloxUserId) {
      return new Response(
        JSON.stringify({
          linked: false,
          user_id: null,
          boost_active: false,
          coin_multiplier: 1.0,
          teacher_message: null,
          web_pattern_updates: [],
          server_time: new Date().toISOString(),
          daily_login_bonus_available: false,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // Link Token + Roblox User ID の検証
    const { data: link, error: linkError } = await supabase
      .from("roblox_links")
      .select("*")
      .eq("link_token", linkToken)
      .eq("roblox_user_id", parseInt(robloxUserId))
      .eq("status", "active")
      .maybeSingle();

    if (linkError || !link) {
      return new Response(
        JSON.stringify({
          linked: false,
          user_id: null,
          boost_active: false,
          coin_multiplier: 1.0,
          teacher_message: null,
          web_pattern_updates: [],
          server_time: new Date().toISOString(),
          daily_login_bonus_available: false,
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    // トークン有効期限チェック
    if (new Date(link.token_expires_at) < new Date()) {
      return new Response(
        JSON.stringify({
          linked: false,
          user_id: null,
          boost_active: false,
          coin_multiplier: 1.0,
          teacher_message: null,
          error: "TOKEN_EXPIRED",
          server_time: new Date().toISOString(),
        }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
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

    // 先生メッセージの取得（将来拡張）
    // TODO: teacher_messages テーブルから未読メッセージを取得

    // 日替わりログインボーナスチェック
    // TODO: 本日分のボーナス受取済みかチェック

    return new Response(
      JSON.stringify({
        linked: true,
        user_id: link.user_id ?? null,
        boost_active: true,
        coin_multiplier: 1.5,
        teacher_message: null,
        web_pattern_updates: [],
        server_time: new Date().toISOString(),
        daily_login_bonus_available: false,
        // 連携成功直後のポーリング用：link_token を返す
        link_token: linkToken,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Heartbeat error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
