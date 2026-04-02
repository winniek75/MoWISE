-- MowiSpawner.server.lua
-- Mowi をプリミティブパーツで生成し、感情・輝度・リングを制御する
-- Phase 0: プレイヤー追従型 Mowi（各プレイヤーの肩に浮遊）
-- Phase 9: ワールド中央固定 Mowi（Zone 1 広場上空）+ 感情・輝度・リング連動
-- ※ FBX モデル受領後は createMowiModel() / createWorldMowi() の中身だけ差し替えること

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes", 30)
if not remotes then
    warn("[MowiSpawner] MoWISERemotes not found")
    return
end

------------------------------------------------------------------------
-- ワールド中央 Mowi（Zone 1 広場上空）
------------------------------------------------------------------------
local MOWI_POSITION = Vector3.new(0, 22, 0)   -- Zone 1 広場中央上空

-- クライアントへの感情演出通知
local mowiEmotion = Instance.new("RemoteEvent", remotes)
mowiEmotion.Name  = "MowiEmotion"   -- "joy" / "sad" / "grow" / "idle"

local function createWorldMowi()
    local model = Instance.new("Model")
    model.Name  = "Mowi"

    -- BODY（球体）
    local body = Instance.new("Part")
    body.Name        = "BODY"
    body.Shape       = Enum.PartType.Ball
    body.Size        = Vector3.new(3, 3, 3)
    body.Color       = Color3.fromRGB(255, 255, 255)
    body.Material    = Enum.Material.SmoothPlastic
    body.Reflectance = 0.3
    body.Anchored    = true
    body.CanCollide  = false
    body.CFrame      = CFrame.new(MOWI_POSITION)
    body.Parent      = model

    -- 内部グロー
    local glow = Instance.new("PointLight", body)
    glow.Name       = "GLOW_INNER"
    glow.Brightness = 0.5
    glow.Range      = 10
    glow.Color      = Color3.fromRGB(200, 220, 255)

    -- パーティクル（LvUP・Joy時に有効化）
    local particles = Instance.new("ParticleEmitter", body)
    particles.Name    = "PARTICLES"
    particles.Enabled = false
    particles.Color   = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 100, 200)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 200, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 240, 100)),
    })
    particles.LightEmission = 1
    particles.Size     = NumberSequence.new(0.3)
    particles.Rate     = 15
    particles.Lifetime = NumberRange.new(0.8, 1.2)
    particles.Speed    = NumberRange.new(3, 6)

    -- リング（Cylinder を薄くしてリング代替）
    local function createRing(name, outerSize, color, xRot)
        local ring = Instance.new("Part")
        ring.Name        = name
        ring.Shape       = Enum.PartType.Cylinder
        ring.Size        = Vector3.new(0.3, outerSize, outerSize)
        ring.Color       = color
        ring.Material    = Enum.Material.Neon
        ring.Anchored    = true
        ring.CanCollide  = false
        ring.Transparency = 1   -- 初期非表示
        ring.CFrame      = CFrame.new(MOWI_POSITION) * CFrame.fromEulerAnglesXYZ(xRot, 0, math.pi/2)
        ring.Parent      = model
        return ring
    end

    local ringA = createRing("RING_A", 4.5, Color3.fromRGB(255, 150, 50),  0)
    local ringB = createRing("RING_B", 5.0, Color3.fromRGB(100, 220, 100), math.rad(45))
    local ringC = createRing("RING_C", 5.5, Color3.fromRGB(150, 100, 255), math.rad(-45))

    model.Parent = workspace
    return {
        model     = model,
        body      = body,
        glow      = glow,
        particles = particles,
        rings     = { ringA, ringB, ringC },
    }
end

local worldMowi = createWorldMowi()
print("[Mowi] ワールド Mowi スポーン完了:", MOWI_POSITION)

------------------------------------------------------------------------
-- Idle アニメーション（上下浮遊 + リング回転）
------------------------------------------------------------------------
local floatOffset   = 0
local floatDir      = 1
local ringRotations = { 0, 0, 0 }
local ringSpeeds    = { 30, -40, 25 }  -- 各リングの回転速度（°/s）

RunService.Heartbeat:Connect(function(dt)
    -- 上下浮遊
    floatOffset = floatOffset + floatDir * dt * 0.5
    if floatOffset > 0.8 then floatDir = -1 end
    if floatOffset < 0   then floatDir =  1 end
    worldMowi.body.CFrame = CFrame.new(MOWI_POSITION + Vector3.new(0, floatOffset, 0))

    -- リング回転
    for i, ring in ipairs(worldMowi.rings) do
        ringRotations[i] = ringRotations[i] + ringSpeeds[i] * dt
        local baseX = (i == 1) and 0 or (i == 2) and math.rad(45) or math.rad(-45)
        ring.CFrame = CFrame.new(MOWI_POSITION + Vector3.new(0, floatOffset, 0))
            * CFrame.fromEulerAnglesXYZ(baseX, math.rad(ringRotations[i]), math.pi/2)
    end
end)

------------------------------------------------------------------------
-- sync-pull 受信時の Mowi 状態更新（HeartbeatLoop から BindableEvent）
------------------------------------------------------------------------
local function updateMowiState(brightnessLevel, growthStage)
    brightnessLevel = brightnessLevel or 1
    growthStage     = growthStage     or 1

    -- グロー輝度（1〜10 → 0.2〜3.0）
    local targetBrightness = 0.2 + (brightnessLevel / 10) * 2.8
    TweenService:Create(worldMowi.glow, TweenInfo.new(1.5), {
        Brightness = targetBrightness
    }):Play()

    -- リング表示（growth_stage でリング数を決定）
    local ringCount = 0
    if growthStage >= 3 then ringCount = 1 end  -- Lv3〜: RING_A
    if growthStage >= 6 then ringCount = 2 end  -- Lv6〜: +RING_B
    if growthStage >= 9 then ringCount = 3 end  -- Lv9〜: +RING_C

    for i, ring in ipairs(worldMowi.rings) do
        local targetTrans = (i <= ringCount) and 0 or 1
        TweenService:Create(ring, TweenInfo.new(1.0), {
            Transparency = targetTrans
        }):Play()
    end

    print(string.format("[Mowi] 輝度:%d → %.1f / リング:%d本",
        brightnessLevel, targetBrightness, ringCount))
end

------------------------------------------------------------------------
-- 感情アニメーション（FlashOutputServer から BindableEvent）
------------------------------------------------------------------------
local mowiEmotionTrigger = Instance.new("BindableEvent")
mowiEmotionTrigger.Name  = "MowiEmotionTrigger"
mowiEmotionTrigger.Parent = remotes

local function playServerEmotion(emotion)
    if emotion == "joy" then
        -- グローをパルス
        local tween = TweenService:Create(worldMowi.glow, TweenInfo.new(0.3), { Brightness = 3.0 })
        tween:Play()
        tween.Completed:Connect(function()
            TweenService:Create(worldMowi.glow, TweenInfo.new(0.5), { Brightness = 0.8 }):Play()
        end)
        -- パーティクル一時ON
        worldMowi.particles.Enabled = true
        task.delay(1.5, function() worldMowi.particles.Enabled = false end)

    elseif emotion == "sad" then
        TweenService:Create(worldMowi.glow, TweenInfo.new(0.3), { Brightness = 0.2 }):Play()
        task.delay(2, function()
            TweenService:Create(worldMowi.glow, TweenInfo.new(0.5), { Brightness = 0.5 }):Play()
        end)

    elseif emotion == "grow" then
        -- 全リングを一瞬高速回転
        ringSpeeds = { 180, -180, 120 }
        worldMowi.particles.Enabled = true
        TweenService:Create(worldMowi.glow, TweenInfo.new(0.5), { Brightness = 3.0 }):Play()
        task.delay(2.5, function()
            ringSpeeds = { 30, -40, 25 }
            worldMowi.particles.Enabled = false
        end)
    end
end

mowiEmotionTrigger.Event:Connect(function(emotion)
    playServerEmotion(emotion)
    -- クライアントにも通知（UI演出はクライアント側）
    for _, p in ipairs(game.Players:GetPlayers()) do
        mowiEmotion:FireClient(p, emotion)
    end
end)

------------------------------------------------------------------------
-- MowiSyncData BindableEvent（HeartbeatLoop から発火される）
------------------------------------------------------------------------
local mowiSyncData = Instance.new("BindableEvent")
mowiSyncData.Name  = "MowiSyncData"
mowiSyncData.Parent = remotes

mowiSyncData.Event:Connect(function(brightnessLevel, growthStage)
    updateMowiState(brightnessLevel, growthStage)
end)

------------------------------------------------------------------------
-- Phase 0 互換：プレイヤー追従型 Mowi（各プレイヤーの肩に浮遊）
------------------------------------------------------------------------
local MOWI_CONFIG = {
    bodyRadius    = 1.5,
    ringRadii     = {2.5, 3.0, 3.5},
    ringThickness = 0.15,
    baseColor     = Color3.fromRGB(180, 140, 255),
    ringColors    = {
        Color3.fromRGB(255, 100, 150),
        Color3.fromRGB(100, 200, 255),
        Color3.fromRGB(150, 255, 150),
    },
    floatHeight   = 4,
    orbitOffset   = 3,
}

local mowiModels = {}

local function createMowi(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart  = character:WaitForChild("HumanoidRootPart")

    if mowiModels[player.UserId] then
        mowiModels[player.UserId]:Destroy()
    end

    local mowiModel = Instance.new("Model")
    mowiModel.Name  = "Mowi_" .. player.Name
    mowiModel.Parent = workspace

    local body = Instance.new("Part")
    body.Name      = "MowiBody"
    body.Shape     = Enum.PartType.Ball
    body.Size      = Vector3.new(MOWI_CONFIG.bodyRadius * 2, MOWI_CONFIG.bodyRadius * 2, MOWI_CONFIG.bodyRadius * 2)
    body.Material  = Enum.Material.Neon
    body.Color     = MOWI_CONFIG.baseColor
    body.CastShadow = false
    body.CanCollide = false
    body.Anchored  = true
    body.Parent    = mowiModel
    mowiModel.PrimaryPart = body

    for i, radius in ipairs(MOWI_CONFIG.ringRadii) do
        local ring = Instance.new("Part")
        ring.Name      = "MowiRing_" .. i
        ring.Shape     = Enum.PartType.Cylinder
        ring.Size      = Vector3.new(MOWI_CONFIG.ringThickness, radius * 2, radius * 2)
        ring.Material  = Enum.Material.Neon
        ring.Color     = MOWI_CONFIG.ringColors[i]
        ring.CastShadow = false
        ring.CanCollide = false
        ring.Anchored  = true
        ring.Parent    = mowiModel

        ring.CFrame = body.CFrame * CFrame.Angles(
            math.random() * math.pi,
            math.random() * math.pi,
            0
        )

        local rotSpeed = 0.5 + i * 0.3
        local rotAxis  = Vector3.new(
            math.sin(i * 1.2),
            math.cos(i * 0.8),
            math.sin(i * 0.5)
        ).Unit

        RunService.Heartbeat:Connect(function(dt)
            if ring and ring.Parent then
                ring.CFrame = ring.CFrame * CFrame.fromAxisAngle(rotAxis, rotSpeed * dt)
            end
        end)
    end

    local floatTime = 0
    RunService.Heartbeat:Connect(function(dt)
        if not (mowiModel and mowiModel.Parent and rootPart and rootPart.Parent) then return end
        floatTime = floatTime + dt
        local floatY  = math.sin(floatTime * 1.2) * 0.4
        local targetPos = rootPart.Position
            + Vector3.new(MOWI_CONFIG.orbitOffset, MOWI_CONFIG.floatHeight + floatY, 0)
        body.CFrame = body.CFrame:Lerp(CFrame.new(targetPos), dt * 3)
        for i = 1, 3 do
            local ring = mowiModel:FindFirstChild("MowiRing_" .. i)
            if ring then ring.Position = body.Position end
        end
    end)

    mowiModels[player.UserId] = mowiModel
    print("[MoWISE] Mowi spawned for " .. player.Name)
    return mowiModel
end

------------------------------------------------------------------------
-- プレイヤー追従 Mowi リアクション演出
------------------------------------------------------------------------
local function reactCorrect(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end
    local origColor = body.Color
    TweenService:Create(body, TweenInfo.new(0.15), {
        Color = Color3.fromRGB(255, 230, 100),
        Size  = Vector3.new(4, 4, 4),
    }):Play()
    task.wait(0.2)
    TweenService:Create(body, TweenInfo.new(0.4, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
        Color = origColor,
        Size  = Vector3.new(MOWI_CONFIG.bodyRadius * 2, MOWI_CONFIG.bodyRadius * 2, MOWI_CONFIG.bodyRadius * 2),
    }):Play()
    local origPos = body.Position
    TweenService:Create(body, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(origPos + Vector3.new(0, 3, 0)),
    }):Play()
    task.wait(0.2)
    TweenService:Create(body, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(origPos),
    }):Play()
    for i = 1, 3 do
        local ring = mowi:FindFirstChild("MowiRing_" .. i)
        if ring then
            local origSize = ring.Size
            TweenService:Create(ring, TweenInfo.new(0.15), {
                Size = origSize + Vector3.new(0, 1, 1),
            }):Play()
            task.delay(0.15, function()
                if ring and ring.Parent then
                    TweenService:Create(ring, TweenInfo.new(0.3, Enum.EasingStyle.Bounce), {
                        Size = origSize,
                    }):Play()
                end
            end)
        end
    end
end

local function reactIncorrect(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end
    local origColor = body.Color
    local origPos = body.Position
    TweenService:Create(body, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(100, 80, 160),
    }):Play()
    TweenService:Create(body, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        CFrame = CFrame.new(origPos + Vector3.new(0, -1, 0)),
    }):Play()
    task.wait(0.6)
    TweenService:Create(body, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Color = origColor,
        CFrame = CFrame.new(origPos),
    }):Play()
end

local function reactClearance(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end
    local origColor = body.Color
    for _ = 1, 3 do
        TweenService:Create(body, TweenInfo.new(0.1), {
            Color = Color3.fromRGB(200, 255, 200),
        }):Play()
        task.wait(0.15)
        TweenService:Create(body, TweenInfo.new(0.1), {
            Color = origColor,
        }):Play()
        task.wait(0.15)
    end
end

local function reactSessionStart(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end
    local origSize = body.Size
    TweenService:Create(body, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = origSize * 1.15,
    }):Play()
    task.wait(0.2)
    TweenService:Create(body, TweenInfo.new(0.2), {
        Size = origSize,
    }):Play()
end

------------------------------------------------------------------------
-- MowiReaction BindableEvent（プレイヤー追従 Mowi 用）
------------------------------------------------------------------------
local mowiReaction = Instance.new("BindableEvent", remotes)
mowiReaction.Name  = "MowiReaction"

mowiReaction.Event:Connect(function(player, reaction)
    local mowi = mowiModels[player.UserId]
    if not mowi or not mowi.Parent then return end

    if reaction == "correct" then
        task.spawn(reactCorrect, mowi)
    elseif reaction == "incorrect" then
        task.spawn(reactIncorrect, mowi)
    elseif reaction == "clearance" then
        task.spawn(reactClearance, mowi)
    elseif reaction == "session_start" then
        task.spawn(reactSessionStart, mowi)
    end
end)

------------------------------------------------------------------------
-- プレイヤー参加/退出
------------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        createMowi(player)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    local mowi = mowiModels[player.UserId]
    if mowi then mowi:Destroy() end
    mowiModels[player.UserId] = nil
end)

print("[MoWISE] MowiSpawner ready (World Mowi + Player Mowi)")
