-- MowiSpawner.server.lua
-- Phase 0: Mowiの仮モデルを生成（球体 + 3リング）
-- Phase 1: リアクション演出（正解/不正解/整地/セッション開始）

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

-- プレイヤーごとの Mowi モデル参照
local mowiModels = {}

------------------------------------------------------------------------
-- Mowi 生成
------------------------------------------------------------------------
local function createMowi(player)
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart  = character:WaitForChild("HumanoidRootPart")

    -- 既存があれば削除
    if mowiModels[player.UserId] then
        mowiModels[player.UserId]:Destroy()
    end

    local mowiModel = Instance.new("Model")
    mowiModel.Name  = "Mowi_" .. player.Name
    mowiModel.Parent = workspace

    -- 球体（本体）
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

    -- 3リング
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

    -- プレイヤー追従
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
-- Mowi リアクション演出
------------------------------------------------------------------------

-- 喜び：ジャンプ + 明るくなる + リング加速
local function reactCorrect(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end

    -- 明るい黄金色にフラッシュ
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

    -- ジャンプ（上に跳ねて戻る）
    local origPos = body.Position
    TweenService:Create(body, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(origPos + Vector3.new(0, 3, 0)),
    }):Play()
    task.wait(0.2)
    TweenService:Create(body, TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
        CFrame = CFrame.new(origPos),
    }):Play()

    -- リングを一瞬大きく
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

-- 残念：少し沈む + 暗くなる
local function reactIncorrect(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end

    local origColor = body.Color
    local origPos = body.Position

    -- 暗めの青紫に
    TweenService:Create(body, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(100, 80, 160),
    }):Play()
    -- 少し下がる
    TweenService:Create(body, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        CFrame = CFrame.new(origPos + Vector3.new(0, -1, 0)),
    }):Play()
    task.wait(0.6)
    -- 元に戻る
    TweenService:Create(body, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Color = origColor,
        CFrame = CFrame.new(origPos),
    }):Play()
end

-- 整地リアクション：廃墟の方向を向いてキラキラ
local function reactClearance(mowi)
    local body = mowi:FindFirstChild("MowiBody")
    if not body then return end

    -- 回転しながら光る
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

-- セッション開始：身構え（少し大きくなる）
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
-- MowiReaction BindableEvent
------------------------------------------------------------------------
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes", 30)

if remotes then
    local mowiReaction = Instance.new("BindableEvent", remotes)
    mowiReaction.Name  = "MowiReaction"

    -- reaction: "correct", "incorrect", "clearance", "session_start"
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

    print("[MoWISE] MowiReaction BindableEvent ready")
end

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
