-- FarmingClient.client.lua
-- Phase 5: 畑への種植え・収穫 UI

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local plantSeed     = remotes:WaitForChild("PlantSeed")
local harvestCrop   = remotes:WaitForChild("HarvestCrop")
local cropReady     = remotes:WaitForChild("CropReady")
local cropHarvested = remotes:WaitForChild("CropHarvested")

------------------------------------------------------------------------
-- バナー UI（下部スライドイン通知）
------------------------------------------------------------------------
local farmGui = Instance.new("ScreenGui")
farmGui.Name         = "FarmGui"
farmGui.ResetOnSpawn = false
farmGui.Parent       = player.PlayerGui

local banner = Instance.new("Frame")
banner.Size              = UDim2.new(0, 360, 0, 64)
banner.Position          = UDim2.new(0.5, -180, 1, 10)
banner.BackgroundColor3  = Color3.fromRGB(30, 100, 50)
banner.BackgroundTransparency = 0.1
banner.BorderSizePixel   = 0
banner.Parent            = farmGui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)

local bannerLabel = Instance.new("TextLabel")
bannerLabel.Size              = UDim2.new(1, -10, 1, 0)
bannerLabel.Position          = UDim2.new(0, 10, 0, 0)
bannerLabel.BackgroundTransparency = 1
bannerLabel.TextColor3        = Color3.fromRGB(150, 255, 150)
bannerLabel.Font              = Enum.Font.GothamBold
bannerLabel.TextSize          = 15
bannerLabel.TextXAlignment    = Enum.TextXAlignment.Left
bannerLabel.Parent            = banner

local function showBanner(text, duration)
    bannerLabel.Text = text
    TweenService:Create(banner, TweenInfo.new(0.4),
        { Position = UDim2.new(0.5, -180, 1, -74) }):Play()
    task.delay(duration or 4, function()
        TweenService:Create(banner, TweenInfo.new(0.4),
            { Position = UDim2.new(0.5, -180, 1, 10) }):Play()
    end)
end

-- 収穫可能通知
cropReady.OnClientEvent:Connect(function(plotId)
    showBanner("収穫できるよ！畑に近づいてね", 5)
    -- 収穫 ProximityPrompt を有効化
    for _, desc in pairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt")
            and desc.Parent
            and desc.Parent:GetAttribute("PlotId") == plotId then
            desc.ActionText = "収穫する"
            desc.Enabled = true
        end
    end
end)

-- 収穫完了通知
cropHarvested.OnClientEvent:Connect(function(success, message)
    if success then
        showBanner("収穫！ " .. message, 3)
    else
        showBanner(message, 3)
    end
end)

------------------------------------------------------------------------
-- 畑パーツに ProximityPrompt を動的セットアップ
------------------------------------------------------------------------
local function setupFarmPlot(part)
    if not part:IsA("BasePart") then return end
    if part:GetAttribute("BuildingType") ~= "farm_plot" then return end

    local plotId = part:GetAttribute("PlotId")
    if not plotId then return end

    -- 既存 ProximityPrompt がなければ作成
    if not part:FindFirstChildOfClass("ProximityPrompt") then
        local prompt = Instance.new("ProximityPrompt")
        prompt.ActionText   = "種を植える"
        prompt.ObjectText   = "farm_plot"
        prompt.MaxActivationDistance = 8
        prompt.HoldDuration = 0.5
        prompt.Parent       = part

        prompt.Triggered:Connect(function(triggeringPlayer)
            if triggeringPlayer ~= player then return end
            if prompt.ActionText == "種を植える" then
                plantSeed:FireServer(plotId)
                prompt.ActionText = "育ち中…"
                prompt.Enabled    = false
            elseif prompt.ActionText == "収穫する" then
                harvestCrop:FireServer(plotId)
                prompt.ActionText = "種を植える"
                prompt.Enabled    = true
            end
        end)
    end
end

-- 既存・今後配置される farm_plot を監視
workspace.DescendantAdded:Connect(setupFarmPlot)
for _, desc in pairs(workspace:GetDescendants()) do
    setupFarmPlot(desc)
end
