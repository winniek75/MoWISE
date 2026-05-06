-- NPCTakeoverListener.server.lua
-- C-3.1 Phase 3 / NPC ProximityPrompt 動的メニュー
--
-- 既存 NPC（Maria/Sam/Lily）の Head に「TeacherTakeoverPrompt」を追加し、
-- 既存 TownTalkPrompt（"英会話する"・C-1.2 で配置済）を引き継ぎ中に Enabled=false 化する。
--
-- npc モデル名規則（VillagerSystem.createNPCModel:331 を参照）:
--   "NPC_barista_maria" / "NPC_merchant_sam" / "NPC_agent_lily"
-- village_id → npc_id 変換は VillagerSystem.TOWN_TALK_NPC_ID_MAP に準ずる

local Players            = game:GetService("Players")
local CollectionService  = game:GetService("CollectionService")
local Workspace          = game:GetService("Workspace")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

------------------------------------------------------------------------
-- villager_id → npc_id（VillagerSystem と同マップを再宣言）
------------------------------------------------------------------------
local VILLAGER_TO_NPC = {
    barista_maria = "maria",
    merchant_sam  = "sam",
    agent_lily    = "lily",
}

local function getNpcIdFromModelName(modelName)
    -- "NPC_barista_maria" → "barista_maria" → "maria"
    if not modelName then return nil end
    local villagerId = string.match(modelName, "^NPC_(.+)$")
    if not villagerId then return nil end
    return VILLAGER_TO_NPC[villagerId]
end

------------------------------------------------------------------------
-- 既存 TownTalkPrompt（"英会話する"・C-1.2 で配置）の Enabled 切替
-- 引き継ぎ中：false（生徒からブロック）／引き継ぎ終了：true（再有効化）
------------------------------------------------------------------------
local function setNPCStudentPromptEnabled(npcModel, enabled)
    local head = npcModel and npcModel:FindFirstChild("Head")
    if not head then return end
    local townTalk = head:FindFirstChild("TownTalkPrompt")
    if townTalk then
        townTalk.Enabled = enabled
        print(("[NPCTakeoverListener] %s: TownTalkPrompt.Enabled = %s"):format(
            npcModel.Name, tostring(enabled)))
    end
end

------------------------------------------------------------------------
-- TeacherTakeoverPrompt 動的更新（先生のみ表示／状態反映）
------------------------------------------------------------------------
local function updatePromptState(prompt, npcId)
    local active = _G.getActiveTakeover and _G.getActiveTakeover(npcId)
    if active then
        -- 自分が引き継いでいるかは Triggered 時に再判定するためここでは ActionText のみ更新
        prompt.ActionText = "引き継ぎ終了"
    else
        prompt.ActionText = "引き継ぐ"
    end
end

------------------------------------------------------------------------
-- 既存 NPC モデルに TeacherTakeoverPrompt を取り付ける
------------------------------------------------------------------------
local function attachTeacherTakeoverPrompt(npcModel)
    if not npcModel then return end

    local npcId = getNpcIdFromModelName(npcModel.Name)
    if not npcId then return end

    local head = npcModel:FindFirstChild("Head")
    if not head then return end

    -- 二重生成防止
    if head:FindFirstChild("TeacherTakeoverPrompt") then return end

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name                  = "TeacherTakeoverPrompt"
    prompt.ActionText            = "引き継ぐ"
    prompt.ObjectText            = "先生メニュー"
    prompt.HoldDuration          = 0
    prompt.MaxActivationDistance = 8
    prompt.RequiresLineOfSight   = false
    -- Stage 1 MVP: Default スタイルで全プレイヤー可視（生徒が押しても Triggered で return）
    -- Stage 2 で Custom スタイル + 先生限定 UI に戻す
    prompt.Style                 = Enum.ProximityPromptStyle.Default
    prompt.UIOffset              = Vector2.new(0, -100)
    prompt.Parent                = head

    prompt.Triggered:Connect(function(player)
        -- ① 先生でなければ何もしない（Custom スタイルでクライアント UI も非表示の前提）
        if not player:GetAttribute("IsTeacher") then
            return
        end

        local active = _G.getActiveTakeover and _G.getActiveTakeover(npcId)

        if active and active.teacherPlayer == player then
            -- 自分が引き継ぎ中 → 終了
            local ok = _G.TakeoverService and _G.TakeoverService:End(player, npcId)
            if ok then
                setNPCStudentPromptEnabled(npcModel, true)
                updatePromptState(prompt, npcId)
            end
        elseif not active then
            -- 引き継ぎ開始
            local sessionId = _G.TakeoverService and _G.TakeoverService:Start(player, npcId)
            if sessionId then
                setNPCStudentPromptEnabled(npcModel, false)
                updatePromptState(prompt, npcId)
            end
        else
            -- 他先生が引き継ぎ中 → 同じ NPC は触れない
            warn(("[NPCTakeoverListener] %s: %s is taken over by %s"):format(
                player.Name, npcId,
                active.teacherPlayer and active.teacherPlayer.Name or "?"))
        end
    end)

    print(("[NPCTakeoverListener] TeacherTakeoverPrompt attached: %s → npc_id=%s"):format(
        npcModel.Name, npcId))
end

------------------------------------------------------------------------
-- 既存 NPC を走査 + 動的追加に対応
------------------------------------------------------------------------
-- (a) Workspace に既に存在する NPC を走査
for _, child in ipairs(Workspace:GetChildren()) do
    if getNpcIdFromModelName(child.Name) then
        attachTeacherTakeoverPrompt(child)
    end
end

-- (b) Workspace に新規追加された NPC を購読
Workspace.ChildAdded:Connect(function(child)
    if getNpcIdFromModelName(child.Name) then
        -- VillagerSystem.attachTownTalkPrompt の付与より後に走るよう少し待つ
        task.delay(2, function()
            if child.Parent then
                attachTeacherTakeoverPrompt(child)
            end
        end)
    end
end)

print("[NPCTakeoverListener] Listener active for maria/sam/lily NPCs")
