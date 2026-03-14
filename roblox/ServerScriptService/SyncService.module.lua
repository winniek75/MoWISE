-- SyncService.module.lua
-- WebアプリとのAPI連動：HTTP通信モジュール
-- Phase 0: link/generate, link/verify, heartbeat
-- Phase 1: sync-pull, sync-push, flash-output

local HttpService = game:GetService("HttpService")
local DataStoreService = game:GetService("DataStoreService")

local SyncService = {}
SyncService.__index = SyncService

-- ★ デプロイ時に実際のURLとキーに変更する
local API_BASE = "https://yytxgxlhgotscwztlsqj.supabase.co/functions/v1"
local API_KEY  = "YOUR_ROBLOX_API_KEY"  -- ServerScriptService 内のみで使用

-- DataStore: 連携トークンの永続保存
local linkStore = DataStoreService:GetDataStore("MoWISE_LinkTokens")

------------------------------------------------------------------------
-- コンストラクタ
------------------------------------------------------------------------
function SyncService.new(player)
    local self = setmetatable({}, SyncService)
    self.player       = player
    self.robloxUserId = player.UserId
    self.linkToken    = nil
    self.linked       = false
    self.localCache   = {}
    self.boosts       = { coin_multiplier = 1.0, premium_materials = false }

    -- DataStore から保存済みトークンを読み込み
    task.spawn(function()
        local ok, token = pcall(function()
            return linkStore:GetAsync("link_" .. tostring(player.UserId))
        end)
        if ok and token then
            self.linkToken = token
            self.linked    = true
            print(("[SyncService] %s: 連携済み（トークン復元）"):format(player.Name))
        end
    end)

    return self
end

------------------------------------------------------------------------
-- HTTP リクエスト共通
------------------------------------------------------------------------
function SyncService:makeRequest(method, endpoint, body)
    local url = API_BASE .. endpoint
    local headers = {
        ["Content-Type"]     = "application/json",
        ["X-MoWISE-API-Key"] = API_KEY,
        ["X-Roblox-User-Id"] = tostring(self.robloxUserId),
    }
    if self.linkToken then
        headers["X-MoWISE-Link-Token"] = self.linkToken
    end

    local success, result = pcall(function()
        if method == "GET" then
            return HttpService:GetAsync(url, false, headers)
        else
            return HttpService:PostAsync(
                url,
                HttpService:JSONEncode(body or {}),
                Enum.HttpContentType.ApplicationJson,
                false,
                headers
            )
        end
    end)

    if success then
        local decodeOk, data = pcall(function()
            return HttpService:JSONDecode(result)
        end)
        if decodeOk then
            return true, data
        else
            warn("[SyncService] JSON decode error:", result)
            return false, nil
        end
    else
        warn("[SyncService] API Error:", result)
        return false, nil
    end
end

------------------------------------------------------------------------
-- アカウント連携：コード発行
------------------------------------------------------------------------
function SyncService:generateLinkCode()
    local ok, data = self:makeRequest("POST", "/roblox-link-generate", {
        roblox_user_id    = self.robloxUserId,
        roblox_display_name = self.player.DisplayName,
    })
    if ok and data then
        return data.code, data.ttl_seconds
    end
    return nil, nil
end

------------------------------------------------------------------------
-- アカウント連携：トークン保存（Webアプリ側で verify 成功後に呼ばれる）
------------------------------------------------------------------------
function SyncService:saveLinkToken(token)
    self.linkToken = token
    self.linked    = true

    pcall(function()
        linkStore:SetAsync("link_" .. tostring(self.robloxUserId), token)
    end)

    print(("[SyncService] %s: 連携トークン保存完了"):format(self.player.Name))
end

------------------------------------------------------------------------
-- アカウント連携解除
------------------------------------------------------------------------
function SyncService:unlink()
    self.linkToken = nil
    self.linked    = false
    self.boosts    = { coin_multiplier = 1.0, premium_materials = false }

    pcall(function()
        linkStore:RemoveAsync("link_" .. tostring(self.robloxUserId))
    end)

    print(("[SyncService] %s: 連携解除"):format(self.player.Name))
end

------------------------------------------------------------------------
-- Heartbeat（60秒ごとに呼ぶ）
------------------------------------------------------------------------
function SyncService:heartbeat(currentState)
    if not self.linked then return nil end

    local ok, data = self:makeRequest("POST", "/roblox-heartbeat", {
        roblox_user_id     = self.robloxUserId,
        current_zone       = currentState.current_zone or 1,
        current_coins      = currentState.current_coins or 0,
        play_time_seconds  = currentState.play_time_seconds or 0,
    })

    if ok and data then
        -- ブースト状態更新
        if data.boost_active then
            self.boosts.coin_multiplier    = data.coin_multiplier or 1.0
            self.boosts.premium_materials  = true
        else
            self.boosts.coin_multiplier    = 1.0
            self.boosts.premium_materials  = false
        end
        -- 連携解除検知
        if data.linked == false then
            self:unlink()
        end
        return data
    end
    return nil
end

------------------------------------------------------------------------
-- Sync Pull（ログイン時: Web→Roblox）
------------------------------------------------------------------------
function SyncService:pullFromWeb(fields)
    if not self.linked then return false end

    local query = "?fields=" .. (fields or "patterns,mowi,badges,streaks")
    local ok, data = self:makeRequest("GET", "/roblox-sync-pull" .. query)
    if ok and data then
        self.localCache = data
        -- ブースト状態も更新
        if data.boosts then
            self.boosts.coin_multiplier   = data.boosts.coin_multiplier or 1.0
            self.boosts.premium_materials = data.boosts.premium_materials or false
        end
        print(("[SyncService] %s: sync-pull 完了"):format(self.player.Name))
        return true
    end
    return false
end

------------------------------------------------------------------------
-- Sync Push（セッション終了時: Roblox→Web）
------------------------------------------------------------------------
function SyncService:pushToWeb(sessionData)
    if not self.linked then return false end

    local ok, data = self:makeRequest("POST", "/roblox-sync-push", sessionData)
    if ok then
        print(("[SyncService] %s: sync-push 完了"):format(self.player.Name))
    end
    return ok
end

------------------------------------------------------------------------
-- Flash Output: セッション開始（APIから出題取得）
------------------------------------------------------------------------
function SyncService:flashOutputStart(patternNo, difficulty, questionCount)
    if not self.linked then return nil end

    local ok, data = self:makeRequest("POST", "/roblox-flash-output-start", {
        pattern_no     = patternNo,
        difficulty     = difficulty or 1,
        question_count = questionCount or 5,
    })

    if ok and data then
        return data
    end
    return nil
end

------------------------------------------------------------------------
-- Flash Output: 回答送信
------------------------------------------------------------------------
function SyncService:flashOutputAnswer(sessionId, questionId, answerTiles, responseTimeMs, combo)
    if not self.linked then return nil end

    local ok, data = self:makeRequest("POST", "/roblox-flash-output-answer", {
        session_id      = sessionId,
        question_id     = questionId,
        answer_tiles    = answerTiles,
        response_time_ms = responseTimeMs,
        current_combo   = combo or 0,
    })

    if ok and data then
        return data
    end
    return nil
end

------------------------------------------------------------------------
-- ユーティリティ
------------------------------------------------------------------------
function SyncService:isLinked()
    return self.linked
end

function SyncService:getCoinMultiplier()
    return self.boosts.coin_multiplier
end

function SyncService:getLocalCache()
    return self.localCache
end

return SyncService
