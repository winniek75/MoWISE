-- TownTalkClient.client.lua
-- C-1.2 Phase 2 / Town Talk クライアント側 UI ロジック
--
-- 責務：
--   1. TT_Start 受信 → セッション構築 → ターン1構築
--   2. 4択シャッフル（option_id 保持・表示順だけ変える）
--   3. 選択肢クリック → TT_AnswerSubmit:FireServer(turnNo, option_id)
--   4. TT_TurnResult 受信 → 正誤フラッシュ・解説モーダル/ブリーフ・次ターン構築
--   5. TT_MissionComplete 受信 → CompleteOverlay 演出
--   6. TT_Cancel 受信 → UI 閉じ + エラー表示（Phase 5 で本格化）
--
-- option_id 保持の徹底：
--   表示順 (1..4) は shuffleOptions で毎回変わるが、各 option.option_id は不変。
--   サーバには表示順ではなく option_id を送ることでサーバ側 validateTurn が正しく動く。
--
-- △ パターン（Lily のみ）：
--   is_correct=false, is_acceptable=true, explanation 非 nil
--   → ✅ 扱いだが解説をブリーフ表示、次ターンへ進む

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")

local remotes            = ReplicatedStorage:WaitForChild("MoWISERemotes")
local TT_Start           = remotes:WaitForChild("TT_Start")
local TT_AnswerSubmit    = remotes:WaitForChild("TT_AnswerSubmit")
local TT_TurnResult      = remotes:WaitForChild("TT_TurnResult")
local TT_MissionComplete = remotes:WaitForChild("TT_MissionComplete")
local TT_Cancel          = remotes:WaitForChild("TT_Cancel")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local gui       = playerGui:WaitForChild("TownTalkUI")

------------------------------------------------------------------------
-- UI 要素参照
------------------------------------------------------------------------
local dialogueFrame  = gui:WaitForChild("DialogueFrame")
local npcHeader      = dialogueFrame:WaitForChild("NPCHeader")
local npcSpeech      = dialogueFrame:WaitForChild("NPCSpeechLabel")
local turnProgress   = dialogueFrame:WaitForChild("TurnProgress")
local tpLabel        = turnProgress:WaitForChild("Label")
local tpBar          = turnProgress:WaitForChild("Bar")

local optionsFrame   = gui:WaitForChild("OptionsFrame")
local optionButtons  = {}
for i = 1, 4 do
    optionButtons[i] = optionsFrame:WaitForChild("OptionButton" .. i)
end

local explModal      = gui:WaitForChild("ExplanationModal")
local explLabel      = explModal:WaitForChild("ExplanationLabel")
local continueBtn    = explModal:WaitForChild("ContinueButton")

-- C-1.2 Phase 5：エラーモーダル
local errorModal     = gui:WaitForChild("ErrorModal")
local errorLabel     = errorModal:WaitForChild("ErrorLabel")
local errorOkBtn     = errorModal:WaitForChild("OkButton")

local completeOverlay = gui:WaitForChild("CompleteOverlay")
local completeLabel   = completeOverlay:WaitForChild("CompleteLabel")
local rewardLabel     = completeOverlay:WaitForChild("RewardLabel")
local mowiMessage     = completeOverlay:WaitForChild("MowiMessageLabel")

------------------------------------------------------------------------
-- 定数
------------------------------------------------------------------------
local NPC_INFO = {
    maria = { name = "Maria", role = "☕ バリスタ" },
    sam   = { name = "Sam",   role = "🛍️ 店員" },
    lily  = { name = "Lily",  role = "📚 司書" },
}

local COLOR_NORMAL = Color3.fromRGB(35, 45, 65)
local COLOR_GREEN  = Color3.fromRGB(46, 204, 113)
local COLOR_RED    = Color3.fromRGB(231, 76, 60)
local COLOR_GREY   = Color3.fromRGB(60, 65, 80)

local CELL_DONE   = Color3.fromRGB(46, 204, 113)
local CELL_CURR   = Color3.fromRGB(255, 220, 100)
local CELL_TODO   = Color3.fromRGB(40, 45, 55)

-- math.random をプロセス起動ごとに変える（Run のたびに別の並び順）
math.randomseed(tick() * 1e6 + player.UserId)

------------------------------------------------------------------------
-- セッション state
------------------------------------------------------------------------
local session = nil
-- {
--   scenarioId           = string,
--   scenario             = table,
--   currentTurn          = number,
--   shuffledOptions      = { [1..4] = option },  -- 表示順
--   lastClickedDisplayIdx = number | nil,         -- フラッシュ用
--   selectionReason      = string,
-- }

local awaitingResult = false  -- ボタン連打防止
local explContinueCallback = nil

------------------------------------------------------------------------
-- ヘルパー：UI 操作
------------------------------------------------------------------------
local function setOptionsActive(active)
    for i = 1, 4 do
        optionButtons[i].Active   = active
        optionButtons[i].AutoButtonColor = active
        optionButtons[i].BackgroundColor3 = active and COLOR_NORMAL or COLOR_GREY
    end
end

local function flashOption(displayIdx, color)
    local btn = optionButtons[displayIdx]
    if not btn then return end
    local original = COLOR_NORMAL
    btn.BackgroundColor3 = color
    task.delay(0.6, function()
        if btn and btn.Parent then
            btn.BackgroundColor3 = original
        end
    end)
end

local function updateTurnProgress(currentTurn, totalTurns)
    tpLabel.Text = string.format("%d / %d", currentTurn, totalTurns)
    -- 5格セルの色更新
    for i = 1, 5 do
        local cell = tpBar:FindFirstChild("Cell" .. i)
        if cell then
            if i < currentTurn then
                cell.BackgroundColor3 = CELL_DONE
            elseif i == currentTurn then
                cell.BackgroundColor3 = CELL_CURR
            else
                cell.BackgroundColor3 = CELL_TODO
            end
        end
    end
end

local function showExplanationModal(text, btnText, onContinue)
    explLabel.Text = text or ""
    continueBtn.Text = btnText or "次へ"
    explContinueCallback = onContinue
    explModal.Visible = true
end

local function hideExplanationModal()
    explModal.Visible = false
    explLabel.Text = ""
    explContinueCallback = nil
end

local function showExplanationBrief(text, durationSec)
    -- △ パターン用：短時間トースト風表示（モーダルだが ContinueButton 非表示）
    explLabel.Text = text or ""
    continueBtn.Visible = false
    explModal.Visible = true
    task.delay(durationSec or 0.8, function()
        explModal.Visible = false
        continueBtn.Visible = true
    end)
end

local function hideUI()
    gui.Enabled = false
    completeOverlay.Visible = false
    explModal.Visible = false
    errorModal.Visible = false
    continueBtn.Visible = true
    setOptionsActive(false)
    session = nil
    awaitingResult = false
end

------------------------------------------------------------------------
-- C-1.2 Phase 5：エラーモーダル表示
-- TT_Cancel reason → 日本語メッセージ変換 → ErrorModal 表示
------------------------------------------------------------------------
local ERROR_MESSAGES = {
    NOT_LINKED    = "Web アプリと連携してから話そう。",
    NO_SCENARIO   = "今は話せないみたい。少し経ってからまた来てね。",
    AUTH          = "接続エラー。サポートに連絡してね。",
    NETWORK       = "電波が悪いみたい。少し経ってからまた来てね。",
    SUBMIT_FAILED = "結果が保存できなかった。もう一度試してね。",
    RESET         = nil,  -- 既存セッションのリセット時は表示しない
}

local function showErrorModal(reason)
    if reason == "RESET" then return end  -- 内部用 reason は無視

    -- セッション中の他モーダル/ボタンを隠す
    explModal.Visible       = false
    completeOverlay.Visible = false
    setOptionsActive(false)

    -- メッセージを設定
    local msg = ERROR_MESSAGES[reason]
    if not msg then
        msg = string.format("エラーが起きたみたい。(%s)", tostring(reason))
    end
    errorLabel.Text = msg

    -- UI 全体を有効化＋エラーモーダルだけ表示
    gui.Enabled = true
    errorModal.Visible = true
end

------------------------------------------------------------------------
-- 4択シャッフル（Fisher-Yates、option_id 保持）
------------------------------------------------------------------------
local function shuffleOptions(options)
    local shuffled = {}
    for i, opt in ipairs(options) do shuffled[i] = opt end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

------------------------------------------------------------------------
-- ターン構築
------------------------------------------------------------------------
local function buildTurn(turnNo)
    if not session then return end
    local turn = session.scenario.turns[turnNo]
    if not turn then
        warn(("[TownTalkClient] turn %d not found in scenario"):format(turnNo))
        return
    end

    session.currentTurn = turnNo
    awaitingResult = false

    -- ヘッダー
    local info = NPC_INFO[session.scenario.npc_id] or { name = "?", role = "" }
    npcHeader.Text = string.format("💬 %s  %s", info.name, info.role)

    -- セリフ
    npcSpeech.Text = turn.npc_audio or ""

    -- 進捗
    updateTurnProgress(turnNo, session.scenario.total_turns or 5)

    -- 4択シャッフル
    local shuffled = shuffleOptions(turn.options)
    session.shuffledOptions = shuffled

    for i = 1, 4 do
        local opt = shuffled[i]
        if opt then
            optionButtons[i].Text = string.format("%s. %s", string.char(64 + i), opt.text)
            optionButtons[i].Visible = true
        else
            optionButtons[i].Visible = false
        end
    end

    setOptionsActive(true)
    hideExplanationModal()
end

------------------------------------------------------------------------
-- 選択肢クリックハンドラ
------------------------------------------------------------------------
for i = 1, 4 do
    optionButtons[i].MouseButton1Click:Connect(function()
        if not session or not session.shuffledOptions or awaitingResult then return end
        local opt = session.shuffledOptions[i]
        if not opt then return end

        awaitingResult = true
        session.lastClickedDisplayIdx = i
        setOptionsActive(false)

        -- option_id を送信（表示順 i ではない！）
        TT_AnswerSubmit:FireServer(session.currentTurn, opt.option_id)
    end)
end

------------------------------------------------------------------------
-- 解説モーダル「もう一度 / 次へ」ボタン
------------------------------------------------------------------------
continueBtn.MouseButton1Click:Connect(function()
    local cb = explContinueCallback
    hideExplanationModal()
    if cb then cb() end
end)

------------------------------------------------------------------------
-- ErrorModal の OK ボタン：UI を完全に閉じる
------------------------------------------------------------------------
errorOkBtn.MouseButton1Click:Connect(function()
    hideUI()
end)

------------------------------------------------------------------------
-- TT_Start：セッション開始
------------------------------------------------------------------------
TT_Start.OnClientEvent:Connect(function(payload)
    if not payload or not payload.scenario then
        warn("[TownTalkClient] TT_Start: invalid payload")
        return
    end

    session = {
        scenarioId      = payload.scenario_id,
        scenario        = payload.scenario,
        currentTurn     = 1,
        shuffledOptions = nil,
        selectionReason = payload.selection_reason,
    }

    completeOverlay.Visible = false
    gui.Enabled = true
    buildTurn(1)

    print(("[TownTalkClient] TT_Start: scenario=%s reason=%s"):format(
        tostring(payload.scenario_id), tostring(payload.selection_reason)))
end)

------------------------------------------------------------------------
-- TT_TurnResult：正誤判定結果
------------------------------------------------------------------------
TT_TurnResult.OnClientEvent:Connect(function(turnNo, isCorrect, isAcceptable, explanation, nextNpcAudio)
    if not session then return end
    if turnNo ~= session.currentTurn then
        warn(("[TownTalkClient] TT_TurnResult: turn mismatch (got %d, expected %d)"):format(
            turnNo, session.currentTurn))
        return
    end

    local turn = session.scenario.turns[turnNo]
    local turnTotal = session.scenario.total_turns or 5

    -- フラッシュ：最後にクリックされた表示位置のボタンを着色
    local clickedIdx = session.lastClickedDisplayIdx
    if clickedIdx then
        if isCorrect or isAcceptable then
            flashOption(clickedIdx, COLOR_GREEN)
        else
            flashOption(clickedIdx, COLOR_RED)
        end
    end

    if isCorrect or isAcceptable then
        --------------------------------------------------------------
        -- ✅ または △：次ターンへ進む（または完了待ち）
        --------------------------------------------------------------
        if isAcceptable and not isCorrect and explanation and explanation ~= "" then
            -- △：解説をブリーフ表示してから進める
            showExplanationBrief(explanation, 1.6)
            task.wait(1.7)
        else
            -- ✅：NPC 反応を一瞬表示
            if turn and turn.npc_reaction_correct then
                npcSpeech.Text = turn.npc_reaction_correct
            end
            task.wait(0.7)
        end

        -- yield 後は session が破棄されている可能性があるので再チェック
        if not session then return end

        if turnNo < turnTotal then
            buildTurn(turnNo + 1)
        else
            -- 最終ターン正解 → MissionComplete 待ち（サーバから来る）
            setOptionsActive(false)
            npcSpeech.Text = (turn and turn.npc_reaction_correct) or npcSpeech.Text
        end
    else
        --------------------------------------------------------------
        -- ❌：解説モーダル + 「もう一度」→ 同ターン再挑戦
        --------------------------------------------------------------
        showExplanationModal(
            explanation or "もう一度試してみよう。",
            "もう一度",
            function()
                buildTurn(turnNo)  -- 同ターン再構築
            end
        )
    end
end)

------------------------------------------------------------------------
-- TT_MissionComplete：完了演出
------------------------------------------------------------------------
TT_MissionComplete.OnClientEvent:Connect(function(rewards)
    rewards = rewards or {}

    rewardLabel.Text = string.format("+%d Coins / 友好度 +%d",
        rewards.coins_granted or 0,
        rewards.friendship_delta or 0)
    mowiMessage.Text = rewards.mowi_message or ""

    completeOverlay.Visible = true

    -- レインボーアニメ（簡略：HSV を 2秒間隔で循環、Visible=false になったら自然終了）
    task.spawn(function()
        local t = 0
        while completeOverlay.Visible do
            t = (t + RunService.Heartbeat:Wait()) % 2
            completeLabel.TextColor3 = Color3.fromHSV(t / 2, 0.7, 1)
        end
    end)

    -- 3秒後に UI を閉じる
    task.delay(3, function()
        hideUI()
    end)

    print(("[TownTalkClient] TT_MissionComplete: +%s coins, msg=%s"):format(
        tostring(rewards.coins_granted), tostring(rewards.mowi_message)))
end)

------------------------------------------------------------------------
-- TT_Cancel：エラー or 中断
-- C-1.2 Phase 5：reason に応じて日本語メッセージのモーダル表示
------------------------------------------------------------------------
TT_Cancel.OnClientEvent:Connect(function(reason)
    warn(("[TownTalkClient] TT_Cancel: reason=%s"):format(tostring(reason)))

    -- セッション state クリア（モーダル表示の前にやる）
    session = nil
    awaitingResult = false

    if reason == "RESET" then
        -- 内部用：UI だけ閉じる
        hideUI()
        return
    end

    -- ユーザー向けエラー表示
    showErrorModal(reason)
end)

------------------------------------------------------------------------
-- 初期化
------------------------------------------------------------------------
gui.Enabled = false
setOptionsActive(false)
hideExplanationModal()
errorModal.Visible = false
completeOverlay.Visible = false

print("[TownTalkClient] ready (Phase 5 full)")
