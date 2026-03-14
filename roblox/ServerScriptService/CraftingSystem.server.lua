-- CraftingSystem.server.lua
-- Phase 2: クラフトレシピ管理・素材消費・アイテム付与・配置

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

-- RemoteEvent 追加
local requestCraft   = Instance.new("RemoteEvent", remotes)
requestCraft.Name    = "RequestCraft"
local craftResult    = Instance.new("RemoteEvent", remotes)
craftResult.Name     = "CraftResult"
local openCraftMenu  = Instance.new("RemoteEvent", remotes)
openCraftMenu.Name   = "OpenCraftMenu"

-- Phase 3: 小さな家配置時に VillagerSystem へ通知する BindableEvent
local houseBuiltEvent = Instance.new("BindableEvent", remotes)
houseBuiltEvent.Name  = "HouseBuilt"

------------------------------------------------------------------------
-- クラフトレシピ定義（Phase 2 MVP: 基礎建材7種）
------------------------------------------------------------------------
local RECIPES = {
    {
        id          = "floor_basic",
        name        = "木の床",
        description = "基本的な床ボード",
        cost        = { Wood = 2 },
        result      = "FloorBasic",
        category    = "建材",
        modelSize   = Vector3.new(6, 0.5, 6),
        modelColor  = Color3.fromRGB(180, 130, 80),
        modelMat    = Enum.Material.Wood,
    },
    {
        id          = "wall_basic",
        name        = "石の壁",
        description = "頑丈な壁ボード",
        cost        = { Stone = 2 },
        result      = "WallBasic",
        category    = "建材",
        modelSize   = Vector3.new(6, 4, 0.5),
        modelColor  = Color3.fromRGB(140, 130, 120),
        modelMat    = Enum.Material.SmoothPlastic,
    },
    {
        id          = "fence_wood",
        name        = "木のフェンス",
        description = "敷地の境界に",
        cost        = { Wood = 1 },
        result      = "FenceWood",
        category    = "インフラ",
        modelSize   = Vector3.new(4, 2, 0.3),
        modelColor  = Color3.fromRGB(160, 110, 60),
        modelMat    = Enum.Material.Wood,
    },
    {
        id          = "path_stone",
        name        = "石畳の道",
        description = "道路ボード",
        cost        = { Stone = 1 },
        result      = "PathStone",
        category    = "インフラ",
        modelSize   = Vector3.new(4, 0.3, 4),
        modelColor  = Color3.fromRGB(130, 120, 110),
        modelMat    = Enum.Material.SmoothPlastic,
    },
    {
        id          = "flower_bed",
        name        = "花壇",
        description = "街を彩る装飾",
        cost        = { Flower = 2, Wood = 1 },
        result      = "FlowerBed",
        category    = "装飾",
        modelSize   = Vector3.new(3, 0.8, 3),
        modelColor  = Color3.fromRGB(255, 180, 50),
        modelMat    = Enum.Material.Grass,
    },
    {
        id          = "small_house",
        name        = "小さな家",
        description = "最初の住居。町民が来るかも",
        cost        = { Wood = 5, Stone = 3 },
        result      = "SmallHouse",
        category    = "建物",
        modelSize   = Vector3.new(8, 6, 8),
        modelColor  = Color3.fromRGB(200, 160, 100),
        modelMat    = Enum.Material.Wood,
    },
    {
        id          = "workbench_upgrade",
        name        = "改良クラフト台",
        description = "より高度なレシピを解禁する",
        cost        = { Wood = 3, Stone = 2 },
        result      = "WorkbenchUpgrade",
        category    = "建物",
        modelSize   = Vector3.new(3, 1.5, 2),
        modelColor  = Color3.fromRGB(120, 80, 40),
        modelMat    = Enum.Material.Wood,
    },
    -- Phase 5: ★解禁レシピ
    {
        id           = "farm_plot",
        name         = "農業用畑",
        description  = "種を植えて作物を育てる",
        cost         = { Wood = 2, Stone = 1, Seed = 1 },
        result       = "FarmPlot",
        category     = "農業",
        modelSize    = Vector3.new(4, 0.3, 4),
        modelColor   = Color3.fromRGB(95, 75, 50),
        modelMat     = Enum.Material.Grass,
        buildingType = "farm_plot",
    },
    {
        id           = "medium_house",
        name         = "中型の家",
        description  = "もう少し広い住居",
        cost         = { Wood = 5, Stone = 3 },
        result       = "MediumHouse",
        category     = "建物",
        modelSize    = Vector3.new(6, 5, 5),
        modelColor   = Color3.fromRGB(200, 180, 150),
        modelMat     = Enum.Material.Wood,
        buildingType = "medium_house",
    },
    {
        id           = "storage_shed",
        name         = "倉庫",
        description  = "素材を保管する建物",
        cost         = { Wood = 4, Stone = 4 },
        result       = "StorageShed",
        category     = "建物",
        modelSize    = Vector3.new(6, 4, 5),
        modelColor   = Color3.fromRGB(150, 130, 110),
        modelMat     = Enum.Material.Wood,
        buildingType = "storage_shed",
    },
}

-- レシピIDで高速検索テーブル
local recipeById = {}
for _, r in ipairs(RECIPES) do
    recipeById[r.id] = r
end

------------------------------------------------------------------------
-- プレイヤーのクラフトインベントリ（作成済みアイテム）
------------------------------------------------------------------------
local craftInventories = {}  -- { [userId] = { FloorBasic = 2, ... } }

local function getCraftInventory(player)
    if not craftInventories[player.UserId] then
        craftInventories[player.UserId] = {}
    end
    return craftInventories[player.UserId]
end

------------------------------------------------------------------------
-- MaterialSystem との連携（BindableFunction）
------------------------------------------------------------------------
local getMaterialsBF    = nil
local consumeMaterialsBF = nil
task.spawn(function()
    getMaterialsBF = remotes:WaitForChild("GetMaterials", 30)
    if not getMaterialsBF then warn("[CraftingSystem] GetMaterials not found") end
end)
task.spawn(function()
    consumeMaterialsBF = remotes:WaitForChild("ConsumeMaterials", 30)
    if not consumeMaterialsBF then warn("[CraftingSystem] ConsumeMaterials not found") end
end)

------------------------------------------------------------------------
-- ワークベンチの ProximityPrompt → クラフトメニューを開く
------------------------------------------------------------------------
local function connectWorkbench()
    local wb = workspace:WaitForChild("Workbench", 15)
    if not wb then return end
    local prompt = wb:WaitForChild("CraftPrompt", 10)
    if not prompt then return end

    prompt.Triggered:Connect(function(player)
        local inv = getMaterialsBF and getMaterialsBF:Invoke(player.UserId)
            or { Wood = 0, Stone = 0, Flower = 0 }
        openCraftMenu:FireClient(player, RECIPES, inv)
    end)
end
task.spawn(connectWorkbench)

-- フォールバック: 後から追加されるWorkbenchにも対応
workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("ProximityPrompt") and obj.Name == "CraftPrompt" then
        obj.Triggered:Connect(function(player)
            local inv = getMaterialsBF and getMaterialsBF:Invoke(player.UserId)
                or { Wood = 0, Stone = 0, Flower = 0 }
            openCraftMenu:FireClient(player, RECIPES, inv)
        end)
    end
end)

------------------------------------------------------------------------
-- クラフト実行
------------------------------------------------------------------------
requestCraft.OnServerEvent:Connect(function(player, recipeId)
    local recipe = recipeById[recipeId]
    if not recipe then
        craftResult:FireClient(player, false, "不明なレシピ")
        return
    end

    -- 素材チェック
    if not getMaterialsBF then
        craftResult:FireClient(player, false, "システム初期化中…")
        return
    end
    local inv = getMaterialsBF:Invoke(player.UserId)
    if not inv then
        craftResult:FireClient(player, false, "インベントリが見つかりません")
        return
    end

    for mat, required in pairs(recipe.cost) do
        local has = inv[mat] or 0
        if has < required then
            craftResult:FireClient(player, false,
                mat .. " が不足しています（" .. has .. "/" .. required .. "）")
            return
        end
    end

    -- 素材消費
    if not consumeMaterialsBF then
        craftResult:FireClient(player, false, "システム初期化中…")
        return
    end
    local success = consumeMaterialsBF:Invoke(player.UserId, recipe.cost)
    if not success then
        craftResult:FireClient(player, false, "素材消費に失敗しました")
        return
    end

    -- クラフトインベントリに追加
    local ci = getCraftInventory(player)
    ci[recipe.result] = (ci[recipe.result] or 0) + 1

    -- クライアントに通知（成功 + 更新後の素材インベントリ）
    local updatedInv = getMaterialsBF:Invoke(player.UserId)
    craftResult:FireClient(player, true, recipe.result, recipe.name, updatedInv, ci)

    print(("[MoWISE] %s crafted: %s"):format(player.Name, recipe.name))
end)

------------------------------------------------------------------------
-- 配置リクエスト
------------------------------------------------------------------------
local requestPlace = Instance.new("RemoteEvent", remotes)
requestPlace.Name  = "RequestPlace"

local placeConfirmed = Instance.new("RemoteEvent", remotes)
placeConfirmed.Name  = "PlaceConfirmed"

requestPlace.OnServerEvent:Connect(function(player, itemKey, position, rotation)
    local ci = getCraftInventory(player)
    if not ci[itemKey] or ci[itemKey] <= 0 then
        return
    end

    -- レシピ情報を取得（result名から逆引き）
    local recipe = nil
    for _, r in ipairs(RECIPES) do
        if r.result == itemKey then recipe = r; break end
    end
    if not recipe then return end

    -- クラフトインベントリから1つ消費
    ci[itemKey] = ci[itemKey] - 1

    -- ワールドにパーツ生成
    local placed = Instance.new("Part")
    placed.Name     = recipe.result .. "_placed"
    placed.Size     = recipe.modelSize
    placed.Color    = recipe.modelColor
    placed.Material = recipe.modelMat
    placed.Anchored = true
    placed.CanCollide = true
    placed.CFrame   = CFrame.new(position) * CFrame.Angles(0, math.rad(rotation or 0), 0)
    placed.Parent   = workspace

    -- タグを追加（整地・撤去などで識別するため）
    local tag = Instance.new("StringValue")
    tag.Name  = "PlacedBy"
    tag.Value = player.Name
    tag.Parent = placed

    -- Phase 5: 建物タイプ属性（FarmingSystem が farm_plot を識別するため）
    if recipe.buildingType then
        placed:SetAttribute("BuildingType", recipe.buildingType)
        placed:SetAttribute("PlotId", tostring(placed:GetDebugId()))
    end

    print(("[MoWISE] %s placed: %s at %s"):format(player.Name, recipe.result, tostring(position)))

    -- Phase 3: 小さな家を置いたら VillagerSystem に通知
    if itemKey == "SmallHouse" then
        houseBuiltEvent:Fire(player, position)
    end

    -- 配置確定をクライアントに通知
    placeConfirmed:FireClient(player, itemKey, ci)
end)

Players.PlayerRemoving:Connect(function(player)
    craftInventories[player.UserId] = nil
end)

print("[MoWISE] CraftingSystem ready")
