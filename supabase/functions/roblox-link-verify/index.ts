// supabase/functions/roblox-link-verify/index.ts
// Webアプリ側から6桁コードを照合してアカウント連携を確立

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

Deno.serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type, Authorization",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
      },
    });
  }

  try {
    // Supabase JWT からユーザーIDを取得
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Authorization required" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // ユーザー認証用クライアント
    const supabaseAuth = createClient(supabaseUrl, Deno.env.get("SUPABASE_ANON_KEY")!, {
      global: { headers: { Authorization: authHeader } },
    });
    const { data: { user }, error: userError } = await supabaseAuth.auth.getUser();

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: "Invalid token" }),
        { status: 401, headers: { "Content-Type": "application/json" } }
      );
    }

    // サービスロールクライアント（DB操作用）
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    const { code } = await req.json();
    if (!code || code.length !== 6) {
      return new Response(
        JSON.stringify({ error: "Invalid code format" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // コード照合
    const { data: linkCode, error: findError } = await supabase
      .from("roblox_link_codes")
      .select("*")
      .eq("code", code.toUpperCase())
      .eq("status", "pending")
      .maybeSingle();

    if (findError || !linkCode) {
      return new Response(
        JSON.stringify({ error: "CODE_NOT_FOUND" }),
        { status: 404, headers: { "Content-Type": "application/json" } }
      );
    }

    // 有効期限チェック
    if (new Date(linkCode.expires_at) < new Date()) {
      await supabase
        .from("roblox_link_codes")
        .update({ status: "expired" })
        .eq("id", linkCode.id);

      return new Response(
        JSON.stringify({ error: "CODE_EXPIRED" }),
        { status: 410, headers: { "Content-Type": "application/json" } }
      );
    }

    // 既存の連携チェック（同じRoblox IDが別ユーザーと連携済み）
    const { data: existingLink } = await supabase
      .from("roblox_links")
      .select("id, user_id")
      .eq("roblox_user_id", linkCode.roblox_user_id)
      .eq("status", "active")
      .maybeSingle();

    if (existingLink && existingLink.user_id !== user.id) {
      return new Response(
        JSON.stringify({ error: "ALREADY_LINKED" }),
        { status: 409, headers: { "Content-Type": "application/json" } }
      );
    }

    // Link Token 生成
    const linkToken = "mwl_" + crypto.randomUUID().replace(/-/g, "");
    const tokenExpiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000); // 30日

    // 既存の連携があれば更新、なければ新規作成
    if (existingLink) {
      // 同じユーザーが再連携
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
        return new Response(
          JSON.stringify({ error: "Failed to create link" }),
          { status: 500, headers: { "Content-Type": "application/json" } }
        );
      }
    }

    // コードを使用済みにする
    await supabase
      .from("roblox_link_codes")
      .update({
        status: "used",
        used_by: user.id,
        used_at: new Date().toISOString(),
      })
      .eq("id", linkCode.id);

    // users テーブルのフラグ更新
    await supabase
      .from("users")
      .update({
        roblox_linked: true,
        roblox_user_id: linkCode.roblox_user_id,
      })
      .eq("id", user.id);

    return new Response(
      JSON.stringify({
        linked: true,
        roblox_display_name: linkCode.roblox_display_name,
        link_token: linkToken,
        boosts: {
          coin_multiplier: 1.5,
          premium_materials: true,
        },
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
