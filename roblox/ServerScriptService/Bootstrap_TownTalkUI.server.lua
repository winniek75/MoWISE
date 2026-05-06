-- Bootstrap_TownTalkUI.server.lua
-- C-1.2 Phase 1.2 / TownTalkUI ScreenGui 雛形を StarterGui に生成
-- 仕様：実装ガイド §6 のツリー構造に準拠
-- 既存 setupFlashOutputGui（WorldSetup.server.lua）と同パターン：
--   1. StarterGui に ScreenGui を生成（新規プレイヤー向け）
--   2. 既にスポーン済みのプレイヤーには PlayerGui に Clone を配布

local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local FONT_REG  = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

------------------------------------------------------------------------
-- ScreenGui 構築本体
------------------------------------------------------------------------
local function buildTownTalkUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name             = "TownTalkUI"
    screenGui.Enabled          = false
    screenGui.ResetOnSpawn     = false
    screenGui.IgnoreGuiInset   = true
    screenGui.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder     = 5

    --------------------------------------------------------------------
    -- Background（半透明オーバーレイ）
    --------------------------------------------------------------------
    local bg = Instance.new("Frame")
    bg.Name                   = "Background"
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.Position               = UDim2.new(0, 0, 0, 0)
    bg.BackgroundColor3       = rgb(0, 0, 0)
    bg.BackgroundTransparency = 0.6
    bg.BorderSizePixel        = 0
    bg.ZIndex                 = 1
    bg.Parent                 = screenGui

    --------------------------------------------------------------------
    -- DialogueFrame（NPC セリフ・ヘッダ・ターン進捗）
    --------------------------------------------------------------------
    local dialogueFrame = Instance.new("Frame")
    dialogueFrame.Name                   = "DialogueFrame"
    dialogueFrame.AnchorPoint            = Vector2.new(0.5, 0)
    dialogueFrame.Position               = UDim2.new(0.5, 0, 0.06, 0)
    dialogueFrame.Size                   = UDim2.new(0.7, 0, 0, 200)
    dialogueFrame.BackgroundColor3       = rgb(20, 25, 40)
    dialogueFrame.BackgroundTransparency = 0.05
    dialogueFrame.BorderSizePixel        = 0
    dialogueFrame.ZIndex                 = 5
    dialogueFrame.Parent                 = screenGui

    local dCorner = Instance.new("UICorner")
    dCorner.CornerRadius = UDim.new(0, 12)
    dCorner.Parent       = dialogueFrame

    local dPadding = Instance.new("UIPadding")
    dPadding.PaddingTop    = UDim.new(0, 12)
    dPadding.PaddingBottom = UDim.new(0, 12)
    dPadding.PaddingLeft   = UDim.new(0, 16)
    dPadding.PaddingRight  = UDim.new(0, 16)
    dPadding.Parent        = dialogueFrame

    -- NPCHeader（"💬 Maria  ☕ バリスタ"）
    local npcHeader = Instance.new("TextLabel")
    npcHeader.Name                   = "NPCHeader"
    npcHeader.Size                   = UDim2.new(1, 0, 0, 28)
    npcHeader.Position               = UDim2.new(0, 0, 0, 0)
    npcHeader.BackgroundTransparency = 1
    npcHeader.Text                   = ""
    npcHeader.TextColor3             = rgb(255, 220, 130)
    npcHeader.Font                   = FONT_BOLD
    npcHeader.TextSize               = 18
    npcHeader.TextXAlignment         = Enum.TextXAlignment.Left
    npcHeader.ZIndex                 = 6
    npcHeader.Parent                 = dialogueFrame

    -- NPCSpeechLabel（npc_audio 字幕）
    local npcSpeech = Instance.new("TextLabel")
    npcSpeech.Name                   = "NPCSpeechLabel"
    npcSpeech.Size                   = UDim2.new(1, 0, 0, 110)
    npcSpeech.Position               = UDim2.new(0, 0, 0, 34)
    npcSpeech.BackgroundTransparency = 1
    npcSpeech.Text                   = ""
    npcSpeech.TextColor3             = rgb(255, 255, 255)
    npcSpeech.Font                   = FONT_REG
    npcSpeech.TextSize               = 22
    npcSpeech.TextXAlignment         = Enum.TextXAlignment.Left
    npcSpeech.TextYAlignment         = Enum.TextYAlignment.Top
    npcSpeech.TextWrapped            = true
    npcSpeech.ZIndex                 = 6
    npcSpeech.Parent                 = dialogueFrame

    -- TurnProgress（"1 / 5" + 5格バー）
    local turnProgress = Instance.new("Frame")
    turnProgress.Name                   = "TurnProgress"
    turnProgress.Size                   = UDim2.new(1, 0, 0, 24)
    turnProgress.Position               = UDim2.new(0, 0, 1, -24)
    turnProgress.BackgroundTransparency = 1
    turnProgress.ZIndex                 = 6
    turnProgress.Parent                 = dialogueFrame

    local tpLabel = Instance.new("TextLabel")
    tpLabel.Name                   = "Label"
    tpLabel.Size                   = UDim2.new(0, 60, 1, 0)
    tpLabel.Position               = UDim2.new(0, 0, 0, 0)
    tpLabel.BackgroundTransparency = 1
    tpLabel.Text                   = "0 / 5"
    tpLabel.TextColor3             = rgb(180, 180, 180)
    tpLabel.Font                   = FONT_BOLD
    tpLabel.TextSize               = 14
    tpLabel.TextXAlignment         = Enum.TextXAlignment.Left
    tpLabel.ZIndex                 = 7
    tpLabel.Parent                 = turnProgress

    local tpBar = Instance.new("Frame")
    tpBar.Name                   = "Bar"
    tpBar.Size                   = UDim2.new(1, -70, 0, 8)
    tpBar.Position               = UDim2.new(0, 70, 0.5, -4)
    tpBar.BackgroundColor3       = rgb(60, 70, 90)
    tpBar.BorderSizePixel        = 0
    tpBar.ZIndex                 = 7
    tpBar.Parent                 = turnProgress

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 4)
    barCorner.Parent       = tpBar

    local barLayout = Instance.new("UIListLayout")
    barLayout.FillDirection      = Enum.FillDirection.Horizontal
    barLayout.Padding            = UDim.new(0, 4)
    barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    barLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
    barLayout.SortOrder          = Enum.SortOrder.LayoutOrder
    barLayout.Parent             = tpBar

    local barPad = Instance.new("UIPadding")
    barPad.PaddingLeft  = UDim.new(0, 4)
    barPad.PaddingRight = UDim.new(0, 4)
    barPad.Parent       = tpBar

    for i = 1, 5 do
        local cell = Instance.new("Frame")
        cell.Name                   = "Cell" .. i
        cell.Size                   = UDim2.new(0.18, -4, 1, -4)
        cell.BackgroundColor3       = rgb(40, 45, 55)
        cell.BorderSizePixel        = 0
        cell.LayoutOrder            = i
        cell.ZIndex                 = 8
        cell.Parent                 = tpBar
        local cc = Instance.new("UICorner")
        cc.CornerRadius = UDim.new(0, 2)
        cc.Parent       = cell
    end

    --------------------------------------------------------------------
    -- OptionsFrame（4 択ボタン縦並び）
    --------------------------------------------------------------------
    local optionsFrame = Instance.new("Frame")
    optionsFrame.Name                   = "OptionsFrame"
    optionsFrame.AnchorPoint            = Vector2.new(0.5, 1)
    optionsFrame.Position               = UDim2.new(0.5, 0, 0.94, 0)
    optionsFrame.Size                   = UDim2.new(0.7, 0, 0.45, 0)
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.ZIndex                 = 5
    optionsFrame.Parent                 = screenGui

    local optList = Instance.new("UIListLayout")
    optList.FillDirection       = Enum.FillDirection.Vertical
    optList.Padding             = UDim.new(0, 8)
    optList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    optList.SortOrder           = Enum.SortOrder.LayoutOrder
    optList.Parent              = optionsFrame

    for i = 1, 4 do
        local btn = Instance.new("TextButton")
        btn.Name                   = "OptionButton" .. i
        btn.Size                   = UDim2.new(1, 0, 0, 56)
        btn.BackgroundColor3       = rgb(35, 45, 65)
        btn.BorderSizePixel        = 0
        btn.AutoButtonColor        = true
        btn.Text                   = string.format("%s. ", string.char(64 + i))
        btn.TextColor3             = rgb(255, 255, 255)
        btn.Font                   = FONT_BOLD
        btn.TextSize               = 18
        btn.TextWrapped            = true
        btn.LayoutOrder            = i
        btn.Visible                = true
        btn.Active                 = false
        btn.ZIndex                 = 6
        btn.Parent                 = optionsFrame

        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 8)
        bc.Parent       = btn
    end

    --------------------------------------------------------------------
    -- ExplanationModal（誤答時の解説表示）
    --------------------------------------------------------------------
    local explModal = Instance.new("Frame")
    explModal.Name                   = "ExplanationModal"
    explModal.Visible                = false
    explModal.AnchorPoint            = Vector2.new(0.5, 0.5)
    explModal.Position               = UDim2.new(0.5, 0, 0.5, 0)
    explModal.Size                   = UDim2.new(0, 460, 0, 200)
    explModal.BackgroundColor3       = rgb(255, 245, 220)
    explModal.BorderSizePixel        = 0
    explModal.ZIndex                 = 20
    explModal.Parent                 = screenGui

    local emCorner = Instance.new("UICorner")
    emCorner.CornerRadius = UDim.new(0, 12)
    emCorner.Parent       = explModal

    local emPad = Instance.new("UIPadding")
    emPad.PaddingTop    = UDim.new(0, 16)
    emPad.PaddingBottom = UDim.new(0, 16)
    emPad.PaddingLeft   = UDim.new(0, 16)
    emPad.PaddingRight  = UDim.new(0, 16)
    emPad.Parent        = explModal

    local explLabel = Instance.new("TextLabel")
    explLabel.Name                   = "ExplanationLabel"
    explLabel.Size                   = UDim2.new(1, 0, 1, -56)
    explLabel.Position               = UDim2.new(0, 0, 0, 0)
    explLabel.BackgroundTransparency = 1
    explLabel.Text                   = ""
    explLabel.TextColor3             = rgb(60, 50, 30)
    explLabel.Font                   = FONT_BOLD
    explLabel.TextSize               = 20
    explLabel.TextWrapped            = true
    explLabel.TextXAlignment         = Enum.TextXAlignment.Center
    explLabel.TextYAlignment         = Enum.TextYAlignment.Center
    explLabel.ZIndex                 = 21
    explLabel.Parent                 = explModal

    local continueBtn = Instance.new("TextButton")
    continueBtn.Name                   = "ContinueButton"
    continueBtn.AnchorPoint            = Vector2.new(0.5, 1)
    continueBtn.Position               = UDim2.new(0.5, 0, 1, 0)
    continueBtn.Size                   = UDim2.new(0, 200, 0, 44)
    continueBtn.BackgroundColor3       = rgb(60, 120, 200)
    continueBtn.BorderSizePixel        = 0
    continueBtn.AutoButtonColor        = true
    continueBtn.Text                   = "もう一度"
    continueBtn.TextColor3             = rgb(255, 255, 255)
    continueBtn.Font                   = FONT_BOLD
    continueBtn.TextSize               = 18
    continueBtn.ZIndex                 = 21
    continueBtn.Parent                 = explModal

    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 8)
    cbCorner.Parent       = continueBtn

    --------------------------------------------------------------------
    -- ErrorModal（C-1.2 Phase 5：エラー時のメッセージ表示）
    -- TT_Cancel 受信時に showErrorModal で表示。OK ボタンで閉じる。
    --------------------------------------------------------------------
    local errorModal = Instance.new("Frame")
    errorModal.Name                   = "ErrorModal"
    errorModal.Visible                = false
    errorModal.AnchorPoint            = Vector2.new(0.5, 0.5)
    errorModal.Position               = UDim2.new(0.5, 0, 0.5, 0)
    errorModal.Size                   = UDim2.new(0, 460, 0, 200)
    errorModal.BackgroundColor3       = rgb(255, 230, 220)  -- 淡いピンク（エラーを優しく伝える）
    errorModal.BorderSizePixel        = 0
    errorModal.ZIndex                 = 25
    errorModal.Parent                 = screenGui

    local errCorner = Instance.new("UICorner")
    errCorner.CornerRadius = UDim.new(0, 12)
    errCorner.Parent       = errorModal

    local errPad = Instance.new("UIPadding")
    errPad.PaddingTop    = UDim.new(0, 16)
    errPad.PaddingBottom = UDim.new(0, 16)
    errPad.PaddingLeft   = UDim.new(0, 16)
    errPad.PaddingRight  = UDim.new(0, 16)
    errPad.Parent        = errorModal

    local errIcon = Instance.new("TextLabel")
    errIcon.Name                   = "ErrorIcon"
    errIcon.Size                   = UDim2.new(1, 0, 0, 36)
    errIcon.Position               = UDim2.new(0, 0, 0, 0)
    errIcon.BackgroundTransparency = 1
    errIcon.Text                   = "🐝"  -- Mowi 風アイコン
    errIcon.TextColor3             = rgb(200, 80, 60)
    errIcon.Font                   = FONT_BOLD
    errIcon.TextSize               = 32
    errIcon.ZIndex                 = 26
    errIcon.Parent                 = errorModal

    local errLabel = Instance.new("TextLabel")
    errLabel.Name                   = "ErrorLabel"
    errLabel.Size                   = UDim2.new(1, 0, 1, -90)
    errLabel.Position               = UDim2.new(0, 0, 0, 36)
    errLabel.BackgroundTransparency = 1
    errLabel.Text                   = ""
    errLabel.TextColor3             = rgb(80, 40, 30)
    errLabel.Font                   = FONT_BOLD
    errLabel.TextSize               = 18
    errLabel.TextWrapped            = true
    errLabel.TextXAlignment         = Enum.TextXAlignment.Center
    errLabel.TextYAlignment         = Enum.TextYAlignment.Center
    errLabel.ZIndex                 = 26
    errLabel.Parent                 = errorModal

    local errOkBtn = Instance.new("TextButton")
    errOkBtn.Name                   = "OkButton"
    errOkBtn.AnchorPoint            = Vector2.new(0.5, 1)
    errOkBtn.Position               = UDim2.new(0.5, 0, 1, 0)
    errOkBtn.Size                   = UDim2.new(0, 200, 0, 44)
    errOkBtn.BackgroundColor3       = rgb(200, 80, 60)
    errOkBtn.BorderSizePixel        = 0
    errOkBtn.AutoButtonColor        = true
    errOkBtn.Text                   = "OK"
    errOkBtn.TextColor3             = rgb(255, 255, 255)
    errOkBtn.Font                   = FONT_BOLD
    errOkBtn.TextSize               = 18
    errOkBtn.ZIndex                 = 26
    errOkBtn.Parent                 = errorModal

    local okCorner = Instance.new("UICorner")
    okCorner.CornerRadius = UDim.new(0, 8)
    okCorner.Parent       = errOkBtn

    --------------------------------------------------------------------
    -- CompleteOverlay（MISSION COMPLETE 演出）
    --------------------------------------------------------------------
    local completeOverlay = Instance.new("Frame")
    completeOverlay.Name                   = "CompleteOverlay"
    completeOverlay.Visible                = false
    completeOverlay.Size                   = UDim2.new(1, 0, 1, 0)
    completeOverlay.Position               = UDim2.new(0, 0, 0, 0)
    completeOverlay.BackgroundColor3       = rgb(0, 0, 0)
    completeOverlay.BackgroundTransparency = 0.3
    completeOverlay.BorderSizePixel        = 0
    completeOverlay.ZIndex                 = 30
    completeOverlay.Parent                 = screenGui

    local coLayout = Instance.new("UIListLayout")
    coLayout.FillDirection       = Enum.FillDirection.Vertical
    coLayout.Padding             = UDim.new(0, 16)
    coLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    coLayout.VerticalAlignment   = Enum.VerticalAlignment.Center
    coLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    coLayout.Parent              = completeOverlay

    local completeLabel = Instance.new("TextLabel")
    completeLabel.Name                   = "CompleteLabel"
    completeLabel.Size                   = UDim2.new(0, 600, 0, 80)
    completeLabel.BackgroundTransparency = 1
    completeLabel.Text                   = "MISSION COMPLETE!"
    completeLabel.TextColor3             = rgb(255, 220, 100)
    completeLabel.Font                   = FONT_BOLD
    completeLabel.TextSize               = 48
    completeLabel.LayoutOrder            = 1
    completeLabel.ZIndex                 = 31
    completeLabel.Parent                 = completeOverlay

    local rewardLabel = Instance.new("TextLabel")
    rewardLabel.Name                   = "RewardLabel"
    rewardLabel.Size                   = UDim2.new(0, 600, 0, 36)
    rewardLabel.BackgroundTransparency = 1
    rewardLabel.Text                   = ""
    rewardLabel.TextColor3             = rgb(255, 255, 255)
    rewardLabel.Font                   = FONT_BOLD
    rewardLabel.TextSize               = 24
    rewardLabel.LayoutOrder            = 2
    rewardLabel.ZIndex                 = 31
    rewardLabel.Parent                 = completeOverlay

    local mowiMessage = Instance.new("TextLabel")
    mowiMessage.Name                   = "MowiMessageLabel"
    mowiMessage.Size                   = UDim2.new(0, 600, 0, 32)
    mowiMessage.BackgroundTransparency = 1
    mowiMessage.Text                   = ""
    mowiMessage.TextColor3             = rgb(180, 220, 255)
    mowiMessage.Font                   = FONT_REG
    mowiMessage.TextSize               = 20
    mowiMessage.LayoutOrder            = 3
    mowiMessage.ZIndex                 = 31
    mowiMessage.Parent                 = completeOverlay

    return screenGui
end

------------------------------------------------------------------------
-- 配置：StarterGui への配置 + 既存プレイヤーへの配布
------------------------------------------------------------------------
local function setupTownTalkUI()
    if StarterGui:FindFirstChild("TownTalkUI") then
        print("[TownTalk] TownTalkUI already exists in StarterGui, skipping")
        return
    end

    local screenGui = buildTownTalkUI()
    screenGui.Parent = StarterGui

    -- 既にスポーン済みのプレイヤーには Clone を配布
    for _, p in ipairs(Players:GetPlayers()) do
        if p:FindFirstChild("PlayerGui") and not p.PlayerGui:FindFirstChild("TownTalkUI") then
            screenGui:Clone().Parent = p.PlayerGui
        end
    end

    print("[TownTalk] TownTalkUI created in StarterGui + distributed to existing players")
end

setupTownTalkUI()

------------------------------------------------------------------------
-- デバッグ用：UI 表示確認（実装ガイド §4 Phase 1 動作確認）
------------------------------------------------------------------------
_G.testTownTalkUI = function(player)
    if not player then
        warn("[TownTalk] testTownTalkUI: player nil")
        return
    end
    local gui = player:WaitForChild("PlayerGui"):WaitForChild("TownTalkUI", 5)
    if not gui then
        warn("[TownTalk] testTownTalkUI: TownTalkUI not found in PlayerGui")
        return
    end
    gui.Enabled = true
    print(("[TownTalk] testTownTalkUI: enabled for %s"):format(player.Name))
end
