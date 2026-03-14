-- FlashOutputClient.client.lua
-- Phase 0: Flash Output GUIのクライアント制御
-- Phase 1: インベントリHUD更新 + 正解演出（SE・パーティクル・画面フラッシュ）

local Players    = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local gui    = player.PlayerGui:WaitForChild("FlashOutputGui")
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local showQuestion = remotes:WaitForChild("ShowQuestion")
local answerResult = remotes:WaitForChild("AnswerResult")
local onAnswered   = remotes:WaitForChild("OnAnswered")

local mainFrame    = gui:WaitForChild("MainFrame")
local promptLabel  = mainFrame:WaitForChild("PromptLabel")
local progressLabel = mainFrame:WaitForChild("ProgressLabel")
local tilesFrame   = mainFrame:WaitForChild("TilesFrame")
local selectedFrame = mainFrame:WaitForChild("SelectedFrame")
local submitButton = mainFrame:WaitForChild("SubmitButton")
local feedbackLabel = mainFrame:WaitForChild("FeedbackLabel")

local selectedTiles = {}
local tileButtons   = {}

------------------------------------------------------------------------
-- Phase 1: SE・演出用セットアップ
------------------------------------------------------------------------

-- SE（Roblox アセットIDで指定、無料SE）
local correctSound = Instance.new("Sound")
correctSound.Name     = "CorrectSE"
correctSound.SoundId  = "rbxassetid://9125402735"   -- 短い成功チャイム
correctSound.Volume   = 0.6
correctSound.Parent   = SoundService

local incorrectSound = Instance.new("Sound")
incorrectSound.Name     = "IncorrectSE"
incorrectSound.SoundId  = "rbxassetid://9125401735"  -- 短いブザー音
incorrectSound.Volume   = 0.4
incorrectSound.Parent   = SoundService

local tileClickSound = Instance.new("Sound")
tileClickSound.Name     = "TileClickSE"
tileClickSound.SoundId  = "rbxassetid://876939830"   -- UI クリック音
tileClickSound.Volume   = 0.3
tileClickSound.Parent   = SoundService

-- 画面フラッシュ用オーバーレイ（FlashOutputGuiに追加）
local flashOverlay = Instance.new("Frame")
flashOverlay.Name                    = "FlashOverlay"
flashOverlay.Size                    = UDim2.new(1, 0, 1, 0)
flashOverlay.BackgroundColor3        = Color3.fromRGB(255, 255, 255)
flashOverlay.BackgroundTransparency  = 1
flashOverlay.BorderSizePixel         = 0
flashOverlay.ZIndex                  = 100
flashOverlay.Parent                  = gui

-- 画面フラッシュ演出
local function screenFlash(color, duration)
    flashOverlay.BackgroundColor3 = color
    flashOverlay.BackgroundTransparency = 0.4
    local tween = TweenService:Create(
        flashOverlay,
        TweenInfo.new(duration or 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 1 }
    )
    tween:Play()
end

-- パーティクル演出（キャラクターの頭上にパーティクルを一瞬放出）
local function emitParticles(color)
    local char = player.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end

    -- 既存があれば使い回し、なければ新規作成
    local emitter = head:FindFirstChild("MoWISEParticle")
    if not emitter then
        emitter = Instance.new("ParticleEmitter")
        emitter.Name         = "MoWISEParticle"
        emitter.Rate         = 0        -- 手動Emitのみ
        emitter.Lifetime     = NumberRange.new(0.6, 1.2)
        emitter.Speed        = NumberRange.new(5, 12)
        emitter.SpreadAngle  = Vector2.new(60, 60)
        emitter.RotSpeed     = NumberRange.new(-180, 180)
        emitter.Size         = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0.8),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.7, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.LightEmission = 0.8
        emitter.Parent       = head
    end

    emitter.Color = ColorSequence.new(color)
    emitter:Emit(20)
end

-- MainFrame ポップアニメーション（正解時に少し大きくなって戻る）
local function popFrame()
    local origSize = mainFrame.Size
    local bigSize = UDim2.new(
        origSize.X.Scale * 1.04, origSize.X.Offset,
        origSize.Y.Scale * 1.04, origSize.Y.Offset
    )
    local grow = TweenService:Create(
        mainFrame,
        TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Size = bigSize }
    )
    grow:Play()
    grow.Completed:Connect(function()
        local shrink = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            { Size = origSize }
        )
        shrink:Play()
    end)
end

-- MainFrame シェイク（不正解時に左右に揺れる）
local function shakeFrame()
    local origPos = mainFrame.Position
    local offsets = { 8, -6, 4, -2, 0 }
    for i, px in ipairs(offsets) do
        local tween = TweenService:Create(
            mainFrame,
            TweenInfo.new(0.05),
            { Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + px, origPos.Y.Scale, origPos.Y.Offset) }
        )
        tween:Play()
        tween.Completed:Wait()
    end
end

------------------------------------------------------------------------
-- タイルボタン生成
------------------------------------------------------------------------
local function buildTiles(tiles)
    for _, b in ipairs(tileButtons) do b:Destroy() end
    tileButtons = {}
    selectedTiles = {}
    -- UIListLayout を再追加するために ClearAllChildren
    selectedFrame:ClearAllChildren()
    -- UIListLayout を再生成
    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection     = Enum.FillDirection.Horizontal
    listLayout.Padding           = UDim.new(0, 4)
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder         = Enum.SortOrder.LayoutOrder
    listLayout.Parent            = selectedFrame

    for i, tileText in ipairs(tiles) do
        local btn = Instance.new("TextButton")
        btn.Name   = "Tile_" .. i
        btn.Text   = tileText
        btn.Size   = UDim2.new(0, 90, 0, 44)
        btn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font   = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Parent = tilesFrame
        table.insert(tileButtons, btn)

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent       = btn

        btn.MouseButton1Click:Connect(function()
            if not btn.Active then return end
            btn.Active = false
            tileClickSound:Play()

            -- 選択アニメーション
            TweenService:Create(
                btn,
                TweenInfo.new(0.15, Enum.EasingStyle.Quad),
                { BackgroundColor3 = Color3.fromRGB(40, 40, 40), Size = UDim2.new(0, 85, 0, 40) }
            ):Play()

            table.insert(selectedTiles, tileText)

            local sel = Instance.new("TextLabel")
            sel.Text  = tileText
            sel.Size  = UDim2.new(0, 80, 1, 0)
            sel.BackgroundColor3 = Color3.fromRGB(80, 140, 80)
            sel.TextColor3 = Color3.fromRGB(255,255,255)
            sel.Font  = Enum.Font.GothamBold
            sel.TextSize = 15
            sel.Parent = selectedFrame

            local selCorner = Instance.new("UICorner")
            selCorner.CornerRadius = UDim.new(0, 4)
            selCorner.Parent       = sel
        end)
    end
end

------------------------------------------------------------------------
-- 問題表示
------------------------------------------------------------------------
showQuestion.OnClientEvent:Connect(function(questionData, idx, total)
    if questionData == nil then
        gui.Enabled = false
        return
    end

    gui.Enabled = true
    feedbackLabel.Text = ""
    feedbackLabel.TextColor3 = Color3.fromRGB(255,255,255)
    promptLabel.Text   = questionData.prompt
    progressLabel.Text = idx .. " / " .. total
    buildTiles(questionData.tiles)
    submitButton.Active = true
    submitButton.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
end)

------------------------------------------------------------------------
-- 回答送信
------------------------------------------------------------------------
submitButton.MouseButton1Click:Connect(function()
    if #selectedTiles == 0 then return end
    submitButton.Active = false
    TweenService:Create(
        submitButton,
        TweenInfo.new(0.1),
        { BackgroundColor3 = Color3.fromRGB(40, 80, 140) }
    ):Play()
    onAnswered:FireServer(selectedTiles)
end)

------------------------------------------------------------------------
-- 正誤フィードバック（Phase 1: 演出強化）
------------------------------------------------------------------------
answerResult.OnClientEvent:Connect(function(isCorrect, correctAnswer)
    if isCorrect then
        feedbackLabel.Text = "正解！"
        feedbackLabel.TextColor3 = Color3.fromRGB(100, 255, 120)

        -- SE
        correctSound:Play()
        -- 画面フラッシュ（緑）
        screenFlash(Color3.fromRGB(100, 255, 120), 0.5)
        -- パーティクル（金色）
        emitParticles(Color3.fromRGB(255, 220, 80))
        -- パネル ポップ
        popFrame()
    else
        feedbackLabel.Text = "正解：" .. correctAnswer
        feedbackLabel.TextColor3 = Color3.fromRGB(255, 100, 100)

        -- SE
        incorrectSound:Play()
        -- 画面フラッシュ（赤、短め）
        screenFlash(Color3.fromRGB(255, 80, 80), 0.3)
        -- パネル シェイク
        task.spawn(shakeFrame)
    end
end)

------------------------------------------------------------------------
-- Phase 1: インベントリHUD更新
------------------------------------------------------------------------
local syncInventory = remotes:WaitForChild("SyncInventory", 30)

local function updateInventoryHud(inv)
    local hudGui = player.PlayerGui:FindFirstChild("InventoryHud")
    if not hudGui then return end
    local frame = hudGui:FindFirstChild("InventoryFrame")
    if not frame then return end

    for matKey, amount in pairs(inv) do
        local row = frame:FindFirstChild(matKey .. "Row")
        if row then
            local amountLabel = row:FindFirstChild("Amount")
            if amountLabel then
                local oldVal = tonumber(amountLabel.Text) or 0
                amountLabel.Text = tostring(amount)
                if amount > oldVal then
                    amountLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    task.delay(0.4, function()
                        if amountLabel and amountLabel.Parent then
                            amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                        end
                    end)
                end
            end
        end
    end
end

if syncInventory then
    syncInventory.OnClientEvent:Connect(function(inv)
        updateInventoryHud(inv)
    end)
end
