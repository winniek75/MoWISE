-- CraftingClient.client.lua
-- Phase 2: クラフトメニューUI + 配置モード

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player  = Players.LocalPlayer
local mouse   = player:GetMouse()
local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes")

local openCraftMenu  = remotes:WaitForChild("OpenCraftMenu")
local requestCraft   = remotes:WaitForChild("RequestCraft")
local craftResult    = remotes:WaitForChild("CraftResult")
local requestPlace   = remotes:WaitForChild("RequestPlace")
local placeConfirmed = remotes:WaitForChild("PlaceConfirmed", 10)

------------------------------------------------------------------------
-- GUI 生成（コードで生成 - 手動GUI不要）
------------------------------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name      = "CraftingGui"
screenGui.Enabled   = false
screenGui.ResetOnSpawn = false
screenGui.Parent    = player.PlayerGui

-- 背景オーバーレイ
local overlay = Instance.new("Frame")
overlay.Size                   = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 0.6
overlay.BorderSizePixel        = 0
overlay.Parent                 = screenGui

-- メインパネル
local panel = Instance.new("Frame")
panel.Name                 = "CraftPanel"
panel.Size                 = UDim2.new(0, 480, 0, 520)
panel.Position             = UDim2.new(0.5, -240, 0.5, -260)
panel.BackgroundColor3     = Color3.fromRGB(20, 25, 40)
panel.BorderSizePixel      = 0
panel.Parent               = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 12)

-- タイトル
local title = Instance.new("TextLabel")
title.Text        = "クラフト"
title.Size        = UDim2.new(1, 0, 0, 44)
title.BackgroundTransparency = 1
title.TextColor3  = Color3.fromRGB(255, 220, 80)
title.Font        = Enum.Font.GothamBold
title.TextSize    = 20
title.Parent      = panel

-- 素材表示バー
local matBar = Instance.new("Frame")
matBar.Name               = "MatBar"
matBar.Size               = UDim2.new(1, -20, 0, 32)
matBar.Position           = UDim2.new(0, 10, 0, 48)
matBar.BackgroundColor3   = Color3.fromRGB(30, 40, 60)
matBar.BorderSizePixel    = 0
matBar.Parent             = panel
Instance.new("UICorner", matBar).CornerRadius = UDim.new(0, 6)
Instance.new("UIListLayout", matBar).FillDirection = Enum.FillDirection.Horizontal

local matLabels = {}
local matKeys = { "Wood", "Stone", "Flower", "Seed" }
local matIcons = { "Wood", "Stone", "Flower", "Seed" }
local matColors = {
    Color3.fromRGB(180, 120, 60),
    Color3.fromRGB(150, 150, 150),
    Color3.fromRGB(255, 150, 200),
    Color3.fromRGB(120, 180, 80),
}
for i, key in ipairs(matKeys) do
    local lbl = Instance.new("TextLabel")
    lbl.Name              = key .. "Label"
    lbl.Text              = matIcons[i] .. " 0"
    lbl.Size              = UDim2.new(0, 110, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3        = matColors[i]
    lbl.Font              = Enum.Font.GothamBold
    lbl.TextSize          = 14
    lbl.Parent            = matBar
    matLabels[key] = lbl
end

-- レシピリスト（スクロール）
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name               = "RecipeList"
scrollFrame.Size               = UDim2.new(1, -20, 1, -160)
scrollFrame.Position           = UDim2.new(0, 10, 0, 90)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 6
scrollFrame.BorderSizePixel    = 0
scrollFrame.Parent             = panel

local listLayout = Instance.new("UIListLayout", scrollFrame)
listLayout.Padding  = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- 閉じるボタン
local closeBtn = Instance.new("TextButton")
closeBtn.Text              = "閉じる"
closeBtn.Size              = UDim2.new(1, -20, 0, 36)
closeBtn.Position          = UDim2.new(0, 10, 1, -46)
closeBtn.BackgroundColor3  = Color3.fromRGB(80, 40, 40)
closeBtn.TextColor3        = Color3.fromRGB(255, 255, 255)
closeBtn.Font              = Enum.Font.Gotham
closeBtn.TextSize          = 14
closeBtn.BorderSizePixel   = 0
closeBtn.Parent            = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)

------------------------------------------------------------------------
-- フィードバックトースト
------------------------------------------------------------------------
local toast = Instance.new("Frame")
toast.Size                 = UDim2.new(0, 300, 0, 44)
toast.Position             = UDim2.new(0.5, -150, 0, -60)
toast.BackgroundColor3     = Color3.fromRGB(40, 160, 80)
toast.BackgroundTransparency = 0.2
toast.BorderSizePixel      = 0
toast.Parent               = screenGui
Instance.new("UICorner", toast).CornerRadius = UDim.new(0, 8)

local toastLabel = Instance.new("TextLabel")
toastLabel.Size              = UDim2.new(1, 0, 1, 0)
toastLabel.BackgroundTransparency = 1
toastLabel.TextColor3        = Color3.fromRGB(255, 255, 255)
toastLabel.Font              = Enum.Font.GothamBold
toastLabel.TextSize          = 16
toastLabel.Parent            = toast

local function showToast(msg, success)
    toast.BackgroundColor3 = success
        and Color3.fromRGB(40, 160, 80)
        or  Color3.fromRGB(180, 60, 60)
    toastLabel.Text = msg
    TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -150, 0, 12) }):Play()
    task.delay(2, function()
        TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(0.5, -150, 0, -60) }):Play()
    end)
end

------------------------------------------------------------------------
-- 素材ラベル更新
------------------------------------------------------------------------
local function updateMatLabels(inv)
    if not inv then return end
    for i, key in ipairs(matKeys) do
        if matLabels[key] then
            matLabels[key].Text = matIcons[i] .. " " .. (inv[key] or 0)
        end
    end
end

------------------------------------------------------------------------
-- レシピボタン生成
------------------------------------------------------------------------
local currentRecipes = {}

local function buildRecipeList(recipes, inv)
    currentRecipes = recipes
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    for i, recipe in ipairs(recipes) do
        local row = Instance.new("Frame")
        row.Name              = "Recipe_" .. recipe.id
        row.Size              = UDim2.new(1, -10, 0, 72)
        row.BackgroundColor3  = Color3.fromRGB(30, 38, 58)
        row.BorderSizePixel   = 0
        row.LayoutOrder       = i
        row.Parent            = scrollFrame
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

        -- アイテム名
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Text        = recipe.name
        nameLabel.Size        = UDim2.new(0.55, 0, 0, 28)
        nameLabel.Position    = UDim2.new(0, 10, 0, 6)
        nameLabel.BackgroundTransparency = 1
        nameLabel.TextColor3  = Color3.fromRGB(255, 255, 255)
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Font        = Enum.Font.GothamBold
        nameLabel.TextSize    = 15
        nameLabel.Parent      = row

        -- コスト表示
        local costParts = {}
        local canCraft  = true
        for mat, amount in pairs(recipe.cost) do
            local has = inv and (inv[mat] or 0) or 0
            local ok  = has >= amount
            if not ok then canCraft = false end
            table.insert(costParts, mat .. "x" .. amount .. (ok and "" or " !"))
        end

        local costLabel = Instance.new("TextLabel")
        costLabel.Text        = table.concat(costParts, "  ")
        costLabel.Size        = UDim2.new(0.55, 0, 0, 26)
        costLabel.Position    = UDim2.new(0, 10, 0, 36)
        costLabel.BackgroundTransparency = 1
        costLabel.TextColor3  = canCraft
            and Color3.fromRGB(160, 220, 160)
            or Color3.fromRGB(220, 120, 120)
        costLabel.TextXAlignment = Enum.TextXAlignment.Left
        costLabel.Font        = Enum.Font.Gotham
        costLabel.TextSize    = 13
        costLabel.Parent      = row

        -- クラフトボタン
        local btn = Instance.new("TextButton")
        btn.Text              = canCraft and "クラフト" or "素材不足"
        btn.Size              = UDim2.new(0, 100, 0, 44)
        btn.Position          = UDim2.new(1, -112, 0.5, -22)
        btn.BackgroundColor3  = canCraft
            and Color3.fromRGB(60, 130, 200)
            or Color3.fromRGB(60, 60, 80)
        btn.TextColor3        = Color3.fromRGB(255, 255, 255)
        btn.Font              = Enum.Font.GothamBold
        btn.TextSize          = 14
        btn.Active            = canCraft
        btn.BorderSizePixel   = 0
        btn.Parent            = row
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

        if canCraft then
            btn.MouseButton1Click:Connect(function()
                requestCraft:FireServer(recipe.id)
                btn.Active = false
                btn.BackgroundColor3 = Color3.fromRGB(40, 80, 140)
                btn.Text = "..."
            end)
        end
    end

    -- ScrollingFrame の CanvasSize を自動調整
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #recipes * 78)
end

------------------------------------------------------------------------
-- メニューを開く
------------------------------------------------------------------------
openCraftMenu.OnClientEvent:Connect(function(recipes, inv)
    updateMatLabels(inv)
    buildRecipeList(recipes, inv)
    screenGui.Enabled = true
end)

-- 閉じるボタン
closeBtn.MouseButton1Click:Connect(function()
    screenGui.Enabled = false
end)

------------------------------------------------------------------------
-- クラフト結果
------------------------------------------------------------------------
craftResult.OnClientEvent:Connect(function(success, resultOrMsg, itemName, updatedInv, craftInv)
    if success then
        showToast((itemName or "アイテム") .. " をクラフト！", true)
        if updatedInv then
            updateMatLabels(updatedInv)
            buildRecipeList(currentRecipes, updatedInv)
        end
        -- 配置モードへ移行
        if resultOrMsg then
            task.delay(0.5, function()
                screenGui.Enabled = false
                startPlacementMode(resultOrMsg, craftInv)
            end)
        end
    else
        showToast(resultOrMsg or "クラフト失敗", false)
        -- ボタンを再アクティブ化
        for _, child in ipairs(scrollFrame:GetChildren()) do
            if child:IsA("Frame") then
                local btn = child:FindFirstChildWhichIsA("TextButton")
                if btn then
                    btn.Active = true
                    btn.BackgroundColor3 = Color3.fromRGB(60, 130, 200)
                    btn.Text = "クラフト"
                end
            end
        end
    end
end)

------------------------------------------------------------------------
-- P2-3: 配置モード
------------------------------------------------------------------------

-- 配置プレビュー用パーツ（Ghost）
local ghostPart = nil
local isPlacing = false
local placingItemKey = nil

local function clearGhost()
    if ghostPart then
        ghostPart:Destroy()
        ghostPart = nil
    end
end

-- 配置モード開始
function startPlacementMode(itemKey, craftInv)
    if isPlacing then clearGhost() end
    isPlacing    = true
    placingItemKey = itemKey

    -- ゴーストパーツ生成（半透明プレビュー）
    ghostPart = Instance.new("Part")
    ghostPart.Name              = "PlacementGhost"
    ghostPart.Size              = Vector3.new(6, 1, 6)  -- 仮サイズ
    ghostPart.Material          = Enum.Material.Neon
    ghostPart.Color             = Color3.fromRGB(100, 200, 255)
    ghostPart.Transparency      = 0.5
    ghostPart.Anchored          = true
    ghostPart.CanCollide        = false
    ghostPart.CastShadow        = false
    ghostPart.Parent            = workspace

    -- 配置ヒントを画面下に表示
    local hint = Instance.new("ScreenGui")
    hint.Name       = "PlacementHint"
    hint.ResetOnSpawn = false
    hint.Parent     = player.PlayerGui

    local hintLabel = Instance.new("TextLabel")
    hintLabel.Text  = "クリックで配置 | Rキーで回転 | Escでキャンセル"
    hintLabel.Size  = UDim2.new(0, 450, 0, 36)
    hintLabel.Position = UDim2.new(0.5, -225, 1, -60)
    hintLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    hintLabel.BackgroundTransparency = 0.3
    hintLabel.TextColor3 = Color3.fromRGB(255, 255, 200)
    hintLabel.Font  = Enum.Font.Gotham
    hintLabel.TextSize = 14
    hintLabel.BorderSizePixel = 0
    hintLabel.Parent = hint
    Instance.new("UICorner", hintLabel).CornerRadius = UDim.new(0, 6)

    local rotation = 0

    -- Raycast パラメータ（ゴーストを除外）
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = { ghostPart }
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    -- マウス追従
    local conn = RunService.RenderStepped:Connect(function()
        if not isPlacing or not ghostPart then return end
        local unitRay = workspace.CurrentCamera:ScreenPointToRay(mouse.X, mouse.Y)
        local result  = workspace:Raycast(unitRay.Origin, unitRay.Direction * 500, rayParams)
        if result then
            local snappedPos = Vector3.new(
                math.round(result.Position.X / 2) * 2,
                result.Position.Y + ghostPart.Size.Y / 2,
                math.round(result.Position.Z / 2) * 2
            )
            ghostPart.CFrame = CFrame.new(snappedPos) * CFrame.Angles(0, math.rad(rotation), 0)
        end
    end)

    -- 回転（R キー）& キャンセル（Esc）
    local inputConn
    inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.R then
            rotation = rotation + 45
        end
        if input.KeyCode == Enum.KeyCode.Escape then
            isPlacing = false
            clearGhost()
            conn:Disconnect()
            inputConn:Disconnect()
            hint:Destroy()
            showToast("配置をキャンセルしました", false)
        end
    end)

    -- クリックで配置確定
    local clickConn
    clickConn = mouse.Button1Down:Connect(function()
        if not isPlacing or not ghostPart then return end
        local pos = ghostPart.Position
        local rot = rotation

        isPlacing = false
        clearGhost()
        conn:Disconnect()
        inputConn:Disconnect()
        clickConn:Disconnect()
        hint:Destroy()

        requestPlace:FireServer(itemKey, pos, rot)
    end)
end

-- 配置確定後の処理
if placeConfirmed then
    placeConfirmed.OnClientEvent:Connect(function(itemKey, updatedCraftInv)
        showToast("配置完了！", true)
    end)
end
