-- PatternStarClient.client.lua
-- Phase 4: パターン★UP演出 + レシピ解禁通知

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local patternStarUp  = remotes:WaitForChild("PatternStarUp")
local recipeUnlocked = remotes:WaitForChild("RecipeUnlocked")

------------------------------------------------------------------------
-- ★UP バナー（画面中央上部）
------------------------------------------------------------------------
local starGui = Instance.new("ScreenGui")
starGui.Name         = "PatternStarGui"
starGui.ResetOnSpawn = false
starGui.Parent       = player.PlayerGui

local starBanner = Instance.new("Frame")
starBanner.Size              = UDim2.new(0, 420, 0, 80)
starBanner.Position          = UDim2.new(0.5, -210, 0, -100)
starBanner.BackgroundColor3  = Color3.fromRGB(40, 20, 80)
starBanner.BackgroundTransparency = 0.1
starBanner.BorderSizePixel   = 0
starBanner.Parent            = starGui
Instance.new("UICorner", starBanner).CornerRadius = UDim.new(0, 12)

local starLabel = Instance.new("TextLabel")
starLabel.Size              = UDim2.new(1, -20, 0.6, 0)
starLabel.Position          = UDim2.new(0, 10, 0, 6)
starLabel.BackgroundTransparency = 1
starLabel.TextColor3        = Color3.fromRGB(255, 220, 80)
starLabel.Font              = Enum.Font.GothamBold
starLabel.TextSize          = 20
starLabel.TextXAlignment    = Enum.TextXAlignment.Left
starLabel.Parent            = starBanner

local starSubLabel = Instance.new("TextLabel")
starSubLabel.Size              = UDim2.new(1, -20, 0.38, 0)
starSubLabel.Position          = UDim2.new(0, 10, 0.6, 0)
starSubLabel.BackgroundTransparency = 1
starSubLabel.TextColor3        = Color3.fromRGB(200, 180, 255)
starSubLabel.Font              = Enum.Font.Gotham
starSubLabel.TextSize          = 13
starSubLabel.TextXAlignment    = Enum.TextXAlignment.Left
starSubLabel.Parent            = starBanner

local function showStarBanner(patternId, stars, patternName)
    local starStr = string.rep("★", stars) .. string.rep("☆", 5 - stars)
    starLabel.Text    = patternName .. "  " .. starStr
    starSubLabel.Text = patternId .. " が ★" .. stars .. " になった！"

    TweenService:Create(starBanner, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, -210, 0, 14) }):Play()

    task.delay(3.5, function()
        TweenService:Create(starBanner, TweenInfo.new(0.3),
            { Position = UDim2.new(0.5, -210, 0, -100) }):Play()
    end)
end

patternStarUp.OnClientEvent:Connect(function(patternId, stars, patternName)
    showStarBanner(patternId, stars, patternName)
end)

------------------------------------------------------------------------
-- レシピ解禁バナー
------------------------------------------------------------------------
local unlockBanner = Instance.new("Frame")
unlockBanner.Size              = UDim2.new(0, 360, 0, 60)
unlockBanner.Position          = UDim2.new(0.5, -180, 1, 10)
unlockBanner.BackgroundColor3  = Color3.fromRGB(20, 80, 40)
unlockBanner.BackgroundTransparency = 0.1
unlockBanner.BorderSizePixel   = 0
unlockBanner.Parent            = starGui
Instance.new("UICorner", unlockBanner).CornerRadius = UDim.new(0, 10)

local unlockLabel = Instance.new("TextLabel")
unlockLabel.Size              = UDim2.new(1, -10, 1, 0)
unlockLabel.Position          = UDim2.new(0, 10, 0, 0)
unlockLabel.BackgroundTransparency = 1
unlockLabel.TextColor3        = Color3.fromRGB(100, 255, 150)
unlockLabel.Font              = Enum.Font.GothamBold
unlockLabel.TextSize          = 15
unlockLabel.TextXAlignment    = Enum.TextXAlignment.Left
unlockLabel.Parent            = unlockBanner

local function showUnlockBanner(recipeId)
    unlockLabel.Text = "新レシピ解禁：" .. recipeId
    TweenService:Create(unlockBanner, TweenInfo.new(0.4),
        { Position = UDim2.new(0.5, -180, 1, -70) }):Play()
    task.delay(4, function()
        TweenService:Create(unlockBanner, TweenInfo.new(0.4),
            { Position = UDim2.new(0.5, -180, 1, 10) }):Play()
    end)
end

recipeUnlocked.OnClientEvent:Connect(function(recipeId)
    showUnlockBanner(recipeId)
end)
