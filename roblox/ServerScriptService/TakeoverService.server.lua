-- TakeoverService.server.lua
-- C-3.1 Phase 3 / 引き継ぎセッション制御
--
-- 役割：
--   1. TakeoverService:Start(player, npcId) → sessionId or nil
--   2. TakeoverService:End(player, npcId)   → bool
--   3. アクティブセッション状態の集中管理
--      _G.getActiveTakeover(npcId) → { sessionId, teacherUserId, teacherPlayer } or nil
--   4. プレイヤー切断時の自動 End

local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local API_BASE       = "https://yytxgxlhgotscwztlsqj.supabase.co/functions/v1"
local ROBLOX_API_KEY = "mowise_roblox_2026"

local remotes          = ReplicatedStorage:WaitForChild("MoWISERemotes")
local takeoverStarted  = remotes:WaitForChild("takeover_started")
local takeoverEnded    = remotes:WaitForChild("takeover_ended")

------------------------------------------------------------------------
-- 状態管理
-- active_takeovers[npcId] = {
--   sessionId       : string  (Supabase UUID)
--   teacherUserId   : string  (mowise user_id)
--   teacherPlayer   : Player  (Roblox プレイヤー参照)
--   classId         : string
--   startedAt       : number  (os.time)
-- }
------------------------------------------------------------------------
local active_takeovers = {}

------------------------------------------------------------------------
-- HTTP 共通（Bearer 認証）
------------------------------------------------------------------------
local function bearerRequest(method, endpoint, body)
    local jsonBody = body and HttpService:JSONEncode(body) or nil

    local ok, response = pcall(function()
        return HttpService:RequestAsync({
            Url     = API_BASE .. endpoint,
            Method  = method,
            Headers = {
                ["Authorization"] = "Bearer " .. ROBLOX_API_KEY,
                ["Content-Type"]  = "application/json",
            },
            Body    = jsonBody,
        })
    end)

    if not ok then
        warn("[Takeover] HTTP error: " .. tostring(response))
        return false, nil, 0
    end

    local decoded = nil
    if response.Body and #response.Body > 0 then
        local decodeOk, parsed = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decodeOk then decoded = parsed end
    end

    return response.Success, decoded, response.StatusCode
end

------------------------------------------------------------------------
-- TeacherClassIds Attribute から class_id を抽出（複数なら最初の 1 件）
------------------------------------------------------------------------
local function getFirstClassId(player)
    local raw = player:GetAttribute("TeacherClassIds")
    if not raw or raw == "" then return nil end

    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not ok or type(decoded) ~= "table" then return nil end
    return decoded[1]
end

------------------------------------------------------------------------
-- TakeoverService:Start
------------------------------------------------------------------------
local TakeoverService = {}

function TakeoverService:Start(player, npcId)
    if not player or not npcId then
        warn("[Takeover] Start: invalid args")
        return nil
    end

    if not player:GetAttribute("IsTeacher") then
        warn(("[Takeover] %s: Start denied (not teacher)"):format(player.Name))
        return nil
    end

    local teacherUserId = player:GetAttribute("TeacherUserId")
    local classId       = getFirstClassId(player)
    if not teacherUserId or not classId then
        warn(("[Takeover] %s: Start failed (TeacherUserId or TeacherClassIds missing)"):format(
            player.Name))
        return nil
    end

    -- ローカル側の二重起動チェック
    if active_takeovers[npcId] then
        warn(("[Takeover] %s: Start aborted (npc %s already active locally)"):format(
            player.Name, tostring(npcId)))
        return nil
    end

    local ok, response, status = bearerRequest("POST", "/academy-takeover-start", {
        teacher_id = teacherUserId,
        class_id   = classId,
        npc_id     = npcId,
    })

    if not ok then
        warn(("[Takeover] %s: Start API failed (status=%s)"):format(
            player.Name, tostring(status)))
        return nil
    end

    if not response or not response.session_id then
        warn(("[Takeover] %s: Start API returned no session_id"):format(player.Name))
        return nil
    end

    active_takeovers[npcId] = {
        sessionId     = response.session_id,
        teacherUserId = teacherUserId,
        teacherPlayer = player,
        classId       = classId,
        startedAt     = os.time(),
    }

    takeoverStarted:FireClient(player, {
        npc_id     = npcId,
        session_id = response.session_id,
        started_at = response.started_at,
    })

    print(("[TakeoverService] Started session %s for %s (teacher=%s)"):format(
        tostring(response.session_id), tostring(npcId), player.Name))

    return response.session_id
end

------------------------------------------------------------------------
-- TakeoverService:End
------------------------------------------------------------------------
function TakeoverService:End(player, npcId)
    if not player or not npcId then
        warn("[Takeover] End: invalid args")
        return false
    end

    local active = active_takeovers[npcId]
    if not active then
        warn(("[Takeover] %s: End aborted (no active session for %s)"):format(
            player.Name, tostring(npcId)))
        return false
    end

    if active.teacherPlayer ~= player then
        warn(("[Takeover] %s: End denied (not session owner; owner=%s)"):format(
            player.Name, active.teacherPlayer and active.teacherPlayer.Name or "nil"))
        return false
    end

    local ok, response, status = bearerRequest("POST", "/academy-takeover-end", {
        session_id = active.sessionId,
        teacher_id = active.teacherUserId,
    })

    if not ok then
        warn(("[Takeover] %s: End API failed (status=%s)"):format(
            player.Name, tostring(status)))
        -- ステイル状態回避のためローカル状態は破棄
        active_takeovers[npcId] = nil
        return false
    end

    active_takeovers[npcId] = nil

    -- player が既に切断していた場合はクライアント通知をスキップ
    if player.Parent then
        takeoverEnded:FireClient(player, {
            npc_id       = npcId,
            session_id   = active.sessionId,
            ended_at     = response and response.ended_at,
            duration_sec = response and response.duration_sec,
        })
    end

    print(("[TakeoverService] Ended session %s for %s (duration=%ss)"):format(
        tostring(active.sessionId), tostring(npcId),
        tostring(response and response.duration_sec or "?")))

    return true
end

------------------------------------------------------------------------
-- グローバル公開
------------------------------------------------------------------------
_G.TakeoverService = TakeoverService

_G.getActiveTakeover = function(npcId)
    return active_takeovers[npcId]
end

------------------------------------------------------------------------
-- プレイヤー切断時の自動 End
------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    for npcId, active in pairs(active_takeovers) do
        if active.teacherPlayer == player then
            warn(("[TakeoverService] Auto-ending %s due to teacher disconnect"):format(npcId))
            -- 直接 End（Player は既に部分切断状態）
            local ok = bearerRequest("POST", "/academy-takeover-end", {
                session_id = active.sessionId,
                teacher_id = active.teacherUserId,
            })
            active_takeovers[npcId] = nil
            if not ok then
                warn(("[TakeoverService] Auto-end API failed for %s"):format(npcId))
            end
        end
    end
end)

print("[TakeoverService] TakeoverService ready")

return TakeoverService
