-- TakeoverClientUI.client.lua
-- C-3.1 Phase 3 / 先生用通知 GUI（最小限）
--
-- 責務：
--   1. takeover_started / takeover_ended RemoteEvent を購読
--   2. 画面右下に小さな通知 ScreenGui を 5 秒表示
--   3. TeacherTakeoverPrompt（Custom スタイル）の表示制御
--      - LocalPlayer:GetAttribute("IsTeacher") == true のみ簡易 UI を描画
--      - 入力 UI は Default の挙動（E キー or 同等ボタン）に任せ、表示判定のみ行う

local Players              = game:GetService("Players")
local ReplicatedStorage    = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService     = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

local remotes        = ReplicatedStorage:WaitForChild("MoWISERemotes")
local takeoverStarted = remotes:WaitForChild("takeover_started")
local takeoverEnded   = remotes:WaitForChild("takeover_ended")

------------------------------------------------------------------------
-- 通知 ScreenGui
------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name        = "TakeoverNotificationGui"
screenGui.ResetOnSpawn = false
screenGui.Parent      = playerGui

local function showNotification(text, ttl)
    local frame = Instance.new("Frame")
    frame.Size                  = UDim2.new(0, 320, 0, 50)
    frame.AnchorPoint           = Vector2.new(1, 1)
    frame.Position              = UDim2.new(1, -20, 1, -100)
    frame.BackgroundColor3      = Color3.fromRGB(28, 32, 48)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel       = 0
    frame.Parent                = screenGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, -20, 1, 0)
    label.Position               = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text                   = text
    label.TextColor3             = Color3.fromRGB(255, 255, 255)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 16
    label.TextXAlignment         = Enum.TextXAlignment.Left
    label.TextYAlignment         = Enum.TextYAlignment.Center
    label.Parent                 = frame

    task.delay(ttl or 5, function()
        if frame.Parent then frame:Destroy() end
    end)
end

local function npcLabel(npcId)
    if npcId == "maria" then return "Maria" end
    if npcId == "sam"   then return "Sam"   end
    if npcId == "lily"  then return "Lily"  end
    return tostring(npcId)
end

------------------------------------------------------------------------
-- RemoteEvent 購読
------------------------------------------------------------------------
takeoverStarted.OnClientEvent:Connect(function(payload)
    showNotification(("✅ %s を引き継ぎ中"):format(npcLabel(payload.npc_id)), 5)
end)

takeoverEnded.OnClientEvent:Connect(function(payload)
    showNotification(("✅ %s の引き継ぎを終了"):format(npcLabel(payload.npc_id)), 5)
end)

------------------------------------------------------------------------
-- TeacherTakeoverPrompt 表示制御（先生のみ）
-- Custom スタイルの ProximityPrompt は標準 UI を出さないため、
-- 先生に対しては最小 BillboardGui を Prompt 親 Part に表示する。
------------------------------------------------------------------------
local function isTeacher()
    return localPlayer:GetAttribute("IsTeacher") == true
end

local activeBillboards = {}  -- [Prompt] = BillboardGui

ProximityPromptService.PromptShown:Connect(function(prompt)
    if prompt.Name ~= "TeacherTakeoverPrompt" then return end
    if not isTeacher() then return end

    local parentPart = prompt.Parent
    if not parentPart or not parentPart:IsA("BasePart") then return end

    if activeBillboards[prompt] then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Size         = UDim2.new(0, 180, 0, 40)
    billboard.StudsOffset  = Vector3.new(0, 5.5, 0)
    billboard.AlwaysOnTop  = true
    billboard.Parent       = parentPart

    local label = Instance.new("TextLabel")
    label.Size                   = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3       = Color3.fromRGB(28, 32, 48)
    label.BackgroundTransparency = 0.15
    label.TextColor3             = Color3.fromRGB(255, 220, 80)
    label.Font                   = Enum.Font.GothamBold
    label.TextSize               = 14
    label.Text                   = ("[E] %s"):format(prompt.ActionText)
    label.Parent                 = billboard
    Instance.new("UICorner", label).CornerRadius = UDim.new(0, 6)

    activeBillboards[prompt] = billboard
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
    if prompt.Name ~= "TeacherTakeoverPrompt" then return end
    local b = activeBillboards[prompt]
    if b then
        b:Destroy()
        activeBillboards[prompt] = nil
    end
end)

print("[TakeoverClientUI] Ready (IsTeacher=" .. tostring(isTeacher()) .. ")")
