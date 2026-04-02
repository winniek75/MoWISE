-- MowiAnimClient.client.lua
-- Mowi の感情演出をクライアント側でUI表示する（画面フラッシュエフェクト）

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")
local mowiEmotion = remotes:WaitForChild("MowiEmotion")

-- 画面フラッシュ用 Frame
local screenGui = Instance.new("ScreenGui", player.PlayerGui)
screenGui.Name         = "MowiEffectGui"
screenGui.ResetOnSpawn = false

local flash = Instance.new("Frame", screenGui)
flash.Size                    = UDim2.fromScale(1, 1)
flash.BackgroundColor3        = Color3.fromRGB(255, 255, 255)
flash.BackgroundTransparency  = 1
flash.ZIndex                  = 100

-- 感情ごとの UI 演出
mowiEmotion.OnClientEvent:Connect(function(emotion)
    if emotion == "joy" then
        -- 画面白フラッシュ
        flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TweenService:Create(flash, TweenInfo.new(0.1), { BackgroundTransparency = 0.6 }):Play()
        task.delay(0.15, function()
            TweenService:Create(flash, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
        end)

    elseif emotion == "sad" then
        -- 画面薄暗くなる
        flash.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        TweenService:Create(flash, TweenInfo.new(0.2), { BackgroundTransparency = 0.7 }):Play()
        task.delay(0.3, function()
            TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
        end)

    elseif emotion == "grow" then
        -- 虹色フラッシュ（ゴールド）
        flash.BackgroundColor3 = Color3.fromRGB(255, 220, 50)
        TweenService:Create(flash, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
        task.delay(0.25, function()
            TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
        end)
    end
end)
