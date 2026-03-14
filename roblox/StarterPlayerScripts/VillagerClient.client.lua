-- VillagerClient.client.lua
-- Phase 3: 町民移住 - Mowi通知・会話ミッションUI

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local villagerApproach = remotes:WaitForChild("VillagerApproach")
local startDialogue    = remotes:WaitForChild("StartDialogue")
local dialogueAnswer   = remotes:WaitForChild("DialogueAnswer")
local dialogueResult   = remotes:WaitForChild("DialogueResult")
local villagerMoved    = remotes:WaitForChild("VillagerMoved")

------------------------------------------------------------------------
-- Mowi 通知バー
------------------------------------------------------------------------
local notifGui = Instance.new("ScreenGui")
notifGui.Name         = "VillagerNotifGui"
notifGui.ResetOnSpawn = false
notifGui.Parent       = player.PlayerGui

local notifFrame = Instance.new("Frame")
notifFrame.Name               = "NotifFrame"
notifFrame.Size               = UDim2.new(0, 360, 0, 60)
notifFrame.Position           = UDim2.new(0.5, -180, 0, -70)
notifFrame.BackgroundColor3   = Color3.fromRGB(60, 20, 100)
notifFrame.BackgroundTransparency = 0.2
notifFrame.BorderSizePixel    = 0
notifFrame.Parent             = notifGui
Instance.new("UICorner", notifFrame).CornerRadius = UDim.new(0, 10)

local notifLabel = Instance.new("TextLabel")
notifLabel.Size              = UDim2.new(1, -16, 1, 0)
notifLabel.Position          = UDim2.new(0, 8, 0, 0)
notifLabel.BackgroundTransparency = 1
notifLabel.TextColor3        = Color3.fromRGB(255, 220, 255)
notifLabel.Font              = Enum.Font.GothamBold
notifLabel.TextSize          = 14
notifLabel.TextXAlignment    = Enum.TextXAlignment.Left
notifLabel.TextWrapped       = true
notifLabel.Parent            = notifFrame

local function showNotif(msg)
    notifLabel.Text = msg
    TweenService:Create(notifFrame, TweenInfo.new(0.4), {
        Position = UDim2.new(0.5, -180, 0, 12)
    }):Play()
    task.delay(3.5, function()
        TweenService:Create(notifFrame, TweenInfo.new(0.4), {
            Position = UDim2.new(0.5, -180, 0, -70)
        }):Play()
    end)
end

villagerApproach.OnClientEvent:Connect(function(name, role)
    showNotif("Mowi: \"だれかが近づいてきてる…\"\n" .. role .. " " .. name .. " が来るよ！")
end)

------------------------------------------------------------------------
-- 会話ミッションUI
------------------------------------------------------------------------
local dialogGui = Instance.new("ScreenGui")
dialogGui.Name         = "DialogueGui"
dialogGui.Enabled      = false
dialogGui.ResetOnSpawn = false
dialogGui.Parent       = player.PlayerGui

-- 下半分パネル
local panel = Instance.new("Frame")
panel.Size               = UDim2.new(1, 0, 0.44, 0)
panel.Position           = UDim2.new(0, 0, 0.56, 0)
panel.BackgroundColor3   = Color3.fromRGB(15, 20, 35)
panel.BackgroundTransparency = 0.05
panel.BorderSizePixel    = 0
panel.Parent             = dialogGui

-- NPCセリフ（吹き出し風）
local speechBubble = Instance.new("Frame")
speechBubble.Size              = UDim2.new(0.9, 0, 0, 72)
speechBubble.Position          = UDim2.new(0.05, 0, 0, 10)
speechBubble.BackgroundColor3  = Color3.fromRGB(255, 255, 255)
speechBubble.BackgroundTransparency = 0.05
speechBubble.BorderSizePixel   = 0
speechBubble.Parent            = panel
Instance.new("UICorner", speechBubble).CornerRadius = UDim.new(0, 10)

local npcNameLabel = Instance.new("TextLabel")
npcNameLabel.Size              = UDim2.new(0.35, 0, 0, 22)
npcNameLabel.Position          = UDim2.new(0, 8, 0, 4)
npcNameLabel.BackgroundColor3  = Color3.fromRGB(100, 50, 180)
npcNameLabel.BackgroundTransparency = 0
npcNameLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
npcNameLabel.Font              = Enum.Font.GothamBold
npcNameLabel.TextSize          = 12
npcNameLabel.BorderSizePixel   = 0
npcNameLabel.Parent            = speechBubble
Instance.new("UICorner", npcNameLabel).CornerRadius = UDim.new(0, 4)

local npcSpeechLabel = Instance.new("TextLabel")
npcSpeechLabel.Size              = UDim2.new(1, -16, 0, 44)
npcSpeechLabel.Position          = UDim2.new(0, 8, 0, 26)
npcSpeechLabel.BackgroundTransparency = 1
npcSpeechLabel.TextColor3        = Color3.fromRGB(30, 30, 30)
npcSpeechLabel.Font              = Enum.Font.GothamBold
npcSpeechLabel.TextSize          = 14
npcSpeechLabel.TextXAlignment    = Enum.TextXAlignment.Left
npcSpeechLabel.TextWrapped       = true
npcSpeechLabel.Parent            = speechBubble

-- 進行バー
local progressLabel = Instance.new("TextLabel")
progressLabel.Size              = UDim2.new(0.2, 0, 0, 22)
progressLabel.Position          = UDim2.new(0.75, 0, 0, 14)
progressLabel.BackgroundTransparency = 1
progressLabel.TextColor3        = Color3.fromRGB(160, 160, 200)
progressLabel.Font              = Enum.Font.Gotham
progressLabel.TextSize          = 12
progressLabel.Parent            = panel

-- ヒントラベル
local hintLabel = Instance.new("TextLabel")
hintLabel.Size              = UDim2.new(0.9, 0, 0, 20)
hintLabel.Position          = UDim2.new(0.05, 0, 0, 88)
hintLabel.BackgroundTransparency = 1
hintLabel.TextColor3        = Color3.fromRGB(200, 160, 255)
hintLabel.Font              = Enum.Font.Gotham
hintLabel.TextSize          = 12
hintLabel.TextXAlignment    = Enum.TextXAlignment.Left
hintLabel.Parent            = panel

-- 選択肢ボタンエリア（4択）
local optionsFrame = Instance.new("Frame")
optionsFrame.Size              = UDim2.new(0.9, 0, 0.55, 0)
optionsFrame.Position          = UDim2.new(0.05, 0, 0.38, 0)
optionsFrame.BackgroundTransparency = 1
optionsFrame.Parent            = panel

local optionLayout = Instance.new("UIListLayout", optionsFrame)
optionLayout.Padding   = UDim.new(0, 6)
optionLayout.SortOrder = Enum.SortOrder.LayoutOrder

local optionButtons = {}
for i = 1, 4 do
    local btn = Instance.new("TextButton")
    btn.Name             = "Option_" .. i
    btn.Size             = UDim2.new(1, 0, 0, 36)
    btn.LayoutOrder      = i
    btn.BackgroundColor3 = Color3.fromRGB(30, 45, 75)
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.Font             = Enum.Font.Gotham
    btn.TextSize         = 13
    btn.TextWrapped      = true
    btn.TextXAlignment   = Enum.TextXAlignment.Left
    btn.BorderSizePixel  = 0
    btn.Parent           = optionsFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIPadding", btn).PaddingLeft = UDim.new(0, 10)

    table.insert(optionButtons, btn)

    btn.MouseButton1Click:Connect(function()
        if not btn.Active then return end
        dialogueAnswer:FireServer(i)
        for _, b in ipairs(optionButtons) do
            b.Active = false
        end
    end)
end

------------------------------------------------------------------------
-- 会話ミッション表示
------------------------------------------------------------------------
startDialogue.OnClientEvent:Connect(function(data)
    dialogGui.Enabled   = true
    npcNameLabel.Text   = data.npcName .. "  " .. data.npcRole
    npcSpeechLabel.Text = data.npc
    hintLabel.Text      = "Hint: " .. (data.hint or "")
    progressLabel.Text  = data.turn .. " / " .. data.total

    for i, btn in ipairs(optionButtons) do
        local opt = data.options[i]
        btn.Text             = opt and (string.char(64 + i) .. ") " .. opt.text) or ""
        btn.Visible          = opt ~= nil
        btn.Active           = true
        btn.BackgroundColor3 = Color3.fromRGB(30, 45, 75)
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    end
end)

------------------------------------------------------------------------
-- 正誤フィードバック
------------------------------------------------------------------------
dialogueResult.OnClientEvent:Connect(function(correct, options, turnNum, isLast)
    -- 正解・不正解の色表示
    for i, btn in ipairs(optionButtons) do
        local opt = options[i]
        if opt then
            if opt.correct then
                btn.BackgroundColor3 = Color3.fromRGB(40, 140, 70)
            else
                btn.BackgroundColor3 = Color3.fromRGB(100, 40, 40)
            end
        end
    end

    if isLast then
        task.wait(0.5)
        dialogGui.Enabled = false
    end
end)

------------------------------------------------------------------------
-- 移住確定 / 失敗演出
------------------------------------------------------------------------
villagerMoved.OnClientEvent:Connect(function(name, role, correctCount)
    if correctCount >= 2 then
        showNotif(role .. " " .. name .. " が移住してきた！\n正解 " .. correctCount .. "/3")
    else
        showNotif(name .. ": \"また今度…\"\n（もう一度話しかけよう）")
    end
end)
