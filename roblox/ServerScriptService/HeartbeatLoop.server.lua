-- HeartbeatLoop.server.lua
-- 60秒ごとに heartbeat API を叩いてブースト状態・先生メッセージを取得

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes", 30)
if not remotes then
    warn("[HeartbeatLoop] MoWISERemotes not found")
    return
end

local HEARTBEAT_INTERVAL = 60  -- 秒

-- LinkSystem が作る SyncService 参照用
local getSyncService = nil
task.spawn(function()
    getSyncService = remotes:WaitForChild("GetSyncService", 30)
end)

-- ブースト状態をクライアントに通知する RemoteEvent
local boostUpdate = Instance.new("RemoteEvent", remotes)
boostUpdate.Name  = "BoostUpdate"

-- 先生メッセージ通知用
local teacherMessage = Instance.new("RemoteEvent", remotes)
teacherMessage.Name  = "TeacherMessage"

------------------------------------------------------------------------
-- プレイヤーごとのHeartbeatループ
------------------------------------------------------------------------
local function startHeartbeat(player)
    -- LinkSystem がSyncServiceを作るまで待つ
    task.wait(5)

    local playStartTime = os.time()

    while player.Parent do  -- プレイヤーが残っている間
        task.wait(HEARTBEAT_INTERVAL)

        if not getSyncService then continue end

        -- BindableFunction 経由で SyncService を取得
        local ok, sync = pcall(function()
            return getSyncService:Invoke(player.UserId)
        end)

        if not ok or not sync or not sync.isLinked or not sync:isLinked() then
            continue
        end

        -- 現在のプレイヤー状態を収集
        local currentState = {
            current_zone      = 1,  -- TODO: 実際のゾーン位置から取得
            current_coins     = 0,  -- TODO: MaterialSystem から取得
            play_time_seconds = os.time() - playStartTime,
        }

        -- Heartbeat 実行
        local result = sync:heartbeat(currentState)

        if result then
            -- ブースト状態をクライアントに通知
            boostUpdate:FireClient(player, {
                boost_active    = result.boost_active or false,
                coin_multiplier = result.coin_multiplier or 1.0,
            })

            -- 先生メッセージがあれば通知
            if result.teacher_message then
                teacherMessage:FireClient(player, result.teacher_message)
            end

            -- 日替わりログインボーナス
            if result.daily_login_bonus_available then
                -- TODO: ログインボーナス付与処理
            end
        end
    end
end

------------------------------------------------------------------------
-- プレイヤー参加時にHeartbeatループ起動
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    task.spawn(startHeartbeat, player)
end)

print("[HeartbeatLoop] Ready")
