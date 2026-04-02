-- PlayerJoinHandler.server.lua
-- ログイン時の初期化 + sync-pull（Web→Roblox データ同期）

local Players       = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local SyncService   = require(script.Parent.SyncService)

local linkStore = DataStoreService:GetDataStore("MoWISE_LinkTokens")

-- サーバー変数：プレイヤー別 sync インスタンスとパターン更新蓄積
local activeSyncs          = {}
local playerPatternUpdates = {}

-- 他スクリプトから参照できるように BindableEvent で公開
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes", 10)
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name   = "MoWISERemotes"
    remotes.Parent = ReplicatedStorage
end

-- activeSyncs を取得するための BindableFunction
local getSyncBF = Instance.new("BindableFunction", remotes)
getSyncBF.Name  = "GetPlayerSync"
getSyncBF.OnInvoke = function(userId)
    return activeSyncs[userId]
end

-- patternUpdates を蓄積するための BindableEvent
local addPatternUpdateBE = Instance.new("BindableEvent", remotes)
addPatternUpdateBE.Name  = "AddPatternUpdate"
addPatternUpdateBE.Event:Connect(function(userId, updateData)
    if not playerPatternUpdates[userId] then
        playerPatternUpdates[userId] = {}
    end
    table.insert(playerPatternUpdates[userId], updateData)
end)

------------------------------------------------------------------------
-- PlayerAdded
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    local sync = SyncService.new(player)

    -- DataStore からリンクトークンを取得
    local ok, token = pcall(function()
        return linkStore:GetAsync("link_" .. tostring(player.UserId))
    end)
    if ok and token then
        sync.linkToken = token
        sync.linked    = true
        print(string.format("[Join] %s: 連携済み（%s...）", player.Name, tostring(token):sub(1, 8)))
    else
        print(string.format("[Join] %s: 未連携（Roblox単体モード）", player.Name))
    end

    -- セッション開始時刻を記録
    player:SetAttribute("SessionStartedAt", os.time())
    player:SetAttribute("SessionFlashTotal", 0)
    player:SetAttribute("SessionFlashCorrect", 0)
    player:SetAttribute("SessionMaxCombo", 0)
    player:SetAttribute("SessionCoinsEarned", 0)
    player:SetAttribute("SessionCoinsSpent", 0)
    player:SetAttribute("SessionHappinessDelta", 0)
    player:SetAttribute("SessionXPEarned", 0)
    player:SetAttribute("Zone1Buildings", 0)
    player:SetAttribute("Zone2Buildings", 0)
    player:SetAttribute("TotalNPCFriendship", 0)

    -- sync-pull（連携済みの場合のみ）
    if sync.linked then
        task.spawn(function()
            local pulled, data = sync:pullFromWeb()
            if pulled and data then
                -- パターン★をPlayer Attribute に保存（Zone解放判定に使う）
                for _, p in ipairs(data.patterns or {}) do
                    player:SetAttribute("Star_" .. p.pattern_no, p.mastery_level)
                end
                -- ブースト設定
                local mult = (data.boosts and data.boosts.coin_multiplier) or 1.0
                player:SetAttribute("CoinMultiplier", mult)
                print(string.format("[Join] %s: sync-pull 完了 (×%.1f ブースト)", player.Name, mult))
            end
        end)
    end

    player:SetAttribute("LinkedSync", sync.linked)
    activeSyncs[player.UserId] = sync
    playerPatternUpdates[player.UserId] = {}
end)

------------------------------------------------------------------------
-- PlayerRemoving — セッション終了時 sync-push
------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    local sync = activeSyncs[player.UserId]
    if not sync or not sync.linked then
        activeSyncs[player.UserId] = nil
        playerPatternUpdates[player.UserId] = nil
        return
    end

    local startedAt = player:GetAttribute("SessionStartedAt") or os.time()
    local now       = os.time()

    -- セッションデータを組み立てる
    local sessionData = {
        session = {
            started_at         = os.date("!%Y-%m-%dT%H:%M:%SZ", startedAt),
            ended_at           = os.date("!%Y-%m-%dT%H:%M:%SZ", now),
            duration_seconds   = now - startedAt,
            total_flash_output = player:GetAttribute("SessionFlashTotal")   or 0,
            correct_count      = player:GetAttribute("SessionFlashCorrect") or 0,
            max_combo          = player:GetAttribute("SessionMaxCombo")     or 0,
            word_coins_earned  = player:GetAttribute("SessionCoinsEarned")  or 0,
            word_coins_spent   = player:GetAttribute("SessionCoinsSpent")   or 0,
            buildings_built        = {},
            npc_missions_completed = {},
        },
        pattern_updates = playerPatternUpdates[player.UserId] or {},
        mowi_update = {
            happiness_delta = player:GetAttribute("SessionHappinessDelta") or 0,
            xp_earned       = player:GetAttribute("SessionXPEarned")       or 0,
        },
        town_state = {
            zone1_buildings      = player:GetAttribute("Zone1Buildings")    or 0,
            zone2_buildings      = player:GetAttribute("Zone2Buildings")    or 0,
            total_npc_friendship = player:GetAttribute("TotalNPCFriendship") or 0,
        }
    }

    local ok, resp = sync:pushToWeb(sessionData)
    if ok then
        print(string.format("[Leave] %s: sync-push 完了", player.Name))
    end

    -- クリーンアップ
    activeSyncs[player.UserId] = nil
    playerPatternUpdates[player.UserId] = nil
end)

print("[PlayerJoinHandler] 初期化完了")
