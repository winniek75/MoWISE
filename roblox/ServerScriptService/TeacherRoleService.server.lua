-- TeacherRoleService.server.lua
-- C-3.1 Phase 3 / 先生ロール判定サービス
--
-- 役割：
--   1. Players.PlayerAdded を購読
--   2. 連携完了プレイヤー（mowiseUserId が設定済み）に対して
--      academy-check-teacher-role を呼び出し
--   3. is_teacher: true なら以下の Attribute を設定
--        - IsTeacher        (bool)
--        - TeacherClassIds  (string: JSON 配列)
--        - TeacherUserId    (string: mowise user_id)
--
-- 既知制約 (C-1.2 §4-1)：
--   既存 roblox-heartbeat / roblox-sync-pull が user_id を返さないため、
--   mowiseUserId は手動運用前提。
--   _G.setMoWISEUserId(player, userId) 後に _G.checkTeacherRole(player) で
--   再判定可能なグローバル関数を提供する。

local Players           = game:GetService("Players")
local HttpService       = game:GetService("HttpService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local API_BASE       = "https://yytxgxlhgotscwztlsqj.supabase.co/functions/v1"
local ROBLOX_API_KEY = "mowise_roblox_2026"

local remotes  = ReplicatedStorage:WaitForChild("MoWISERemotes")
local getSyncBF = remotes:WaitForChild("GetPlayerSync", 30)

------------------------------------------------------------------------
-- ヘルパー：SyncService 取得（C-1.2 と同パターン）
------------------------------------------------------------------------
local function getSyncService(player)
    if not getSyncBF then return nil end
    local ok, sync = pcall(function()
        return getSyncBF:Invoke(player.UserId)
    end)
    return ok and sync or nil
end

local function getMoWISEUserId(player)
    local sync = getSyncService(player)
    if not sync then return nil end
    return sync.mowiseUserId
end

------------------------------------------------------------------------
-- Edge Function 呼出：academy-check-teacher-role
-- 戻り値：{ is_teacher, class_ids, teacher_id } or nil
------------------------------------------------------------------------
local function callCheckTeacherRole(userId)
    local payload = HttpService:JSONEncode({ user_id = userId })

    local ok, response = pcall(function()
        return HttpService:RequestAsync({
            Url     = API_BASE .. "/academy-check-teacher-role",
            Method  = "POST",
            Headers = {
                ["Authorization"] = "Bearer " .. ROBLOX_API_KEY,
                ["Content-Type"]  = "application/json",
            },
            Body    = payload,
        })
    end)

    if not ok then
        warn("[TeacherRole] HTTP error: " .. tostring(response))
        return nil
    end

    if not response.Success then
        warn(("[TeacherRole] HTTP %s: %s"):format(
            tostring(response.StatusCode), tostring(response.Body)))
        return nil
    end

    local decodeOk, decoded = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    if not decodeOk then
        warn("[TeacherRole] JSON decode error: " .. tostring(response.Body))
        return nil
    end

    return decoded
end

------------------------------------------------------------------------
-- 先生ロール判定本体
------------------------------------------------------------------------
local function checkTeacherRole(player)
    if not player or not player.Parent then
        warn("[TeacherRole] checkTeacherRole: invalid player")
        return false
    end

    local userId = getMoWISEUserId(player)
    if not userId then
        print(("[TeacherRole] %s: mowiseUserId 未設定（連携完了待ち）"):format(player.Name))
        player:SetAttribute("IsTeacher", false)
        return false
    end

    local result = callCheckTeacherRole(userId)
    if not result then
        warn(("[TeacherRole] %s: API 呼出失敗"):format(player.Name))
        return false
    end

    if result.is_teacher then
        local classIdsJson = HttpService:JSONEncode(result.class_ids or {})
        player:SetAttribute("IsTeacher",       true)
        player:SetAttribute("TeacherClassIds", classIdsJson)
        player:SetAttribute("TeacherUserId",   result.teacher_id or userId)
        print(("[TeacherRole] %s: 先生として認識 (classes=%d)"):format(
            player.Name, #(result.class_ids or {})))
        return true
    else
        player:SetAttribute("IsTeacher",       false)
        player:SetAttribute("TeacherClassIds", "[]")
        print(("[TeacherRole] %s: 生徒"):format(player.Name))
        return false
    end
end

------------------------------------------------------------------------
-- PlayerAdded フック
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    -- 初期状態：未連携扱いで Attribute をリセット
    player:SetAttribute("IsTeacher",       false)
    player:SetAttribute("TeacherClassIds", "[]")

    -- 5秒待ってから初回判定（PlayerJoinHandler の sync 完了を待つ）
    task.delay(5, function()
        if player and player.Parent then
            checkTeacherRole(player)
        end
    end)
end)

------------------------------------------------------------------------
-- グローバル公開（手動運用補助）
-- 例：Server Console で _G.setMoWISEUserId(player, "2dead3d3-...") 後に
--     _G.checkTeacherRole(player) を実行すると先生 Attribute が設定される
------------------------------------------------------------------------
_G.checkTeacherRole = checkTeacherRole

print("[TeacherRole] TeacherRoleService ready")
