// supabase/functions/roblox-link-generate/index.ts
// Roblox側から6桁連携コードを発行するEdge Function

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const ROBLOX_API_KEY = Deno.env.get("ROBLOX_API_KEY") ?? "";
// 紛らわしい文字を除外（0/O, 1/I/L）
const CODE_CHARS = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 6;
const CODE_TTL_SECONDS = 300; // 5分

function generateCode(): string {
  let code = "";
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CODE_CHARS[Math.floor(Math.random() * CODE_CHARS.length)];
  }
  return code;
}

Deno.serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type, X-MoWISE-API-Key, X-Roblox-User-Id",
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
    const { roblox_user_id, roblox_display_name } = await req.json();

    if (!roblox_user_id) {
      return new Response(
        JSON.stringify({ error: "roblox_user_id is required" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // 既存の未使用コードを無効化
    await supabase
      .from("roblox_link_codes")
      .update({ status: "expired" })
      .eq("roblox_user_id", roblox_user_id)
      .eq("status", "pending");

    // 6桁コード生成（重複チェック付き）
    let code = generateCode();
    let retries = 0;
    while (retries < 5) {
      const { data: existing } = await supabase
        .from("roblox_link_codes")
        .select("id")
        .eq("code", code)
        .eq("status", "pending")
        .maybeSingle();

      if (!existing) break;
      code = generateCode();
      retries++;
    }

    const expiresAt = new Date(Date.now() + CODE_TTL_SECONDS * 1000);

    const { error: insertError } = await supabase
      .from("roblox_link_codes")
      .insert({
        code,
        roblox_user_id,
        roblox_display_name: roblox_display_name || null,
        status: "pending",
        expires_at: expiresAt.toISOString(),
      });

    if (insertError) {
      console.error("Insert error:", insertError);
      return new Response(
        JSON.stringify({ error: "Failed to generate code" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({
        code,
        expires_at: expiresAt.toISOString(),
        ttl_seconds: CODE_TTL_SECONDS,
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    console.error("Unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
