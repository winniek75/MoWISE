-- ClearanceSystem.server.lua
-- Phase 0: 正解後に遺跡パーツを壊して整地する

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local clearRuins = Instance.new("RemoteEvent", remotes)
clearRuins.Name  = "ClearRuins"
local enableClearance = Instance.new("BindableEvent", remotes)
enableClearance.Name  = "EnableClearance"
local giveMaterial = remotes:WaitForChild("GiveMaterial") -- BindableEvent
local mowiReaction = nil
task.spawn(function()
    mowiReaction = remotes:WaitForChild("MowiReaction", 30)
end)

-- 既にプロンプトを付与済みかどうか（プレイヤーごと）
local enabledPlayers = {}

-- 遺跡パーツに ProximityPrompt を追加
local function addPromptToRuins(player)
    local folder = workspace:FindFirstChild("RuinsFolder")
    if not folder then return end

    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") and not part:FindFirstChild("ClearPrompt") then
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name        = "ClearPrompt"
            prompt.ActionText  = "整地する"
            prompt.ObjectText  = "遺跡"
            prompt.MaxActivationDistance = 8
            prompt.Parent      = part

            prompt.Triggered:Connect(function(triggeringPlayer)
                -- 遺跡を壊すアニメーション
                local tween = TweenService:Create(
                    part,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    { Size = Vector3.new(0.1, 0.1, 0.1), CFrame = part.CFrame + Vector3.new(0, -3, 0) }
                )
                tween:Play()
                tween.Completed:Connect(function()
                    part:Destroy()
                    -- 石材を付与
                    giveMaterial:Fire(triggeringPlayer, "Stone", 2)
                    -- Mowi: 整地リアクション
                    if mowiReaction then
                        mowiReaction:Fire(triggeringPlayer, "clearance")
                    end
                    print("[MoWISE] " .. triggeringPlayer.Name .. " cleared ruins → Stone +2")
                end)
                prompt:Destroy()
            end)
        end
    end
end

-- FlashOutputServer が正解時に EnableClearance を発火 → サーバーで受けて整地解禁
enableClearance.Event:Connect(function(player)
    if enabledPlayers[player.UserId] then return end
    enabledPlayers[player.UserId] = true
    addPromptToRuins(player)
    print("[MoWISE] Clearance enabled for " .. player.Name)
end)
