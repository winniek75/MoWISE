-- MaterialSystem.server.lua
-- Phase 0: 素材インベントリ管理

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- remotes フォルダを待つ（FlashOutputServer が作成）
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

-- BindableEvent（サーバー内通信用）で素材付与を受け取る
local giveMaterial  = Instance.new("BindableEvent", remotes)
giveMaterial.Name   = "GiveMaterial"
-- RemoteEvent（クライアントへのインベントリ同期用）
local syncInventory = Instance.new("RemoteEvent", remotes)
syncInventory.Name  = "SyncInventory"

-- プレイヤーごとのインベントリ
local inventories = {}

local function getInventory(player)
    if not inventories[player.UserId] then
        inventories[player.UserId] = { Wood = 0, Stone = 0, Flower = 0, Seed = 0 }
    end
    -- Phase 5: 既存プレイヤーに Seed が無ければ追加
    if inventories[player.UserId].Seed == nil then
        inventories[player.UserId].Seed = 0
    end
    return inventories[player.UserId]
end

-- サーバー内から :Fire(player, materialType, amount) で呼ばれる
giveMaterial.Event:Connect(function(player, materialType, amount)
    local inv = getInventory(player)
    -- 未登録の素材タイプなら 0 で初期化して受け入れる
    if inv[materialType] == nil then
        inv[materialType] = 0
    end

    inv[materialType] = inv[materialType] + amount
    print(("[MoWISE] %s: %s +%d (合計:%d)"):format(
        player.Name, materialType, amount, inv[materialType]))
    syncInventory:FireClient(player, inv)

    -- 素材が降ってくる演出（amount個のパーツを少しずらして落とす）
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local basePos = char.HumanoidRootPart.Position
        for i = 1, math.min(amount, 5) do  -- 最大5個まで表示
            local offsetX = (math.random() - 0.5) * 4
            local offsetZ = (math.random() - 0.5) * 4
            local startPos = basePos + Vector3.new(offsetX, 8 + i * 0.5, offsetZ)
            local endPos   = basePos + Vector3.new(offsetX, 2, offsetZ)

            local part = Instance.new("Part")
            part.Size       = Vector3.new(0.8, 0.8, 0.8)
            part.Color      = materialType == "Wood" and Color3.fromRGB(180, 120, 60)
                              or materialType == "Stone" and Color3.fromRGB(150, 150, 150)
                              or materialType == "Seed" and Color3.fromRGB(120, 180, 80)
                              or Color3.fromRGB(255, 150, 200)
            part.Material   = materialType == "Wood" and Enum.Material.Wood
                              or Enum.Material.SmoothPlastic
            part.CFrame     = CFrame.new(startPos)
            part.Anchored   = true
            part.CanCollide = false
            part.CastShadow = false
            part.Transparency = 0
            part.Parent     = workspace

            -- 上から降りてくるTween
            local fallTween = TweenService:Create(
                part,
                TweenInfo.new(0.6, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
                { CFrame = CFrame.new(endPos) }
            )
            fallTween:Play()

            -- 着地後にフェードアウトして消える
            fallTween.Completed:Connect(function()
                task.wait(0.5)
                local fadeTween = TweenService:Create(
                    part,
                    TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Transparency = 1, CFrame = part.CFrame + Vector3.new(0, 1.5, 0) }
                )
                fadeTween:Play()
                fadeTween.Completed:Connect(function()
                    part:Destroy()
                end)
            end)
        end
    end
end)

Players.PlayerRemoving:Connect(function(player)
    inventories[player.UserId] = nil
end)

------------------------------------------------------------------------
-- Phase 2: CraftingSystem との連携（BindableFunction ハンドラ）
------------------------------------------------------------------------

-- GetMaterials: userId → インベントリを返す
local getMaterialsBF = Instance.new("BindableFunction")
getMaterialsBF.Name = "GetMaterials"
getMaterialsBF.Parent = remotes

getMaterialsBF.OnInvoke = function(userId)
    return inventories[userId] or { Wood = 0, Stone = 0, Flower = 0, Seed = 0 }
end

-- ConsumeMaterials: userId, costTable → 素材消費して true/false を返す
local consumeMaterialsBF = Instance.new("BindableFunction")
consumeMaterialsBF.Name = "ConsumeMaterials"
consumeMaterialsBF.Parent = remotes

consumeMaterialsBF.OnInvoke = function(userId, costTable)
    local inv = inventories[userId]
    if not inv then return false end
    -- 一度確認してから消費
    for mat, amount in pairs(costTable) do
        if (inv[mat] or 0) < amount then return false end
    end
    for mat, amount in pairs(costTable) do
        inv[mat] = inv[mat] - amount
    end
    -- HUDを同期
    local player = Players:GetPlayerByUserId(userId)
    if player then
        syncInventory:FireClient(player, inv)
    end
    return true
end
