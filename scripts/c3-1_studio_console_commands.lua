-- =====================================================
-- C-3.1 Phase 5 / Studio Server Console コマンド集
-- =====================================================
-- Studio Play モード起動後、Server Console（View → Output → Server）に
-- 以下を順次貼り付けて実行する。
--
-- 前提：
--   - Rojo で本ブランチを sync 済み（Bootstrap_TakeoverRemotes / TeacherRoleService /
--     TakeoverService / NPCTakeoverListener / TakeoverClientUI が読み込まれている）
--   - Zone 2 NPC（Maria/Sam/Lily）が既に移住完了（または手動で建物 5/10/15 棟達成）
-- =====================================================


-- -----------------------------------------------------
-- シナリオ A：先生として通常フロー
-- -----------------------------------------------------

-- A-1. プレイヤー取得 + mowiseUserId を先生 ID に設定
local p1 = game.Players:GetPlayers()[1]
_G.setMoWISEUserId(p1, "2dead3d3-58a6-4c77-a1f3-6f3e524422e2")

-- A-2. 先生ロール再判定（5秒以内に IsTeacher = true になる）
_G.checkTeacherRole(p1)

-- A-3. Attribute 検証
print("IsTeacher       =", p1:GetAttribute("IsTeacher"))
print("TeacherClassIds =", p1:GetAttribute("TeacherClassIds"))
print("TeacherUserId   =", p1:GetAttribute("TeacherUserId"))

-- A-4. （手動）Maria に近づき、TeacherTakeoverPrompt を E キーで実行
--      → サーバーログに "[TakeoverService] Started session XXX for maria" が表示される
--      → Supabase Dashboard で academy_npc_takeovers に新行が追加される

-- A-5. アクティブセッション状態確認
print("Active maria =", _G.getActiveTakeover("maria"))

-- A-6. （手動）Roblox 標準 Chat で "Hello! What would you like to drink?" と打つ
--      → 全プレイヤーに表示される（Roblox 標準動作）

-- A-7. （手動）Maria に近づき、TeacherTakeoverPrompt を再度 E で実行（"引き継ぎ終了"）
--      → サーバーログに "[TakeoverService] Ended session XXX" が表示される
--      → Supabase で ended_at が記録される


-- -----------------------------------------------------
-- シナリオ B：生徒からのブロック確認
-- -----------------------------------------------------
-- Studio で 2 プレイヤーモード起動 → Player2 が join したら以下：

local p2 = game.Players:GetPlayers()[2]
_G.setMoWISEUserId(p2, "0c871272-0391-4b82-8e69-6493f06377f9")
_G.checkTeacherRole(p2)
print("p2 IsTeacher =", p2:GetAttribute("IsTeacher"))  -- false 期待

-- B-1. Player1（先生）が Maria を引き継ぎ中の状態で
-- B-2. Player2（生徒）が Maria に近づくと
--      → 既存 TownTalkPrompt（"英会話する"）が Enabled=false になっており表示されない
--      → 期待：ProximityPrompt が出ない
-- B-3. Player1 が「引き継ぎ終了」した後
--      → Player2 が再度 Maria に近づくと "英会話する" が表示される


-- -----------------------------------------------------
-- シナリオ C：エラーケース
-- -----------------------------------------------------

-- C-1. 同 NPC 二重引き継ぎ（409）
--      Player1 が Maria を引き継ぎ中に、サーバー側で TakeoverService:Start を再呼出
print("Duplicate start =", _G.TakeoverService:Start(p1, "maria"))  -- nil 期待 + warn ログ

-- C-2. 別教室の先生（403）→ TeacherClassIds を不正値で上書きして検証
local origClassIds = p1:GetAttribute("TeacherClassIds")
p1:SetAttribute("TeacherClassIds", '["00000000-0000-0000-0000-000000000000"]')
print("Wrong class start =", _G.TakeoverService:Start(p1, "sam"))  -- nil 期待 + warn ログ
p1:SetAttribute("TeacherClassIds", origClassIds)
