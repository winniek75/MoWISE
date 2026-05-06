-- WorldDecorations.server.lua
-- ワールド装飾: Zone1「はじまりの森」/ Zone2「マーケット通り」
-- WorldSetup の後に実行される。既存パーツがあればスキップ。

local Workspace  = game:GetService("Workspace")
local Lighting   = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

-- 装飾フォルダ
local function getFolder(name)
    local f = Workspace:FindFirstChild(name)
    if not f then
        f = Instance.new("Folder")
        f.Name   = name
        f.Parent = Workspace
    end
    return f
end

------------------------------------------------------------------------
-- ヘルパー: 木を生成
------------------------------------------------------------------------
local function createTree(parent, pos, scale, treeType)
    scale = scale or 1
    treeType = treeType or "oak"

    local trunk = Instance.new("Part")
    trunk.Name      = "Trunk"
    trunk.Shape     = Enum.PartType.Cylinder
    trunk.Anchored  = true
    trunk.CanCollide = true
    trunk.Material  = Enum.Material.Wood
    trunk.Color     = Color3.fromRGB(110, 70, 35)
    trunk.CFrame    = CFrame.new(pos + Vector3.new(0, 3 * scale, 0))
                      * CFrame.Angles(0, 0, math.rad(90))
    trunk.Size      = Vector3.new(6 * scale, 0.8 * scale, 0.8 * scale)
    trunk.Parent    = parent

    if treeType == "oak" then
        -- 丸い葉（球体3つ重ねて自然に）
        local leafPositions = {
            Vector3.new(0, 6.5 * scale, 0),
            Vector3.new(0.8 * scale, 5.5 * scale, 0.6 * scale),
            Vector3.new(-0.6 * scale, 5.8 * scale, -0.5 * scale),
        }
        for i, lp in ipairs(leafPositions) do
            local leaf = Instance.new("Part")
            leaf.Name      = "Leaves_" .. i
            leaf.Shape     = Enum.PartType.Ball
            leaf.Anchored  = true
            leaf.CanCollide = false
            leaf.Material  = Enum.Material.Grass
            leaf.Color     = Color3.fromRGB(
                40 + math.random(0, 30),
                120 + math.random(0, 40),
                30 + math.random(0, 20)
            )
            leaf.Size      = Vector3.new(1, 1, 1) * (3.5 + math.random() * 1.5) * scale
            leaf.Position  = pos + lp
            leaf.Parent    = parent
        end
    elseif treeType == "pine" then
        -- 針葉樹: コーン3段
        for i = 1, 3 do
            local cone = Instance.new("Part")
            cone.Name      = "Pine_" .. i
            cone.Anchored  = true
            cone.CanCollide = false
            cone.Material  = Enum.Material.Grass
            cone.Color     = Color3.fromRGB(20 + i * 10, 80 + i * 15, 25)
            local s = (4 - i) * 1.2 * scale
            cone.Size      = Vector3.new(s, 2 * scale, s)
            cone.Position  = pos + Vector3.new(0, 3.5 * scale + (i - 1) * 1.6 * scale, 0)
            cone.Parent    = parent
        end
    elseif treeType == "cherry" then
        -- 桜の木: ピンクの葉
        local leafPositions = {
            Vector3.new(0, 6.5 * scale, 0),
            Vector3.new(1 * scale, 5.5 * scale, 0.8 * scale),
            Vector3.new(-0.8 * scale, 6 * scale, -0.6 * scale),
        }
        for i, lp in ipairs(leafPositions) do
            local leaf = Instance.new("Part")
            leaf.Name      = "CherryLeaves_" .. i
            leaf.Shape     = Enum.PartType.Ball
            leaf.Anchored  = true
            leaf.CanCollide = false
            leaf.Material  = Enum.Material.Grass
            leaf.Color     = Color3.fromRGB(
                255,
                140 + math.random(0, 40),
                160 + math.random(0, 40)
            )
            leaf.Size      = Vector3.new(1, 1, 1) * (3 + math.random() * 1.5) * scale
            leaf.Position  = pos + lp
            leaf.Parent    = parent

            -- 花びらパーティクル
            if i == 1 then
                local emitter = Instance.new("ParticleEmitter")
                emitter.Rate         = 3
                emitter.Lifetime     = NumberRange.new(3, 6)
                emitter.Speed        = NumberRange.new(0.5, 2)
                emitter.SpreadAngle  = Vector2.new(180, 180)
                emitter.Size         = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.2),
                    NumberSequenceKeypoint.new(1, 0.1),
                })
                emitter.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(0.8, 0.3),
                    NumberSequenceKeypoint.new(1, 1),
                })
                emitter.Color        = ColorSequence.new(Color3.fromRGB(255, 180, 200))
                emitter.RotSpeed     = NumberRange.new(-60, 60)
                emitter.Parent       = leaf
            end
        end
    end
end

------------------------------------------------------------------------
-- ヘルパー: 街灯
------------------------------------------------------------------------
local function createLamp(parent, pos, lampStyle)
    lampStyle = lampStyle or "wood"

    local pole = Instance.new("Part")
    pole.Name      = "LampPole"
    pole.Anchored  = true
    pole.CanCollide = true
    pole.Size      = Vector3.new(0.3, 6, 0.3)
    pole.Position  = pos + Vector3.new(0, 3, 0)
    pole.Parent    = parent

    if lampStyle == "wood" then
        pole.Material = Enum.Material.Wood
        pole.Color    = Color3.fromRGB(90, 60, 30)
    else
        pole.Material = Enum.Material.Metal
        pole.Color    = Color3.fromRGB(50, 50, 55)
    end

    local lamp = Instance.new("Part")
    lamp.Name      = "LampHead"
    lamp.Shape     = Enum.PartType.Ball
    lamp.Anchored  = true
    lamp.CanCollide = false
    lamp.Size      = Vector3.new(1.5, 1.5, 1.5)
    lamp.Position  = pos + Vector3.new(0, 6.5, 0)
    lamp.Material  = Enum.Material.Neon
    lamp.Color     = Color3.fromRGB(255, 220, 130)
    lamp.Parent    = parent

    local light = Instance.new("PointLight")
    light.Brightness = 1.5
    light.Range      = 25
    light.Color      = Color3.fromRGB(255, 230, 160)
    light.Parent     = lamp
end

------------------------------------------------------------------------
-- ヘルパー: 道（PathSegment）
------------------------------------------------------------------------
local function createPath(parent, from, to, width)
    width = width or 4
    local mid = (from + to) / 2
    local diff = to - from
    local length = diff.Magnitude
    local angle  = math.atan2(diff.X, diff.Z)

    local path = Instance.new("Part")
    path.Name      = "PathSegment"
    path.Anchored  = true
    path.CanCollide = true
    path.Material  = Enum.Material.Cobblestone
    path.Color     = Color3.fromRGB(140, 130, 115)
    path.Size      = Vector3.new(width, 0.15, length)
    path.CFrame    = CFrame.new(mid + Vector3.new(0, 0.08, 0))
                     * CFrame.Angles(0, angle, 0)
    path.Parent    = parent
end

------------------------------------------------------------------------
-- ヘルパー: 花
------------------------------------------------------------------------
local function createFlowerPatch(parent, center, count, radius)
    count  = count or 6
    radius = radius or 3
    local colors = {
        Color3.fromRGB(255, 100, 120), -- 赤
        Color3.fromRGB(255, 200, 80),  -- 黄
        Color3.fromRGB(180, 100, 255), -- 紫
        Color3.fromRGB(255, 150, 200), -- ピンク
        Color3.fromRGB(100, 180, 255), -- 青
        Color3.fromRGB(255, 255, 150), -- 白黄
    }
    for _ = 1, count do
        local offset = Vector3.new(
            (math.random() - 0.5) * radius * 2,
            0.3,
            (math.random() - 0.5) * radius * 2
        )
        local flower = Instance.new("Part")
        flower.Name      = "Flower"
        flower.Shape     = Enum.PartType.Ball
        flower.Anchored  = true
        flower.CanCollide = false
        flower.Size      = Vector3.new(0.5, 0.5, 0.5) * (0.8 + math.random() * 0.4)
        flower.Position  = center + offset
        flower.Material  = Enum.Material.Neon
        flower.Color     = colors[math.random(1, #colors)]
        flower.Parent    = parent

        -- 茎
        local stem = Instance.new("Part")
        stem.Name      = "Stem"
        stem.Anchored  = true
        stem.CanCollide = false
        stem.Size      = Vector3.new(0.1, 0.3, 0.1)
        stem.Position  = flower.Position - Vector3.new(0, 0.25, 0)
        stem.Material  = Enum.Material.Grass
        stem.Color     = Color3.fromRGB(60, 140, 40)
        stem.Parent    = parent
    end
end

------------------------------------------------------------------------
-- ヘルパー: ベンチ
------------------------------------------------------------------------
local function createBench(parent, pos, rotation)
    rotation = rotation or 0
    local seat = Instance.new("Part")
    seat.Name      = "BenchSeat"
    seat.Anchored  = true
    seat.CanCollide = true
    seat.Material  = Enum.Material.Wood
    seat.Color     = Color3.fromRGB(130, 85, 45)
    seat.Size      = Vector3.new(3, 0.25, 1)
    seat.CFrame    = CFrame.new(pos + Vector3.new(0, 0.8, 0))
                     * CFrame.Angles(0, math.rad(rotation), 0)
    seat.Parent    = parent

    -- 脚（2本）
    for _, xOff in ipairs({-1.2, 1.2}) do
        local leg = Instance.new("Part")
        leg.Name      = "BenchLeg"
        leg.Anchored  = true
        leg.CanCollide = true
        leg.Material  = Enum.Material.Wood
        leg.Color     = Color3.fromRGB(100, 65, 30)
        leg.Size      = Vector3.new(0.2, 0.8, 0.8)
        leg.CFrame    = seat.CFrame * CFrame.new(xOff, -0.5, 0)
        leg.Parent    = parent
    end

    -- 背もたれ
    local back = Instance.new("Part")
    back.Name      = "BenchBack"
    back.Anchored  = true
    back.CanCollide = false
    back.Material  = Enum.Material.Wood
    back.Color     = Color3.fromRGB(130, 85, 45)
    back.Size      = Vector3.new(3, 1, 0.15)
    back.CFrame    = seat.CFrame * CFrame.new(0, 0.6, -0.4)
    back.Parent    = parent
end

------------------------------------------------------------------------
-- ヘルパー: 噴水
------------------------------------------------------------------------
local function createFountain(parent, pos)
    -- 土台
    local base = Instance.new("Part")
    base.Name      = "FountainBase"
    base.Shape     = Enum.PartType.Cylinder
    base.Anchored  = true
    base.Material  = Enum.Material.Marble
    base.Color     = Color3.fromRGB(200, 195, 185)
    base.Size      = Vector3.new(1, 8, 8)
    base.CFrame    = CFrame.new(pos + Vector3.new(0, 0.5, 0))
                     * CFrame.Angles(0, 0, math.rad(90))
    base.Parent    = parent

    -- 内側の水
    local water = Instance.new("Part")
    water.Name      = "FountainWater"
    water.Shape     = Enum.PartType.Cylinder
    water.Anchored  = true
    water.CanCollide = false
    water.Material  = Enum.Material.Glass
    water.Color     = Color3.fromRGB(80, 160, 220)
    water.Transparency = 0.3
    water.Size      = Vector3.new(0.3, 7, 7)
    water.CFrame    = CFrame.new(pos + Vector3.new(0, 0.7, 0))
                      * CFrame.Angles(0, 0, math.rad(90))
    water.Parent    = parent

    -- 中央の柱
    local pillar = Instance.new("Part")
    pillar.Name      = "FountainPillar"
    pillar.Shape     = Enum.PartType.Cylinder
    pillar.Anchored  = true
    pillar.Material  = Enum.Material.Marble
    pillar.Color     = Color3.fromRGB(210, 205, 195)
    pillar.Size      = Vector3.new(4, 0.8, 0.8)
    pillar.CFrame    = CFrame.new(pos + Vector3.new(0, 2, 0))
                       * CFrame.Angles(0, 0, math.rad(90))
    pillar.Parent    = parent

    -- 水しぶきパーティクル
    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate         = 15
    emitter.Lifetime     = NumberRange.new(0.5, 1.5)
    emitter.Speed        = NumberRange.new(3, 6)
    emitter.SpreadAngle  = Vector2.new(30, 30)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.15),
        NumberSequenceKeypoint.new(0.5, 0.25),
        NumberSequenceKeypoint.new(1, 0.05),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.4),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Color        = ColorSequence.new(Color3.fromRGB(180, 220, 255))
    emitter.LightEmission = 0.3
    emitter.Parent       = pillar

    -- 環境光
    local light = Instance.new("PointLight")
    light.Brightness = 0.5
    light.Range      = 15
    light.Color      = Color3.fromRGB(150, 200, 255)
    light.Parent     = water
end

------------------------------------------------------------------------
-- ヘルパー: マーケット屋台
------------------------------------------------------------------------
local function createMarketStall(parent, pos, rotation, stallName, roofColor)
    rotation  = rotation or 0
    roofColor = roofColor or Color3.fromRGB(180, 50, 50)

    -- カウンター
    local counter = Instance.new("Part")
    counter.Name      = "StallCounter"
    counter.Anchored  = true
    counter.Material  = Enum.Material.Wood
    counter.Color     = Color3.fromRGB(140, 95, 50)
    counter.Size      = Vector3.new(5, 1.2, 2)
    counter.CFrame    = CFrame.new(pos + Vector3.new(0, 0.6, 0))
                        * CFrame.Angles(0, math.rad(rotation), 0)
    counter.Parent    = parent

    -- 柱（4本）
    local pillarPositions = {
        CFrame.new(-2.2, 2.5, -0.8),
        CFrame.new( 2.2, 2.5, -0.8),
        CFrame.new(-2.2, 2.5,  0.8),
        CFrame.new( 2.2, 2.5,  0.8),
    }
    for i, cf in ipairs(pillarPositions) do
        local pillar = Instance.new("Part")
        pillar.Name      = "Pillar_" .. i
        pillar.Anchored  = true
        pillar.Material  = Enum.Material.Wood
        pillar.Color     = Color3.fromRGB(100, 65, 30)
        pillar.Size      = Vector3.new(0.3, 3.8, 0.3)
        pillar.CFrame    = counter.CFrame * cf
        pillar.Parent    = parent
    end

    -- 屋根
    local roof = Instance.new("Part")
    roof.Name      = "StallRoof"
    roof.Anchored  = true
    roof.Material  = Enum.Material.Fabric
    roof.Color     = roofColor
    roof.Size      = Vector3.new(6, 0.2, 3)
    roof.CFrame    = counter.CFrame * CFrame.new(0, 4.2, 0)
    roof.Parent    = parent

    -- 看板
    local sign = Instance.new("Part")
    sign.Name      = "StallSign"
    sign.Anchored  = true
    sign.Material  = Enum.Material.Wood
    sign.Color     = Color3.fromRGB(160, 110, 60)
    sign.Size      = Vector3.new(3, 0.8, 0.15)
    sign.CFrame    = counter.CFrame * CFrame.new(0, 3.2, -1.1)
    sign.Parent    = parent

    local gui = Instance.new("SurfaceGui", sign)
    gui.Face = Enum.NormalId.Back
    local label = Instance.new("TextLabel", gui)
    label.Size       = UDim2.new(1, 0, 1, 0)
    label.Text       = stallName or "Shop"
    label.TextScaled = true
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 240, 200)
    label.Font       = Enum.Font.GothamBold
end

------------------------------------------------------------------------
-- ヘルパー: アーチ門
------------------------------------------------------------------------
local function createArch(parent, pos, rotation, text)
    rotation = rotation or 0
    local cf = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotation), 0)

    -- 左柱
    local left = Instance.new("Part")
    left.Anchored = true
    left.Material = Enum.Material.Cobblestone
    left.Color    = Color3.fromRGB(140, 130, 115)
    left.Size     = Vector3.new(1.5, 8, 1.5)
    left.CFrame   = cf * CFrame.new(-4, 4, 0)
    left.Parent   = parent

    -- 右柱
    local right = Instance.new("Part")
    right.Anchored = true
    right.Material = Enum.Material.Cobblestone
    right.Color    = Color3.fromRGB(140, 130, 115)
    right.Size     = Vector3.new(1.5, 8, 1.5)
    right.CFrame   = cf * CFrame.new(4, 4, 0)
    right.Parent   = parent

    -- 横梁
    local beam = Instance.new("Part")
    beam.Anchored = true
    beam.Material = Enum.Material.Wood
    beam.Color    = Color3.fromRGB(120, 80, 40)
    beam.Size     = Vector3.new(10, 1, 1.5)
    beam.CFrame   = cf * CFrame.new(0, 8.5, 0)
    beam.Parent   = parent

    -- テキスト看板
    if text then
        local sign = Instance.new("Part")
        sign.Anchored = true
        sign.Material = Enum.Material.Wood
        sign.Color    = Color3.fromRGB(100, 65, 30)
        sign.Size     = Vector3.new(6, 1.5, 0.2)
        sign.CFrame   = cf * CFrame.new(0, 9.8, 0)
        sign.Parent   = parent

        local gui = Instance.new("SurfaceGui", sign)
        gui.Face = Enum.NormalId.Front
        local label = Instance.new("TextLabel", gui)
        label.Size       = UDim2.new(1, 0, 1, 0)
        label.Text       = text
        label.TextScaled = true
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 230, 170)
        label.Font       = Enum.Font.GothamBold

        -- 裏面にも同じテキスト
        local gui2 = Instance.new("SurfaceGui", sign)
        gui2.Face = Enum.NormalId.Back
        local label2 = Instance.new("TextLabel", gui2)
        label2.Size       = UDim2.new(1, 0, 1, 0)
        label2.Text       = text
        label2.TextScaled = true
        label2.BackgroundTransparency = 1
        label2.TextColor3 = Color3.fromRGB(255, 230, 170)
        label2.Font       = Enum.Font.GothamBold
    end
end

------------------------------------------------------------------------
-- ヘルパー: 池
------------------------------------------------------------------------
local function createPond(parent, pos, radius)
    radius = radius or 8
    local water = Instance.new("Part")
    water.Name      = "Pond"
    water.Shape     = Enum.PartType.Cylinder
    water.Anchored  = true
    water.CanCollide = false
    water.Material  = Enum.Material.Glass
    water.Color     = Color3.fromRGB(60, 130, 200)
    water.Transparency = 0.35
    water.Size      = Vector3.new(0.4, radius * 2, radius * 2)
    water.CFrame    = CFrame.new(pos + Vector3.new(0, -0.1, 0))
                      * CFrame.Angles(0, 0, math.rad(90))
    water.Parent    = parent

    -- 水面のキラキラ
    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate         = 5
    emitter.Lifetime     = NumberRange.new(1, 3)
    emitter.Speed        = NumberRange.new(0.1, 0.5)
    emitter.SpreadAngle  = Vector2.new(180, 180)
    emitter.Size         = NumberSequence.new(0.15)
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Color        = ColorSequence.new(Color3.fromRGB(200, 230, 255))
    emitter.LightEmission = 1
    emitter.Parent       = water

    -- 周囲の石
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2 + math.random() * 0.3
        local dist  = radius + 0.5 + math.random() * 0.5
        local rock = Instance.new("Part")
        rock.Name      = "PondRock_" .. i
        rock.Anchored  = true
        rock.CanCollide = true
        rock.Material  = Enum.Material.Slate
        rock.Color     = Color3.fromRGB(100 + math.random(0, 30), 95 + math.random(0, 20), 90)
        local s = 0.6 + math.random() * 0.8
        rock.Size      = Vector3.new(s, s * 0.6, s)
        rock.Position  = pos + Vector3.new(math.cos(angle) * dist, 0.2, math.sin(angle) * dist)
        rock.Parent    = parent
    end
end

------------------------------------------------------------------------
-- ヘルパー: 蛍パーティクル（夜間雰囲気）
------------------------------------------------------------------------
local function createFireflies(parent, pos, radius)
    radius = radius or 20
    local anchor = Instance.new("Part")
    anchor.Name        = "FireflyAnchor"
    anchor.Anchored    = true
    anchor.CanCollide  = false
    anchor.Transparency = 1
    anchor.Size        = Vector3.new(1, 1, 1)
    anchor.Position    = pos + Vector3.new(0, 3, 0)
    anchor.Parent      = parent

    local emitter = Instance.new("ParticleEmitter")
    emitter.Rate         = 8
    emitter.Lifetime     = NumberRange.new(3, 7)
    emitter.Speed        = NumberRange.new(0.3, 1.5)
    emitter.SpreadAngle  = Vector2.new(180, 180)
    emitter.Size         = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.2, 0.2),
        NumberSequenceKeypoint.new(0.8, 0.15),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.15, 0),
        NumberSequenceKeypoint.new(0.85, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Color        = ColorSequence.new(
        Color3.fromRGB(180, 255, 100),
        Color3.fromRGB(255, 255, 80)
    )
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.Parent       = anchor
end

------------------------------------------------------------------------
-- ============================================================
-- Zone 1: はじまりの森
-- ============================================================
------------------------------------------------------------------------
local function decorateZone1()
    if Workspace:FindFirstChild("Zone1Decorations") then
        print("[MoWISE] Zone1Decorations already exists, skipping")
        return
    end

    local folder = getFolder("Zone1Decorations")

    -- === 木 ===
    local trees = {
        -- メインエリア周囲の森
        { pos = Vector3.new(-50, 0,  -40), scale = 1.2, type = "oak" },
        { pos = Vector3.new(-55, 0,  -20), scale = 1.0, type = "pine" },
        { pos = Vector3.new(-60, 0,    5), scale = 1.3, type = "oak" },
        { pos = Vector3.new(-45, 0,   35), scale = 0.9, type = "pine" },
        { pos = Vector3.new(-55, 0,   55), scale = 1.1, type = "oak" },
        { pos = Vector3.new(-30, 0,  -55), scale = 1.0, type = "oak" },
        { pos = Vector3.new(-15, 0,  -60), scale = 0.8, type = "pine" },
        { pos = Vector3.new( 10, 0,  -55), scale = 1.2, type = "oak" },
        { pos = Vector3.new( 40, 0,  -50), scale = 1.0, type = "pine" },
        { pos = Vector3.new( 55, 0,  -35), scale = 1.1, type = "oak" },
        { pos = Vector3.new( 60, 0,  -10), scale = 0.9, type = "pine" },
        { pos = Vector3.new( 55, 0,   20), scale = 1.2, type = "oak" },
        { pos = Vector3.new( 50, 0,   50), scale = 1.0, type = "oak" },
        { pos = Vector3.new( 30, 0,   60), scale = 0.8, type = "pine" },
        { pos = Vector3.new(-10, 0,   65), scale = 1.1, type = "oak" },
        { pos = Vector3.new(-40, 0,   60), scale = 1.0, type = "pine" },
        -- スポーン付近の桜
        { pos = Vector3.new(-5, 0,   -8), scale = 1.0, type = "cherry" },
        { pos = Vector3.new( 8, 0,   -5), scale = 0.8, type = "cherry" },
        -- 散在する木
        { pos = Vector3.new( 35, 0,  -20), scale = 0.7, type = "pine" },
        { pos = Vector3.new(-30, 0,   20), scale = 1.0, type = "oak" },
        { pos = Vector3.new( 15, 0,   40), scale = 0.9, type = "oak" },
        { pos = Vector3.new(-20, 0,  -30), scale = 0.8, type = "pine" },
    }
    for _, t in ipairs(trees) do
        createTree(folder, t.pos, t.scale, t.type)
    end

    -- === 池 ===
    createPond(folder, Vector3.new(-30, 0, 40), 6)

    -- === 花畑 ===
    createFlowerPatch(folder, Vector3.new(10, 0, 68), 10, 5)
    createFlowerPatch(folder, Vector3.new(-35, 0, 55), 8, 4)
    createFlowerPatch(folder, Vector3.new(45, 0, -45), 6, 3)
    createFlowerPatch(folder, Vector3.new(-5, 0, -5), 5, 2) -- スポーン周辺

    -- === 小道 ===
    -- スポーン → Flash Output
    createPath(folder, Vector3.new(0, 0, 0), Vector3.new(0, 0, -5), 3)
    -- スポーン → ワークベンチ
    createPath(folder, Vector3.new(0, 0, 0), Vector3.new(20, 0, 20), 3)
    -- スポーン → 池方向
    createPath(folder, Vector3.new(0, 0, 0), Vector3.new(-20, 0, 30), 3)
    createPath(folder, Vector3.new(-20, 0, 30), Vector3.new(-30, 0, 40), 3)
    -- Zone 2 方向への道
    createPath(folder, Vector3.new(0, 0, 0), Vector3.new(0, 0, 60), 3)
    createPath(folder, Vector3.new(0, 0, 60), Vector3.new(0, 0, 90), 3)

    -- === 街灯 ===
    createLamp(folder, Vector3.new(-6, 0, 15), "wood")
    createLamp(folder, Vector3.new( 6, 0, 15), "wood")
    createLamp(folder, Vector3.new(-6, 0, 45), "wood")
    createLamp(folder, Vector3.new( 6, 0, 45), "wood")
    createLamp(folder, Vector3.new( 25, 0, 18), "wood") -- ワークベンチ付近

    -- === ベンチ ===
    createBench(folder, Vector3.new(-33, 0, 35), 30)   -- 池の近く
    createBench(folder, Vector3.new(8, 0, 5), 0)        -- スポーン付近

    -- === 蛍 ===
    createFireflies(folder, Vector3.new(-30, 0, 40))  -- 池周辺
    createFireflies(folder, Vector3.new(0, 0, 30))     -- メイン通り

    -- === スポーン広場の装飾 ===
    -- 中央に Mowi の像台座
    local pedestal = Instance.new("Part")
    pedestal.Name      = "MowiPedestal"
    pedestal.Anchored  = true
    pedestal.Material  = Enum.Material.Marble
    pedestal.Color     = Color3.fromRGB(220, 215, 205)
    pedestal.Size      = Vector3.new(3, 0.6, 3)
    pedestal.Position  = Vector3.new(0, 0.3, -2)
    pedestal.Parent    = folder
    Instance.new("UICorner", pedestal)  -- 角丸は Part には使えないが害はない

    -- === Zone1 入口アーチ ===
    createArch(folder, Vector3.new(0, 0, -15), 0, "はじまりの森")

    print("[MoWISE] Zone 1 decorations placed (trees, pond, paths, lamps, flowers)")
end

------------------------------------------------------------------------
-- ============================================================
-- Zone 2: マーケット通り
-- ============================================================
------------------------------------------------------------------------
local function decorateZone2()
    if Workspace:FindFirstChild("Zone2Decorations") then
        print("[MoWISE] Zone2Decorations already exists, skipping")
        return
    end

    local folder = getFolder("Zone2Decorations")
    local Z2 = Vector3.new(0, 0, 300) -- Zone2中心

    -- === Zone2 入口アーチ ===
    createArch(folder, Z2 + Vector3.new(0, 0, -90), 0, "マーケット通り")

    -- === 中央噴水 ===
    createFountain(folder, Z2)

    -- === メインストリート ===
    createPath(folder, Z2 + Vector3.new(0, 0, -90), Z2 + Vector3.new(0, 0, -40), 5)
    createPath(folder, Z2 + Vector3.new(0, 0, -40), Z2 + Vector3.new(0, 0, 0), 5)
    createPath(folder, Z2 + Vector3.new(0, 0, 0),  Z2 + Vector3.new(0, 0, 50), 5)
    -- 横道
    createPath(folder, Z2 + Vector3.new(0, 0, 0), Z2 + Vector3.new(-40, 0, 0), 4)
    createPath(folder, Z2 + Vector3.new(0, 0, 0), Z2 + Vector3.new(40, 0, 0), 4)

    -- === マーケット屋台 ===
    createMarketStall(folder, Z2 + Vector3.new(-20, 0, -30), 20,
        "Bakery", Color3.fromRGB(200, 140, 60))
    createMarketStall(folder, Z2 + Vector3.new( 20, 0, -30), -20,
        "Fruit Shop", Color3.fromRGB(60, 160, 80))
    createMarketStall(folder, Z2 + Vector3.new(-25, 0,  15), 0,
        "Books", Color3.fromRGB(60, 80, 180))
    createMarketStall(folder, Z2 + Vector3.new( 25, 0,  15), 0,
        "Clothes", Color3.fromRGB(180, 60, 120))
    createMarketStall(folder, Z2 + Vector3.new(-15, 0,  50), 10,
        "Tools", Color3.fromRGB(120, 100, 80))
    createMarketStall(folder, Z2 + Vector3.new( 15, 0,  50), -10,
        "Potions", Color3.fromRGB(130, 60, 180))

    -- === 街灯（金属製） ===
    local lampPositions = {
        Z2 + Vector3.new(-8, 0, -60),
        Z2 + Vector3.new( 8, 0, -60),
        Z2 + Vector3.new(-8, 0, -20),
        Z2 + Vector3.new( 8, 0, -20),
        Z2 + Vector3.new(-8, 0,  20),
        Z2 + Vector3.new( 8, 0,  20),
        Z2 + Vector3.new(-8, 0,  50),
        Z2 + Vector3.new( 8, 0,  50),
        Z2 + Vector3.new(-30, 0, 0),
        Z2 + Vector3.new( 30, 0, 0),
    }
    for _, p in ipairs(lampPositions) do
        createLamp(folder, p, "metal")
    end

    -- === ベンチ ===
    createBench(folder, Z2 + Vector3.new(-6, 0, 5), 90)
    createBench(folder, Z2 + Vector3.new( 6, 0, 5), -90)
    createBench(folder, Z2 + Vector3.new(-6, 0, -5), 90)
    createBench(folder, Z2 + Vector3.new( 6, 0, -5), -90)

    -- === 装飾の木 ===
    createTree(folder, Z2 + Vector3.new(-35, 0, -50), 0.8, "cherry")
    createTree(folder, Z2 + Vector3.new( 35, 0, -50), 0.8, "cherry")
    createTree(folder, Z2 + Vector3.new(-35, 0,  60), 0.9, "oak")
    createTree(folder, Z2 + Vector3.new( 35, 0,  60), 0.9, "oak")

    -- === 花壇 ===
    createFlowerPatch(folder, Z2 + Vector3.new(-12, 0, 0), 8, 3)
    createFlowerPatch(folder, Z2 + Vector3.new( 12, 0, 0), 8, 3)
    createFlowerPatch(folder, Z2 + Vector3.new(0, 0, -50), 6, 2)

    -- === Zone2 境界壁（低い石壁） ===
    for x = -90, 90, 10 do
        local wall = Instance.new("Part")
        wall.Name      = "BoundaryWall"
        wall.Anchored  = true
        wall.Material  = Enum.Material.Cobblestone
        wall.Color     = Color3.fromRGB(120, 115, 105)
        wall.Size      = Vector3.new(10, 2, 1)
        wall.Position  = Z2 + Vector3.new(x, 1, -98)
        wall.Parent    = folder
    end

    print("[MoWISE] Zone 2 decorations placed (fountain, stalls, lamps, arches)")
end

------------------------------------------------------------------------
-- ============================================================
-- Lighting 改善（時間帯演出）
-- ============================================================
------------------------------------------------------------------------
local function enhanceLighting()
    -- より温かみのある光に調整
    Lighting.ClockTime     = 10         -- 朝10時（明るめ）
    Lighting.Brightness    = 1.2
    Lighting.Ambient       = Color3.fromRGB(80, 80, 90)
    Lighting.OutdoorAmbient = Color3.fromRGB(100, 100, 110)
    Lighting.FogEnd        = 600
    Lighting.FogColor      = Color3.fromRGB(180, 190, 200)

    -- Atmosphere の調整
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        atmo.Density  = 0.2
        atmo.Offset   = 0.1
        atmo.Color    = Color3.fromRGB(200, 210, 220)
        atmo.Decay    = Color3.fromRGB(160, 170, 190)
        atmo.Glare    = 0
        atmo.Haze     = 2
    end

    -- SunRays がなければ追加
    if not Lighting:FindFirstChild("SunRays") then
        local sunRays = Instance.new("SunRaysEffect")
        sunRays.Intensity = 0.06
        sunRays.Spread    = 0.5
        sunRays.Parent    = Lighting
    end

    -- Bloom がなければ追加
    if not Lighting:FindFirstChild("Bloom") then
        local bloom = Instance.new("BloomEffect")
        bloom.Intensity = 0.2
        bloom.Size      = 20
        bloom.Threshold = 1.5
        bloom.Parent    = Lighting
    end

    -- ColorCorrection がなければ追加
    if not Lighting:FindFirstChild("ColorCorrection") then
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Saturation  = 0.15
        cc.Contrast    = 0.05
        cc.Brightness  = 0.02
        cc.Parent      = Lighting
    end

    print("[MoWISE] Enhanced lighting applied")
end

------------------------------------------------------------------------
-- Zone 1→2 をつなぐ道
------------------------------------------------------------------------
local function connectZones()
    if Workspace:FindFirstChild("ZoneConnector") then return end
    local folder = getFolder("ZoneConnector")

    -- Zone1 端 → Zone2 入口まで長い道
    local segments = {
        { Vector3.new(0, 0, 90),  Vector3.new(0, 0, 130) },
        { Vector3.new(0, 0, 130), Vector3.new(0, 0, 170) },
        { Vector3.new(0, 0, 170), Vector3.new(0, 0, 210) },
    }
    for _, seg in ipairs(segments) do
        createPath(folder, seg[1], seg[2], 4)
    end

    -- 道沿いの街灯
    createLamp(folder, Vector3.new(-5, 0, 110), "wood")
    createLamp(folder, Vector3.new( 5, 0, 150), "wood")
    createLamp(folder, Vector3.new(-5, 0, 190), "wood")

    -- 道沿いの木
    createTree(folder, Vector3.new(-12, 0, 120), 0.8, "pine")
    createTree(folder, Vector3.new( 12, 0, 140), 0.7, "oak")
    createTree(folder, Vector3.new(-10, 0, 170), 0.9, "pine")
    createTree(folder, Vector3.new( 10, 0, 200), 0.7, "oak")

    print("[MoWISE] Zone connector path placed")
end

------------------------------------------------------------------------
-- 実行
------------------------------------------------------------------------
-- WorldSetup の完了を待つ
task.wait(2)

enhanceLighting()
decorateZone1()
decorateZone2()
connectZones()

print("[MoWISE] === WorldDecorations complete ===")
