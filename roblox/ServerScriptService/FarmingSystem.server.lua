-- FarmingSystem.server.lua
-- Phase 5: farm_plot の植付・成長・収穫ループ

local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

------------------------------------------------------------------------
-- RemoteEvent 定義
------------------------------------------------------------------------
local plantSeed     = Instance.new("RemoteEvent", remotes); plantSeed.Name     = "PlantSeed"
local harvestCrop   = Instance.new("RemoteEvent", remotes); harvestCrop.Name   = "HarvestCrop"
local cropReady     = Instance.new("RemoteEvent", remotes); cropReady.Name     = "CropReady"
local cropHarvested = Instance.new("RemoteEvent", remotes); cropHarvested.Name = "CropHarvested"

-- MaterialSystem の BindableFunction / BindableEvent をキャッシュ
local consumeMaterialsBF = nil
local giveMaterial       = nil
task.spawn(function()
    consumeMaterialsBF = remotes:WaitForChild("ConsumeMaterials", 30)
    if not consumeMaterialsBF then warn("[FarmingSystem] ConsumeMaterials not found") end
end)
task.spawn(function()
    giveMaterial = remotes:WaitForChild("GiveMaterial", 30)
    if not giveMaterial then warn("[FarmingSystem] GiveMaterial not found") end
end)

------------------------------------------------------------------------
-- 農業設定
------------------------------------------------------------------------
local GROW_TIME  = 300   -- 5分（テスト時は 30 に変更可）
local SEED_COST  = 1

-- 収穫報酬（ランダム3択）
local HARVEST_REWARDS = {
    { Seed = 2 },
    { Flower = 2 },
    { Seed = 1, Flower = 1 },
}

------------------------------------------------------------------------
-- 畑の状態管理
------------------------------------------------------------------------
-- { [plotId] = { owner=userId, plantedAt=tick(), stage="growing"|"ready", part=BasePart } }
local farmPlots = {}

------------------------------------------------------------------------
-- 植付処理
------------------------------------------------------------------------
plantSeed.OnServerEvent:Connect(function(player, plotId)
    if farmPlots[plotId] then return end

    -- Seed を消費（ConsumeMaterials は userId を受け取る）
    if not consumeMaterialsBF then return end
    local ok = consumeMaterialsBF:Invoke(player.UserId, { Seed = SEED_COST })
    if not ok then
        cropHarvested:FireClient(player, false, "Seed が足りません")
        return
    end

    -- plotId に対応するパーツを Workspace から検索
    local part = nil
    for _, desc in pairs(workspace:GetDescendants()) do
        if desc:IsA("BasePart") and desc:GetAttribute("PlotId") == plotId then
            part = desc
            break
        end
    end
    if not part then return end

    -- 状態登録
    farmPlots[plotId] = {
        owner     = player.UserId,
        plantedAt = tick(),
        stage     = "growing",
        part      = part,
    }

    -- 畑パーツの色を変えて「植えた」を演出
    part.Color = Color3.fromRGB(60, 120, 40)

    print(("[FarmingSystem] %s planted Seed in plot %s"):format(player.Name, plotId))
end)

------------------------------------------------------------------------
-- 成長チェック（毎秒）
------------------------------------------------------------------------
local lastCheck = 0
RunService.Heartbeat:Connect(function()
    local now = tick()
    if now - lastCheck < 1 then return end
    lastCheck = now

    for plotId, data in pairs(farmPlots) do
        if data.stage == "growing" and (now - data.plantedAt) >= GROW_TIME then
            data.stage = "ready"

            -- 畑パーツを黄色に（収穫可能サイン）
            if data.part and data.part.Parent then
                data.part.Color = Color3.fromRGB(220, 200, 50)
            end

            -- オーナーに通知
            local owner = Players:GetPlayerByUserId(data.owner)
            if owner then
                cropReady:FireClient(owner, plotId)
                print(("[FarmingSystem] Plot %s is ready for harvest"):format(plotId))
            end
        end
    end
end)

------------------------------------------------------------------------
-- 収穫処理
------------------------------------------------------------------------
harvestCrop.OnServerEvent:Connect(function(player, plotId)
    local data = farmPlots[plotId]
    if not data then return end
    if data.owner ~= player.UserId then return end
    if data.stage ~= "ready" then return end

    -- ランダム報酬
    local reward = HARVEST_REWARDS[math.random(1, #HARVEST_REWARDS)]

    -- 素材付与（GiveMaterial は BindableEvent → :Fire()）
    if giveMaterial then
        for matName, qty in pairs(reward) do
            giveMaterial:Fire(player, matName, qty)
        end
    end

    -- 畑を空き状態に戻す
    if data.part and data.part.Parent then
        data.part.Color = Color3.fromRGB(95, 75, 50)
    end
    farmPlots[plotId] = nil

    -- クライアントに完了通知
    local rewardStr = ""
    for k, v in pairs(reward) do rewardStr = rewardStr .. k .. "x" .. v .. " " end
    cropHarvested:FireClient(player, true, rewardStr:gsub(" $", ""))

    print(("[FarmingSystem] %s harvested: %s"):format(player.Name, rewardStr))
end)

print("[MoWISE] FarmingSystem ready")
