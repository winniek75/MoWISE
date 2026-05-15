// supabase/functions/roblox-link-verify/index.ts
// Webアプリ側から6桁コードを照合してアカウント連携を確立
// v7: 全レスポンスに CORS ヘッダ統一（ブラウザからの fetch hang を解消）

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

    const { data: existingLink } = await supabase
      .from("roblox_links")
      .select("id, user_id")
      .eq("roblox_user_id", linkCode.roblox_user_id)
      .eq("status", "active")
      .maybeSingle();

    if (existingLink && existingLink.user_id !== user.id) {
      return respond({ error: "ALREADY_LINKED" }, 409);
    }

    const linkToken = "mwl_" + crypto.randomUUID().replace(/-/g, "");
    const tokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

    if (existingLink) {
      await supabase
        .from("roblox_links")
        .update({
          link_token: linkToken,
          status: "active",
          token_expires_at: tokenExpiresAt.toISOString(),
          updated_at: new Date().toISOString(),
        })
        .eq("id", existingLink.id);
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
