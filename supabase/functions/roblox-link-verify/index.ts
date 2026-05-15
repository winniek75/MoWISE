// supabase/functions/roblox-link-verify/index.ts
// Webアプリ側から6桁コードを照合してアカウント連携を確立
// v7: 全レスポンスに CORS ヘッダ統一付与
// v8: UNIQUE(user_id) 衝突修正
//     - 同じ user が解除後に再連携した際、既存行を status='active' に戻す UPDATE で処理
//     - 同じ user が別 Roblox アカウントに切り替えるケースも UPDATE で対応
//     - 他人が同じ Roblox を active 占有している場合は ALREADY_LINKED 409

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, apikey, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

function respond(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), { status, headers: CORS_HEADERS });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: CORS_HEADERS });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return respond({ error: "Authorization required" }, 401);
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabaseAuth = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userError } = await supabaseAuth.auth.getUser();

    if (userError || !user) {
      return respond({ error: "Invalid token" }, 401);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { code } = await req.json();
    if (!code || code.length !== 6) {
      return respond({ error: "Invalid code format" }, 400);
    }

    const { data: linkCode, error: findError } = await supabase
      .from("roblox_link_codes")
      .select("*")
      .eq("code", code.toUpperCase())
      .eq("status", "pending")
      .maybeSingle();

    if (findError || !linkCode) {
      return respond({ error: "CODE_NOT_FOUND" }, 404);
    }

    if (new Date(linkCode.expires_at) < new Date()) {
      await supabase
        .from("roblox_link_codes")
        .update({ status: "expired" })
        .eq("id", linkCode.id);
      return respond({ error: "CODE_EXPIRED" }, 410);
    }

    // 他人がこの Roblox アカウントを active 占有していないかチェック
    const { data: otherUserLink } = await supabase
      .from("roblox_links")
      .select("id, user_id")
      .eq("roblox_user_id", linkCode.roblox_user_id)
      .eq("status", "active")
      .neq("user_id", user.id)
      .maybeSingle();

    if (otherUserLink) {
      return respond({ error: "ALREADY_LINKED" }, 409);
    }

    // 自分の既存行（status 問わず）を探す
    const { data: ownLink } = await supabase
      .from("roblox_links")
      .select("id")
      .eq("user_id", user.id)
      .maybeSingle();

    const linkToken = "mwl_" + crypto.randomUUID().replace(/-/g, "");
    const tokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    if (ownLink) {
      // 既存行 UPDATE：Roblox 切り替え・解除後の再連携もカバー
      const { error: updateError } = await supabase
        .from("roblox_links")
        .update({
          roblox_user_id: linkCode.roblox_user_id,
          roblox_display_name: linkCode.roblox_display_name,
          link_token: linkToken,
          status: "active",
          token_expires_at: tokenExpiresAt.toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", ownLink.id);

      if (updateError) {
        console.error("Link update error:", updateError);
        return respond({ error: "Failed to update link" }, 500);
      }
    } else {
      const { error: linkError } = await supabase
        .from("roblox_links")
        .insert({
          user_id: user.id,
          roblox_user_id: linkCode.roblox_user_id,
          roblox_display_name: linkCode.roblox_display_name,
          link_token: linkToken,
          status: "active",
          token_expires_at: tokenExpiresAt.toISOString(),
        });

      if (linkError) {
        console.error("Link insert error:", linkError);
        return respond({ error: "Failed to create link" }, 500);
      }
    }

    await supabase
      .from("roblox_link_codes")
      .update({
        status: "used",
        used_by: user.id,
        used_at: new Date().toISOString(),
      })
      .eq("id", linkCode.id);

    await supabase
      .from("users")
      .update({
        roblox_linked: true,
        roblox_user_id: linkCode.roblox_user_id,
      })
      .eq("id", user.id);

    return respond({
      linked: true,
      roblox_display_name: linkCode.roblox_display_name,
      link_token: linkToken,
      boosts: {
        coin_multiplier: 1.5,
        premium_materials: true,
      },
    }, 200);
  } catch (err) {
    console.error("Unexpected error:", err);
    return respond({ error: "Internal server error" }, 500);
  }
});
