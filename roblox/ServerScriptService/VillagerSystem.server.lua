-- VillagerSystem.server.lua
-- Phase 3: 町民移住システム
-- 小さな家（SmallHouse）配置 → NPCが歩いてくる → 会話ミッション → 移住確定

local Players            = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

-- RemoteEvent 追加
local villagerApproach = Instance.new("RemoteEvent", remotes)
villagerApproach.Name  = "VillagerApproach"

local startDialogue    = Instance.new("RemoteEvent", remotes)
startDialogue.Name     = "StartDialogue"

local dialogueAnswer   = Instance.new("RemoteEvent", remotes)
dialogueAnswer.Name    = "DialogueAnswer"

local dialogueResult   = Instance.new("RemoteEvent", remotes)
dialogueResult.Name    = "DialogueResult"

local villagerMoved    = Instance.new("RemoteEvent", remotes)
villagerMoved.Name     = "VillagerMoved"

-- Mowi リアクション（任意）
local mowiReaction = nil
task.spawn(function()
    mowiReaction = remotes:WaitForChild("MowiReaction", 30)
end)

-- 素材付与用
local giveMaterial = nil
task.spawn(function()
    giveMaterial = remotes:WaitForChild("GiveMaterial", 30)
end)

------------------------------------------------------------------------
-- Zone 1 町民データ（MVP: 3人）
------------------------------------------------------------------------
local VILLAGER_DATA = {
    {
        id        = "farmer_tom",
        name      = "Tom",
        role      = "Farmer",
        bodyColor = Color3.fromRGB(180, 120, 60),
        hatColor  = Color3.fromRGB(100, 60, 20),
        dialogue  = {
            {
                npc  = "Hello! My name is Tom. I'm looking for a new place to live.",
                options = {
                    { text = "Nice to meet you, Tom! I'm building a town here.", correct = true },
                    { text = "Go away.", correct = false },
                    { text = "I am Tom.", correct = false },
                    { text = "What's your name?", correct = false },
                },
                hint = "自己紹介してみよう"
            },
            {
                npc  = "This place looks nice. Are you the one who built this?",
                options = {
                    { text = "Yes! I built it. Do you like it?", correct = true },
                    { text = "I don't know.", correct = false },
                    { text = "No, I'm not.", correct = false },
                    { text = "Built? What?", correct = false },
                },
                hint = "肯定して会話を続けよう"
            },
            {
                npc  = "I'd like to live here. Is that okay with you?",
                options = {
                    { text = "Of course! You're welcome here.", correct = true },
                    { text = "No, go away.", correct = false },
                    { text = "I don't understand.", correct = false },
                    { text = "Maybe later.", correct = false },
                },
                hint = "歓迎の気持ちを伝えよう"
            },
        },
        moveReward = { Wood = 2 },
    },
    {
        id        = "teacher_maya",
        name      = "Maya",
        role      = "Teacher",
        bodyColor = Color3.fromRGB(100, 150, 220),
        hatColor  = Color3.fromRGB(60, 80, 160),
        dialogue  = {
            {
                npc  = "Hi there! I'm Maya. I used to teach at the old school.",
                options = {
                    { text = "Hi Maya! I'm glad to meet you.", correct = true },
                    { text = "I'm Maya too.", correct = false },
                    { text = "Old school?", correct = false },
                    { text = "I don't care.", correct = false },
                },
                hint = "挨拶してみよう"
            },
            {
                npc  = "I'm tired of traveling. I'm looking for a quiet place.",
                options = {
                    { text = "I understand. This place is very quiet.", correct = true },
                    { text = "I'm tired too.", correct = false },
                    { text = "Travel is fun!", correct = false },
                    { text = "I don't like quiet.", correct = false },
                },
                hint = "共感して会話しよう"
            },
            {
                npc  = "Can I stay here? I'd love to help the community.",
                options = {
                    { text = "Yes, please stay! We'd love your help.", correct = true },
                    { text = "No, you can't.", correct = false },
                    { text = "I'm busy.", correct = false },
                    { text = "What community?", correct = false },
                },
                hint = "歓迎しよう"
            },
        },
        moveReward = { Stone = 2 },
    },
    {
        id        = "child_leo",
        name      = "Leo",
        role      = "Kid",
        bodyColor = Color3.fromRGB(255, 180, 120),
        hatColor  = Color3.fromRGB(220, 120, 60),
        dialogue  = {
            {
                npc  = "Wow, cool house! Did you make that?",
                options = {
                    { text = "Yes, I made it myself!", correct = true },
                    { text = "No, I didn't.", correct = false },
                    { text = "What house?", correct = false },
                    { text = "Go away, kid.", correct = false },
                },
                hint = "自信を持って答えよう"
            },
            {
                npc  = "I'm Leo. I'm 12 years old. How about you?",
                options = {
                    { text = "Nice to meet you, Leo! I'm glad you're here.", correct = true },
                    { text = "I'm Leo too.", correct = false },
                    { text = "Old.", correct = false },
                    { text = "I don't know.", correct = false },
                },
                hint = "自己紹介しよう"
            },
            {
                npc  = "Can I live here? I want to help build the town!",
                options = {
                    { text = "Sure! I'd love your help, Leo.", correct = true },
                    { text = "No, kids can't live here.", correct = false },
                    { text = "I'm busy.", correct = false },
                    { text = "Maybe not.", correct = false },
                },
                hint = "子どもも歓迎しよう"
            },
        },
        moveReward = { Flower = 3 },
    },
}

------------------------------------------------------------------------
-- Zone 2 町民データ（Market Zone: 3人）
------------------------------------------------------------------------
local ZONE2_VILLAGER_DATA = {
    {
        id        = "barista_maria",
        name      = "Maria",
        role      = "☕ バリスタ",
        bodyColor = Color3.fromRGB(200, 140, 80),
        hatColor  = Color3.fromRGB(60, 30, 10),
        spawnZone = "Zone2",
        dialogue  = {
            {
                npc  = "Hi! Welcome to the market. I'd like to open a café here. Is that okay?",
                options = {
                    { text = "Of course! I'd like a café here too.", correct = true },
                    { text = "No, go away.", correct = false },
                    { text = "I'd like you to leave.", correct = false },
                    { text = "What's a café?", correct = false },
                },
                hint = "「I'd like ～」で気持ちを伝えよう"
            },
            {
                npc  = "Can I get your help to set up? I need a good spot.",
                options = {
                    { text = "Sure! Can I get you anything to start?", correct = true },
                    { text = "I can't help.", correct = false },
                    { text = "Can I get out of here?", correct = false },
                    { text = "You need what?", correct = false },
                },
                hint = "「Can I get ～」を使って会話しよう"
            },
            {
                npc  = "I'll make the best coffee in town. You'll love it!",
                options = {
                    { text = "I'll be your first customer!", correct = true },
                    { text = "I'll leave now.", correct = false },
                    { text = "Coffee is bad.", correct = false },
                    { text = "I'll think about it.", correct = false },
                },
                hint = "「I'll ～」で決意を表そう"
            },
        },
        moveReward = { itemName = "Coffee", amount = 2 },
    },
    {
        id        = "merchant_sam",
        name      = "Sam",
        role      = "🛒 商人",
        bodyColor = Color3.fromRGB(80, 120, 60),
        hatColor  = Color3.fromRGB(40, 60, 30),
        spawnZone = "Zone2",
        dialogue  = {
            {
                npc  = "Hello! Do you have a place for a general store here?",
                options = {
                    { text = "Yes! Do you have what this town needs?", correct = true },
                    { text = "Do you have any money?", correct = false },
                    { text = "No, we don't have space.", correct = false },
                    { text = "I don't understand.", correct = false },
                },
                hint = "「Do you have ～」で質問しよう"
            },
            {
                npc  = "I'll bring all kinds of goods. What do you need most?",
                options = {
                    { text = "I'll help you build the store!", correct = true },
                    { text = "I'll go now.", correct = false },
                    { text = "Nothing, thanks.", correct = false },
                    { text = "What do you sell?", correct = false },
                },
                hint = "「I'll ～」を使って応えよう"
            },
            {
                npc  = "Do you have any friends who might want to trade?",
                options = {
                    { text = "Sure! Do you have anything rare?", correct = true },
                    { text = "No, I don't have friends.", correct = false },
                    { text = "Do you have to ask?", correct = false },
                    { text = "I don't trade.", correct = false },
                },
                hint = "「Do you have ～」を繰り返し使おう"
            },
        },
        moveReward = { itemName = "Coins", amount = 150 },
    },
    {
        id        = "agent_lily",
        name      = "Lily",
        role      = "🌍 旅行エージェント",
        bodyColor = Color3.fromRGB(140, 100, 200),
        hatColor  = Color3.fromRGB(80, 50, 150),
        spawnZone = "Zone2",
        dialogue  = {
            {
                npc  = "Hi there! I'm going to open a travel agency in this market.",
                options = {
                    { text = "I'm going to welcome you! Please stay.", correct = true },
                    { text = "I'm going to leave.", correct = false },
                    { text = "I'm not going anywhere.", correct = false },
                    { text = "Where are you going?", correct = false },
                },
                hint = "「I'm going to ～」で意思を伝えよう"
            },
            {
                npc  = "How about putting my shop near the fountain? It's perfect!",
                options = {
                    { text = "How about right here? It's the best spot!", correct = true },
                    { text = "How about you leave?", correct = false },
                    { text = "I don't like fountains.", correct = false },
                    { text = "How about no.", correct = false },
                },
                hint = "「How about ～」で提案しよう"
            },
            {
                npc  = "I'm going to help people travel to other zones. Sound good?",
                options = {
                    { text = "Great! I'm going to be your first traveler.", correct = true },
                    { text = "I'm going to say no.", correct = false },
                    { text = "I don't like travel.", correct = false },
                    { text = "What zones?", correct = false },
                },
                hint = "「I'm going to ～」でもう一度使おう"
            },
        },
        moveReward = { itemName = "Map", amount = 1 },
    },
}

------------------------------------------------------------------------
-- 住民管理
------------------------------------------------------------------------
local residents        = {}
local pendingVillagers = {}
local villagerQueue    = {}

for _, v in ipairs(VILLAGER_DATA) do
    table.insert(villagerQueue, v)
end

-- Zone 2 キュー
local zone2VillagerQueue    = {}
local zone2Residents        = {}     -- { [npcId] = npcModel }
local zone2PendingVillagers = {}     -- { [userId] = { ... } }

for _, v in ipairs(ZONE2_VILLAGER_DATA) do
    table.insert(zone2VillagerQueue, v)
end

-- Zone 2 NPC スポーン位置（Zone 2の端・広場入口付近）
local ZONE2_SPAWN_POSITIONS = {
    Vector3.new(50, 5, 220),     -- Zone 2 入口付近A
    Vector3.new(20, 5, 235),     -- Zone 2 入口付近B
    Vector3.new(-20, 5, 240),    -- Zone 2 入口付近C
}
local zone2SpawnIndex = 1

------------------------------------------------------------------------
-- NPCモデルを生成
------------------------------------------------------------------------
local function createNPCModel(vData, spawnPos)
    local model = Instance.new("Model")
    model.Name  = "NPC_" .. vData.id
    model.Parent = workspace

    local torso = Instance.new("Part")
    torso.Name      = "Torso"
    torso.Size      = Vector3.new(2, 2, 1)
    torso.Color     = vData.bodyColor
    torso.Material  = Enum.Material.SmoothPlastic
    torso.CFrame    = CFrame.new(spawnPos + Vector3.new(0, 2, 0))
    torso.Anchored  = true
    torso.CanCollide = false
    torso.Parent    = model

    local head = Instance.new("Part")
    head.Name       = "Head"
    head.Size       = Vector3.new(1.5, 1.5, 1.5)
    head.Color      = Color3.fromRGB(255, 210, 160)
    head.Material   = Enum.Material.SmoothPlastic
    head.CFrame     = CFrame.new(spawnPos + Vector3.new(0, 3.75, 0))
    head.Anchored   = true
    head.CanCollide = false
    head.Parent     = model
    model.PrimaryPart = head

    local hat = Instance.new("Part")
    hat.Name      = "Hat"
    hat.Size      = Vector3.new(1.8, 0.4, 1.8)
    hat.Color     = vData.hatColor
    hat.Material  = Enum.Material.SmoothPlastic
    hat.CFrame    = CFrame.new(spawnPos + Vector3.new(0, 4.8, 0))
    hat.Anchored  = true
    hat.CanCollide = false
    hat.Parent    = model

    local billboard = Instance.new("BillboardGui")
    billboard.Size        = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2.5, 0)
    billboard.AlwaysOnTop = false
    billboard.Parent      = head

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Text                    = vData.name .. "\n" .. vData.role
    nameLabel.Size                    = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency  = 0.3
    nameLabel.BackgroundColor3        = Color3.fromRGB(20, 20, 30)
    nameLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
    nameLabel.Font                    = Enum.Font.GothamBold
    nameLabel.TextSize                = 11
    nameLabel.TextScaled              = true
    nameLabel.Parent                  = billboard
    Instance.new("UICorner", nameLabel).CornerRadius = UDim.new(0, 4)

    local marker = Instance.new("BillboardGui")
    marker.Name         = "DialogueMarker"
    marker.Size         = UDim2.new(0, 40, 0, 40)
    marker.StudsOffset  = Vector3.new(0, 4.5, 0)
    marker.AlwaysOnTop  = false
    marker.Parent       = head

    local markerLabel = Instance.new("TextLabel")
    markerLabel.Name                    = "MarkerText"
    markerLabel.Text                    = "?"
    markerLabel.Size                    = UDim2.new(1, 0, 1, 0)
    markerLabel.BackgroundTransparency  = 1
    markerLabel.TextColor3              = Color3.fromRGB(255, 220, 80)
    markerLabel.Font                    = Enum.Font.GothamBold
    markerLabel.TextScaled              = true
    markerLabel.Parent                  = marker

    local prompt = Instance.new("ProximityPrompt")
    prompt.Name       = "TalkPrompt"
    prompt.ActionText = "話しかける"
    prompt.ObjectText = vData.name
    prompt.MaxActivationDistance = 8
    prompt.Parent     = head

    return model
end

------------------------------------------------------------------------
-- NPCを目的地まで歩かせる
------------------------------------------------------------------------
local function walkNPCTo(npcModel, targetPos)
    local head  = npcModel:FindFirstChild("Head")
    local torso = npcModel:FindFirstChild("Torso")
    local hat   = npcModel:FindFirstChild("Hat")
    if not head then return end

    local path = PathfindingService:CreatePath({
        AgentRadius  = 1.5,
        AgentHeight  = 4,
        AgentCanJump = false,
    })

    local ok = pcall(function()
        path:ComputeAsync(head.Position, targetPos)
    end)

    local waypoints = {}
    if ok and path.Status == Enum.PathStatus.Success then
        waypoints = path:GetWaypoints()
    else
        table.insert(waypoints, { Position = targetPos })
    end

    for _, wp in ipairs(waypoints) do
        local wpPos = wp.Position
        local dist  = (wpPos - head.Position).Magnitude
        local dur   = math.max(dist / 8, 0.1)

        TweenService:Create(head,  TweenInfo.new(dur, Enum.EasingStyle.Linear),
            { CFrame = CFrame.new(wpPos + Vector3.new(0, 3.75, 0)) }):Play()
        TweenService:Create(torso, TweenInfo.new(dur, Enum.EasingStyle.Linear),
            { CFrame = CFrame.new(wpPos + Vector3.new(0, 2, 0)) }):Play()
        TweenService:Create(hat,   TweenInfo.new(dur, Enum.EasingStyle.Linear),
            { CFrame = CFrame.new(wpPos + Vector3.new(0, 4.8, 0)) }):Play()
        task.wait(dur + 0.05)
    end
end

------------------------------------------------------------------------
-- C-1.2 Phase 4 / Town Talk Prompt 統合（Zone 2 移住完了 NPC のみ対象）
-- 既存 TalkPrompt（話しかける）/ prompt2（おはなしする）には触れず、
-- 第2 Prompt として「英会話する」を並列追加する。
--
-- vData.id → C-1.3 シナリオ DB の npc_id マッピング：
--   barista_maria → maria
--   merchant_sam  → sam
--   agent_lily    → lily   ※実装ガイド §4-4 では traveler_lily と記載があるが、
--                            既存 ZONE2_VILLAGER_DATA の id が agent_lily のため実コードに合わせる
------------------------------------------------------------------------
local TOWN_TALK_NPC_ID_MAP = {
    barista_maria = "maria",
    merchant_sam  = "sam",
    agent_lily    = "lily",
}

local function getTownTalkNpcId(villagerId)
    return TOWN_TALK_NPC_ID_MAP[villagerId]
end

local function attachTownTalkPrompt(npcModel, vData)
    if not npcModel then return end
    local npcId = getTownTalkNpcId(vData.id)
    if not npcId then return end  -- マッピング無いなら no-op（Zone 1 全員 + 想定外 Zone 2 用）

    local head = npcModel:FindFirstChild("Head")
    if not head then return end

    -- 二重生成防止
    if head:FindFirstChild("TownTalkPrompt") then return end

    local ttPrompt = Instance.new("ProximityPrompt")
    ttPrompt.Name                  = "TownTalkPrompt"
    ttPrompt.ActionText            = "英会話する"
    ttPrompt.ObjectText            = vData.role  -- "☕ バリスタ" 等
    ttPrompt.HoldDuration          = 0
    ttPrompt.MaxActivationDistance = 8
    ttPrompt.RequiresLineOfSight   = false
    ttPrompt.UIOffset              = Vector2.new(0, -50)  -- 既存 prompt2 の上に並ぶ
    ttPrompt.Parent                = head

    ttPrompt.Triggered:Connect(function(player)
        if _G.TownTalkService then
            _G.TownTalkService:startSession(player, npcId)
        else
            warn("[VillagerSystem] _G.TownTalkService not ready (Phase 3 script load 失敗?)")
        end
    end)

    print(("[VillagerSystem] TownTalk prompt attached: %s → %s"):format(vData.id, npcId))
end

------------------------------------------------------------------------
-- Zone 2 NPC 召喚（Zone 2のスポーン位置を使用）
------------------------------------------------------------------------
local function spawnZone2Villager(player, vData)
    local spawnPos = ZONE2_SPAWN_POSITIONS[zone2SpawnIndex]
    zone2SpawnIndex = (zone2SpawnIndex % #ZONE2_SPAWN_POSITIONS) + 1

    -- NPCモデル生成（Zone 1と同じcreateNPCModel関数を再利用）
    local npcModel = createNPCModel(vData, spawnPos)

    -- Mowi 通知（クライアントに送る）
    for _, p in ipairs(game.Players:GetPlayers()) do
        villagerApproach:FireClient(p,
            vData.name,
            vData.role,
            "zone2"    -- Zone識別子
        )
    end

    -- ProximityPrompt でプレイヤーが話しかけられるようにする
    local head = npcModel:FindFirstChild("Head")
    if head then
        -- 既存の TalkPrompt を再利用（createNPCModel で作成済み）
        local prompt = head:FindFirstChild("TalkPrompt")
        if prompt then
            prompt.Triggered:Connect(function(trigPlayer)
                if zone2PendingVillagers[trigPlayer.UserId] then return end
                zone2PendingVillagers[trigPlayer.UserId] = {
                    villagerData = vData,
                    npcModel     = npcModel,
                    turnIndex    = 1,
                    correctCount = 0,
                }
                prompt.Enabled = false
                -- 会話ミッション開始
                local turn = vData.dialogue[1]
                startDialogue:FireClient(trigPlayer, {
                    npcName  = vData.name,
                    npcRole  = vData.role,
                    npc      = turn.npc,
                    options  = turn.options,
                    hint     = turn.hint,
                    turn     = 1,
                    total    = #vData.dialogue,
                })
            end)
        end
    end

    print(string.format("[Zone2 Villager] %s（%s）がスポーン: %s",
        vData.name, vData.role, tostring(spawnPos)))
    return npcModel
end

------------------------------------------------------------------------
-- 小さな家が配置されたら町民を呼ぶ（HouseBuilt BindableEvent）
------------------------------------------------------------------------
task.spawn(function()
    local houseBuiltEvent = remotes:WaitForChild("HouseBuilt", 30)
    if not houseBuiltEvent then
        warn("[VillagerSystem] HouseBuilt event not found")
        return
    end

    houseBuiltEvent.Event:Connect(function(player, housePosition)
        if #villagerQueue == 0 then return end

        local vData = table.remove(villagerQueue, 1)

        -- Mowi通知をクライアントに送る
        villagerApproach:FireClient(player, vData.name, vData.role)
        if mowiReaction then mowiReaction:Fire(player, "session_start") end

        task.wait(10)

        -- Zone1の端からNPCを生成
        local spawnPos  = Vector3.new(-80, 3, 0)
        local npcModel  = createNPCModel(vData, spawnPos)
        local targetPos = housePosition + Vector3.new(4, 0, 0)

        walkNPCTo(npcModel, targetPos)

        -- ProximityPromptで会話開始
        local head   = npcModel:WaitForChild("Head")
        local prompt = head:WaitForChild("TalkPrompt")

        prompt.Triggered:Connect(function(triggeringPlayer)
            if pendingVillagers[triggeringPlayer.UserId] then return end

            pendingVillagers[triggeringPlayer.UserId] = {
                vData        = vData,
                npcModel     = npcModel,
                turnIndex    = 1,
                correctCount = 0,
                targetPos    = targetPos,
            }

            prompt.Enabled = false

            local turn = vData.dialogue[1]
            startDialogue:FireClient(triggeringPlayer, {
                npcName = vData.name,
                npcRole = vData.role,
                npc     = turn.npc,
                options = turn.options,
                hint    = turn.hint,
                turn    = 1,
                total   = #vData.dialogue,
            })
        end)

        print(("[MoWISE] Villager %s arrived near house"):format(vData.name))
    end)
end)

------------------------------------------------------------------------
-- 会話の回答を受け取る
------------------------------------------------------------------------
dialogueAnswer.OnServerEvent:Connect(function(player, choiceIndex)
    if type(choiceIndex) ~= "number" or choiceIndex < 1 or choiceIndex > 4 then return end

    -- Zone 1 or Zone 2 判定
    local session = pendingVillagers[player.UserId]
    local session2 = zone2PendingVillagers[player.UserId]
    local isZone2 = (session2 ~= nil and session == nil)
    local activeSession = session or session2
    if not activeSession then return end

    -- Zone 2 は villagerData / Zone 1 は vData
    local vData = isZone2 and activeSession.villagerData or activeSession.vData
    local turn    = vData.dialogue[activeSession.turnIndex]
    local choice  = turn.options[choiceIndex]
    local correct = choice and choice.correct or false

    if correct then
        activeSession.correctCount = activeSession.correctCount + 1
        if mowiReaction then mowiReaction:Fire(player, "correct") end
    else
        if mowiReaction then mowiReaction:Fire(player, "incorrect") end
    end

    activeSession.turnIndex = activeSession.turnIndex + 1
    local isLast = activeSession.turnIndex > #vData.dialogue

    dialogueResult:FireClient(player, correct, turn.options, activeSession.turnIndex - 1, isLast)

    if isLast then
        task.wait(1.5)
        local passed = activeSession.correctCount >= 2

        if passed then
            -- 報酬付与
            if isZone2 then
                -- Zone 2: moveReward = { itemName = "...", amount = N }
                local reward = vData.moveReward
                if reward and reward.itemName == "Coins" then
                    local coins = player:FindFirstChild("WordCoins")
                    if coins then coins.Value = coins.Value + reward.amount end
                elseif reward and giveMaterial then
                    giveMaterial:Fire(player, reward.itemName, reward.amount)
                end
                zone2Residents[vData.id] = activeSession.npcModel
            else
                -- Zone 1: moveReward = { Wood = 2 } etc.
                residents[vData.id] = {
                    model    = activeSession.npcModel,
                    position = activeSession.targetPos,
                }
                if giveMaterial then
                    for mat, amount in pairs(vData.moveReward) do
                        giveMaterial:Fire(player, mat, amount)
                    end
                end
            end

            local head = activeSession.npcModel:FindFirstChild("Head")
            if head then
                local markerGui = head:FindFirstChild("DialogueMarker")
                if markerGui then markerGui:Destroy() end

                local prompt2 = Instance.new("ProximityPrompt")
                prompt2.ActionText = "おはなしする"
                prompt2.ObjectText = vData.name
                prompt2.MaxActivationDistance = 8
                prompt2.Parent = head
            end

            -- C-1.2 Phase 4：Zone 2 villager 移住完了時に Town Talk Prompt を並列追加
            -- Zone 1 villager は getTownTalkNpcId が nil を返すため自動 no-op
            attachTownTalkPrompt(activeSession.npcModel, vData)

            villagerMoved:FireClient(player, vData.name, vData.role, activeSession.correctCount)
            if mowiReaction then mowiReaction:Fire(player, "correct") end

            print(("[MoWISE] %s moved in! Correct: %d/3"):format(vData.name, activeSession.correctCount))
        else
            local head = activeSession.npcModel:FindFirstChild("Head")
            if head then
                local prompt = head:FindFirstChild("TalkPrompt")
                if prompt then prompt.Enabled = true end
            end
            villagerMoved:FireClient(player, vData.name, vData.role, -1)
        end

        if isZone2 then
            zone2PendingVillagers[player.UserId] = nil
        else
            pendingVillagers[player.UserId] = nil
        end
    else
        task.wait(1)
        local nextTurn = vData.dialogue[activeSession.turnIndex]
        startDialogue:FireClient(player, {
            npcName = vData.name,
            npcRole = vData.role,
            npc     = nextTurn.npc,
            options = nextTurn.options,
            hint    = nextTurn.hint,
            turn    = activeSession.turnIndex,
            total   = #vData.dialogue,
        })
    end
end)

Players.PlayerRemoving:Connect(function(player)
    pendingVillagers[player.UserId] = nil
    zone2PendingVillagers[player.UserId] = nil
end)

------------------------------------------------------------------------
-- Zone 2 建物カウント → NPC トリガー
-- Zone 2の建物が 5棟、10棟、15棟 になるたびに次のNPCを呼ぶ
------------------------------------------------------------------------
local zone2BuildingThresholds = { 5, 10, 15 }
local zone2TriggeredIndex     = 0
local zone2BuildingCount      = 0

-- BindableEvent: ZoneSystem/CraftingSystem から Zone 2 建設通知を受け取る
local zone2BuildingAdded = Instance.new("BindableEvent")
zone2BuildingAdded.Name  = "Zone2BuildingAdded"
zone2BuildingAdded.Parent = remotes

zone2BuildingAdded.Event:Connect(function(player)
    zone2BuildingCount = zone2BuildingCount + 1
    print(string.format("[Zone2] %s が建物を建設 → 合計 %d棟", player.Name, zone2BuildingCount))

    -- しきい値チェック
    local nextThreshold = zone2BuildingThresholds[zone2TriggeredIndex + 1]
    if nextThreshold and zone2BuildingCount >= nextThreshold then
        zone2TriggeredIndex = zone2TriggeredIndex + 1
        local nextVillager = zone2VillagerQueue[zone2TriggeredIndex]
        if nextVillager and not zone2Residents[nextVillager.id] then
            task.delay(8, function()  -- 8秒後にスポーン
                spawnZone2Villager(player, nextVillager)
            end)
        end
    end
end)

print("[MoWISE] VillagerSystem ready (Zone 1: 3 NPCs | Zone 2: 3 NPCs)")
