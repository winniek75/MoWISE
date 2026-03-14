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
-- 住民管理
------------------------------------------------------------------------
local residents        = {}
local pendingVillagers = {}
local villagerQueue    = {}

for _, v in ipairs(VILLAGER_DATA) do
    table.insert(villagerQueue, v)
end

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
    local session = pendingVillagers[player.UserId]
    if not session then return end
    if type(choiceIndex) ~= "number" or choiceIndex < 1 or choiceIndex > 4 then return end

    local turn    = session.vData.dialogue[session.turnIndex]
    local choice  = turn.options[choiceIndex]
    local correct = choice and choice.correct or false

    if correct then
        session.correctCount = session.correctCount + 1
        if mowiReaction then mowiReaction:Fire(player, "correct") end
    else
        if mowiReaction then mowiReaction:Fire(player, "incorrect") end
    end

    session.turnIndex = session.turnIndex + 1
    local isLast = session.turnIndex > #session.vData.dialogue

    dialogueResult:FireClient(player, correct, turn.options, session.turnIndex - 1, isLast)

    if isLast then
        task.wait(1.5)
        local passed = session.correctCount >= 2

        if passed then
            residents[session.vData.id] = {
                model    = session.npcModel,
                position = session.targetPos,
            }

            if giveMaterial then
                for mat, amount in pairs(session.vData.moveReward) do
                    giveMaterial:Fire(player, mat, amount)
                end
            end

            local head = session.npcModel:FindFirstChild("Head")
            if head then
                local markerGui = head:FindFirstChild("DialogueMarker")
                if markerGui then markerGui:Destroy() end

                local prompt2 = Instance.new("ProximityPrompt")
                prompt2.ActionText = "おはなしする"
                prompt2.ObjectText = session.vData.name
                prompt2.MaxActivationDistance = 8
                prompt2.Parent = head
            end

            villagerMoved:FireClient(player, session.vData.name, session.vData.role, session.correctCount)
            if mowiReaction then mowiReaction:Fire(player, "correct") end

            print(("[MoWISE] %s moved in! Correct: %d/3"):format(session.vData.name, session.correctCount))
        else
            local head = session.npcModel:FindFirstChild("Head")
            if head then
                local prompt = head:FindFirstChild("TalkPrompt")
                if prompt then prompt.Enabled = true end
            end
            villagerMoved:FireClient(player, session.vData.name, session.vData.role, -1)
        end

        pendingVillagers[player.UserId] = nil
    else
        task.wait(1)
        local nextTurn = session.vData.dialogue[session.turnIndex]
        startDialogue:FireClient(player, {
            npcName = session.vData.name,
            npcRole = session.vData.role,
            npc     = nextTurn.npc,
            options = nextTurn.options,
            hint    = nextTurn.hint,
            turn    = session.turnIndex,
            total   = #session.vData.dialogue,
        })
    end
end)

Players.PlayerRemoving:Connect(function(player)
    pendingVillagers[player.UserId] = nil
end)

print("[MoWISE] VillagerSystem ready")
