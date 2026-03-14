-- LinkClient.client.lua
-- アカウント連携画面のクライアント制御
-- 6桁コード表示 + カウントダウン + 連携成功通知

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local gui     = player.PlayerGui:WaitForChild("LinkGui")
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local requestLinkCode   = remotes:WaitForChild("RequestLinkCode")
local linkStatusChanged = remotes:WaitForChild("LinkStatusChanged")
local requestUnlink     = remotes:WaitForChild("RequestUnlink")

local mainFrame     = gui:WaitForChild("MainFrame")
local titleLabel    = mainFrame:WaitForChild("TitleLabel")
local descLabel     = mainFrame:WaitForChild("DescLabel")
local codeFrame     = mainFrame:WaitForChild("CodeFrame")
local codeLabel     = codeFrame:WaitForChild("CodeLabel")
local timerLabel    = codeFrame:WaitForChild("TimerLabel")
local stepsLabel    = mainFrame:WaitForChild("StepsLabel")
local reissueButton = mainFrame:WaitForChild("ReissueButton")
local closeButton   = mainFrame:WaitForChild("CloseButton")
local statusLabel   = mainFrame:WaitForChild("StatusLabel")

local isLinked    = false
local countdownId = 0  -- カウントダウン識別用

------------------------------------------------------------------------
-- メニュー ProximityPrompt から開く（WorldSetup で生成）
------------------------------------------------------------------------
gui.Enabled = false

------------------------------------------------------------------------
-- カウントダウン表示
------------------------------------------------------------------------
local function startCountdown(ttl)
    countdownId = countdownId + 1
    local myId  = countdownId
    local remaining = ttl

    task.spawn(function()
        while remaining > 0 and myId == countdownId do
            local min = math.floor(remaining / 60)
            local sec = remaining % 60
            timerLabel.Text = ("残り %d:%02d"):format(min, sec)
            task.wait(1)
            remaining = remaining - 1
        end
        if myId == countdownId then
            timerLabel.Text = "期限切れ"
            timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        end
    end)
end

------------------------------------------------------------------------
-- コード発行リクエスト
------------------------------------------------------------------------
local function requestCode()
    statusLabel.Text = "コード発行中..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    codeLabel.Text = "------"
    timerLabel.Text = ""
    reissueButton.Active = false

    local result = requestLinkCode:InvokeServer()

    if result and result.success then
        -- コードを1文字ずつスペース区切りで表示
        local spaced = table.concat(string.split(result.code, ""), " ")
        codeLabel.Text = spaced
        codeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        statusLabel.Text = ""
        startCountdown(result.ttl)

        -- コード表示アニメーション
        codeFrame.BackgroundTransparency = 1
        TweenService:Create(
            codeFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 0.2 }
        ):Play()
    elseif result and result.error == "ALREADY_LINKED" then
        statusLabel.Text = "既に連携済みです"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
    else
        statusLabel.Text = "エラーが発生しました。もう一度お試しください。"
        statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    end

    reissueButton.Active = true
end

------------------------------------------------------------------------
-- ボタン接続
------------------------------------------------------------------------
reissueButton.MouseButton1Click:Connect(function()
    if not reissueButton.Active then return end
    requestCode()
end)

closeButton.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

------------------------------------------------------------------------
-- 連携状態変更通知
------------------------------------------------------------------------
linkStatusChanged.OnClientEvent:Connect(function(data)
    if data.linked then
        isLinked = true
        -- 連携成功演出
        statusLabel.Text = data.message or "MoWISEと連携しました！"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
        codeLabel.Text = "✓ 連携済み"
        codeLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
        timerLabel.Text = ""
        countdownId = countdownId + 1  -- カウントダウン停止

        -- 成功フラッシュ
        local flashFrame = Instance.new("Frame")
        flashFrame.Size = UDim2.new(1, 0, 1, 0)
        flashFrame.BackgroundColor3 = Color3.fromRGB(100, 255, 120)
        flashFrame.BackgroundTransparency = 0.5
        flashFrame.ZIndex = 50
        flashFrame.Parent = mainFrame
        TweenService:Create(
            flashFrame,
            TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { BackgroundTransparency = 1 }
        ):Play()
        task.delay(0.7, function()
            flashFrame:Destroy()
        end)

        -- ブースト表示
        if data.coin_multiplier and data.coin_multiplier > 1 then
            descLabel.Text = ("Word Coins ×%.1f ブースト有効！"):format(data.coin_multiplier)
        end

        -- 3秒後に自動で閉じる
        task.delay(3, function()
            if gui.Enabled then
                gui.Enabled = false
            end
        end)
    else
        isLinked = false
        if data.expired then
            statusLabel.Text = data.message or "コードの有効期限が切れました"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        end
    end
end)

------------------------------------------------------------------------
-- 連携メニューを開くためのイベント（ProximityPrompt から）
------------------------------------------------------------------------
local openLinkMenu = remotes:WaitForChild("OpenLinkMenu", 10)
if openLinkMenu then
    openLinkMenu.OnClientEvent:Connect(function()
        gui.Enabled = true
        if not isLinked then
            requestCode()
        else
            statusLabel.Text = "連携済みです"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
            codeLabel.Text = "✓ 連携済み"
            codeLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
            timerLabel.Text = ""
        end
    end)
end
