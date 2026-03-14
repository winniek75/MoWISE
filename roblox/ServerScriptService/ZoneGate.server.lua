-- ZoneGate.server.lua
-- Phase 7: Zone 1 ⇔ Zone 2 のワープゲート管理

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

-- クライアントへのゾーン移動通知
local zoneChanged = Instance.new("RemoteEvent", remotes)
zoneChanged.Name = "ZoneChanged"

------------------------------------------------------------------------
-- ゲート定義
-- Zone 1 北端 (0, 3, 110) → Zone 2 南端 (0, 3, 205)
-- Zone 2 南端 (0, 3, 205) → Zone 1 北端 (0, 3, 105)
------------------------------------------------------------------------
local GATES = {
    {
        name         = "Zone1ToZone2",
        position     = Vector3.new(0, 3, 112),
        size         = Vector3.new(12, 6, 2),
        destination  = Vector3.new(0, 3, 205),
        label        = "Zone 2 へ進む",
        toZone       = 2,
    },
    {
        name         = "Zone2ToZone1",
        position     = Vector3.new(0, 3, 203),
        size         = Vector3.new(12, 6, 2),
        destination  = Vector3.new(0, 3, 105),
        label        = "Zone 1 へ戻る",
        toZone       = 1,
    },
}

------------------------------------------------------------------------
-- ゲートパーツ生成
------------------------------------------------------------------------
local cooldowns = {}  -- { [userId] = tick() }

for _, gate in ipairs(GATES) do
    local part = Instance.new("Part")
    part.Name      = gate.name
    part.Size      = gate.size
    part.Position  = gate.position
    part.Anchored  = true
    part.CanCollide = false
    part.Transparency = 0.6
    part.Material  = Enum.Material.Neon
    part.Color     = gate.toZone == 2
                     and Color3.fromRGB(80, 180, 255)
                     or  Color3.fromRGB(255, 180, 80)
    part.Parent    = game.Workspace

    -- 看板
    local sg = Instance.new("SurfaceGui", part)
    sg.Face = Enum.NormalId.Front
    local lbl = Instance.new("TextLabel", sg)
    lbl.Size       = UDim2.new(1, 0, 1, 0)
    lbl.Text       = gate.label
    lbl.TextScaled = true
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font       = Enum.Font.GothamBold

    -- タッチでワープ
    local dest = gate.destination
    local toZone = gate.toZone
    part.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then return end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- 連続発火防止（0.5秒クールダウン）
        local uid = player.UserId
        if cooldowns[uid] and (tick() - cooldowns[uid]) < 0.5 then return end
        cooldowns[uid] = tick()

        hrp.CFrame = CFrame.new(dest)

        -- クライアントにゾーン変更を通知（UI更新用）
        zoneChanged:FireClient(player, toZone)

        print(("[ZoneGate] %s moved to Zone %d"):format(player.Name, toZone))
    end)
end

-- プレイヤー退出時にクールダウンをクリア
Players.PlayerRemoving:Connect(function(player)
    cooldowns[player.UserId] = nil
end)

print("[ZoneGate] Zone 1 <-> Zone 2 gates ready")
