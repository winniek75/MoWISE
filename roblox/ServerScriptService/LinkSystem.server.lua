-- LinkSystem.server.lua
-- Phase 0 API連動: 6桁コードによるアカウント連携フロー
-- SyncService を使って link/generate を呼び、クライアントに表示

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SyncService モジュール読み込み
local SyncService = require(script.Parent:WaitForChild("SyncService"))

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes", 30)
if not remotes then
    warn("[LinkSystem] MoWISERemotes not found")
    return
end

-- RemoteEvent / RemoteFunction の作成
local requestLinkCode = Instance.new("RemoteFunction", remotes)
requestLinkCode.Name  = "RequestLinkCode"

local linkStatusChanged = Instance.new("RemoteEvent", remotes)
linkStatusChanged.Name  = "LinkStatusChanged"

local requestUnlink = Instance.new("RemoteEvent", remotes)
requestUnlink.Name  = "RequestUnlink"

-- プレイヤーごとの SyncService インスタンス
local syncServices = {}

------------------------------------------------------------------------
-- プレイヤー参加時：SyncService 初期化 + 連携状態通知
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    local sync = SyncService.new(player)
    syncServices[player.UserId] = sync

    -- DataStore からトークン復元まで少し待つ
    task.wait(2)

    -- 連携済みなら初回 sync-pull + ブースト通知
    if sync:isLinked() then
        linkStatusChanged:FireClient(player, {
            linked = true,
            coin_multiplier = sync:getCoinMultiplier(),
        })
        -- ログイン同期
        task.spawn(function()
            local ok = sync:pullFromWeb()
            if ok then
                print(("[LinkSystem] %s: ログイン同期完了"):format(player.Name))
            end
        end)
    else
        linkStatusChanged:FireClient(player, { linked = false })
    end
end)

------------------------------------------------------------------------
-- プレイヤー退出時：セッションデータ push + クリーンアップ
------------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    local sync = syncServices[player.UserId]
    if sync and sync:isLinked() then
        -- セッション終了同期（簡易版：Phase 1 で本格化）
        pcall(function()
            sync:pushToWeb({
                session = {
                    started_at = "",  -- TODO: セッション開始時刻を記録
                    ended_at   = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                },
            })
        end)
    end
    syncServices[player.UserId] = nil
end)

------------------------------------------------------------------------
-- クライアントからコード発行リクエスト
------------------------------------------------------------------------
requestLinkCode.OnServerInvoke = function(player)
    local sync = syncServices[player.UserId]
    if not sync then
        return { success = false, error = "SyncService not initialized" }
    end

    -- 既に連携済み
    if sync:isLinked() then
        return { success = false, error = "ALREADY_LINKED" }
    end

    local code, ttl = sync:generateLinkCode()
    if code then
        print(("[LinkSystem] %s: 連携コード発行 → %s"):format(player.Name, code))

        -- コード発行後、ポーリングで連携成功を検知（最大5分）
        task.spawn(function()
            local elapsed = 0
            local interval = 5  -- 5秒ごとにチェック
            local maxWait = ttl or 300

            while elapsed < maxWait do
                task.wait(interval)
                elapsed = elapsed + interval

                -- heartbeat で連携状態を確認
                local result = sync:heartbeat({
                    current_zone = 1,
                    current_coins = 0,
                    play_time_seconds = 0,
                })

                if result and result.linked == true then
                    -- Webアプリ側で verify 成功 → トークン保存
                    -- (heartbeat レスポンスに link_token が含まれる想定)
                    if result.link_token then
                        sync:saveLinkToken(result.link_token)
                    end

                    linkStatusChanged:FireClient(player, {
                        linked = true,
                        coin_multiplier = result.coin_multiplier or 1.5,
                        message = "MoWISEと連携しました！",
                    })

                    -- 初回 sync-pull
                    task.spawn(function()
                        sync:pullFromWeb()
                    end)

                    print(("[LinkSystem] %s: 連携成功！"):format(player.Name))
                    return
                end
            end

            -- タイムアウト
            linkStatusChanged:FireClient(player, {
                linked = false,
                expired = true,
                message = "コードの有効期限が切れました",
            })
        end)

        return {
            success = true,
            code    = code,
            ttl     = ttl or 300,
        }
    else
        return { success = false, error = "API_ERROR" }
    end
end

------------------------------------------------------------------------
-- 連携解除
------------------------------------------------------------------------
requestUnlink.OnServerEvent:Connect(function(player)
    local sync = syncServices[player.UserId]
    if sync then
        sync:unlink()
        linkStatusChanged:FireClient(player, { linked = false })
        print(("[LinkSystem] %s: 連携解除"):format(player.Name))
    end
end)

------------------------------------------------------------------------
-- SyncService を他スクリプトから参照可能にする（BindableFunction）
------------------------------------------------------------------------
local getSyncService = Instance.new("BindableFunction", remotes)
getSyncService.Name  = "GetSyncService"

getSyncService.OnInvoke = function(userId)
    return syncServices[userId]
end

print("[LinkSystem] Ready")
