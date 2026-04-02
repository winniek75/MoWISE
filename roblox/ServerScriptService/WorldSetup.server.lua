-- WorldSetup.server.lua
-- Phase 0: P0-1 / P0-6 / P0-7 の手動セットアップを自動化
-- 起動時に1回だけ実行し、地形・廃墟・Lighting・FlashTrigger・GUIを生成する

local Players         = game:GetService("Players")
local Lighting        = game:GetService("Lighting")
local StarterGui      = game:GetService("StarterGui")
local Workspace       = game:GetService("Workspace")
local Terrain         = Workspace.Terrain

------------------------------------------------------------------------
-- P0-1a: Lighting 設定
------------------------------------------------------------------------
local function setupLighting()
	Lighting.Ambient       = Color3.fromRGB(60, 60, 70)
	Lighting.Brightness    = 0.8
	Lighting.ClockTime     = 7          -- 夕暮れ前の薄暗さ
	Lighting.FogEnd        = 400
	Lighting.FogColor      = Color3.fromRGB(150, 150, 160)

	-- Atmosphere が無ければ追加（より廃墟らしい霧感）
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmo = Instance.new("Atmosphere")
		atmo.Density  = 0.3
		atmo.Offset   = 0.2
		atmo.Color    = Color3.fromRGB(170, 170, 180)
		atmo.Decay    = Color3.fromRGB(120, 120, 130)
		atmo.Glare    = 0.1
		atmo.Haze     = 1.5
		atmo.Parent   = Lighting
	end

	print("[MoWISE] Lighting configured")
end

------------------------------------------------------------------------
-- P0-1b: Terrain（草地 + 起伏）
------------------------------------------------------------------------
local function setupTerrain()
	-- 既存の地形をクリアして再生成
	Terrain:Clear()

	local REGION_SIZE = 200          -- studs
	local RESOLUTION  = 4            -- Terrain resolution
	local HALF        = REGION_SIZE / 2

	-- FillRegion で草の平地を敷く（高さ4studsの薄い層）
	local min = Vector3.new(-HALF, -4, -HALF)
	local max = Vector3.new( HALF,  0,  HALF)
	local region = Region3.new(min, max)
	region = region:ExpandToGrid(RESOLUTION)
	Terrain:FillRegion(region, RESOLUTION, Enum.Material.Grass)

	-- 岩の丘を数か所追加
	local hills = {
		{ pos = Vector3.new(-40, 0, -30), radius = 18 },
		{ pos = Vector3.new( 50, 0,  40), radius = 14 },
		{ pos = Vector3.new( 20, 0, -60), radius = 10 },
		{ pos = Vector3.new(-60, 0,  50), radius = 12 },
	}
	for _, h in ipairs(hills) do
		Terrain:FillBall(h.pos, h.radius, Enum.Material.Rock)
	end

	-- 低い窪地（穴）を数か所 Air で掘る
	local hollows = {
		{ pos = Vector3.new( 30, -2,  10), radius = 8 },
		{ pos = Vector3.new(-20, -2, -50), radius = 6 },
	}
	for _, h in ipairs(hollows) do
		Terrain:FillBall(h.pos, h.radius, Enum.Material.Air)
	end

	print("[MoWISE] Terrain generated (200x200)")
end

------------------------------------------------------------------------
-- P0-1c: 廃墟パーツ (RuinsFolder)
------------------------------------------------------------------------
local function setupRuins()
	-- 既存があれば再生成しない
	if Workspace:FindFirstChild("RuinsFolder") then
		print("[MoWISE] RuinsFolder already exists, skipping")
		return
	end

	local folder = Instance.new("Folder")
	folder.Name   = "RuinsFolder"
	folder.Parent = Workspace

	-- パーツ定義テーブル
	local RUINS = {
		-- Walls
		{ name="Wall_01", size=Vector3.new(2,8,1),  pos=Vector3.new(-15, 4, -10), rot=Vector3.new(0, 0, 0),   color=Color3.fromRGB(108,88,75) },
		{ name="Wall_02", size=Vector3.new(2,8,1),  pos=Vector3.new(-10, 4, -12), rot=Vector3.new(0, 25, 0),  color=Color3.fromRGB(108,88,75) },
		{ name="Wall_03", size=Vector3.new(2,8,1),  pos=Vector3.new( 12, 4,  8),  rot=Vector3.new(0,-15, 0),  color=Color3.fromRGB(108,88,75) },
		{ name="Wall_04", size=Vector3.new(2,6,1),  pos=Vector3.new( 18, 3, -20), rot=Vector3.new(0, 40, 5),  color=Color3.fromRGB(100,82,70) },
		{ name="Wall_05", size=Vector3.new(2,7,1),  pos=Vector3.new(-25, 3.5, 15),rot=Vector3.new(0,-30, 0),  color=Color3.fromRGB(100,82,70) },
		-- Rocks
		{ name="Rock_01", size=Vector3.new(3,2,4),  pos=Vector3.new(-8,  1, -5),  rot=Vector3.new(0, 10, 0),  color=Color3.fromRGB(99,95,98)  },
		{ name="Rock_02", size=Vector3.new(4,3,3),  pos=Vector3.new( 20, 1.5, 5), rot=Vector3.new(0,-20, 0),  color=Color3.fromRGB(99,95,98)  },
		{ name="Rock_03", size=Vector3.new(2,2,3),  pos=Vector3.new( -5, 1,  18), rot=Vector3.new(0, 45, 0),  color=Color3.fromRGB(90,88,92)  },
		-- Debris（崩れた梁 — 傾けて配置）
		{ name="Debris_01", size=Vector3.new(4,1,3), pos=Vector3.new(-12, 0.5, 2),  rot=Vector3.new(15, 0,  8),  color=Color3.fromRGB(108,88,75) },
		{ name="Debris_02", size=Vector3.new(5,1,2), pos=Vector3.new( 8,  0.5,-15), rot=Vector3.new(-10, 30, 5), color=Color3.fromRGB(100,82,70) },
		{ name="Debris_03", size=Vector3.new(3,1,4), pos=Vector3.new( 25, 0.5, 20), rot=Vector3.new(8, -10, 12), color=Color3.fromRGB(95,80,68)  },
	}

	for _, def in ipairs(RUINS) do
		local part = Instance.new("Part")
		part.Name       = def.name
		part.Size       = def.size
		part.Anchored   = true
		part.Material   = Enum.Material.SmoothPlastic
		part.Color      = def.color
		part.CFrame     = CFrame.new(def.pos)
			* CFrame.Angles(math.rad(def.rot.X), math.rad(def.rot.Y), math.rad(def.rot.Z))
		part.Parent     = folder
	end

	print("[MoWISE] RuinsFolder created (" .. #RUINS .. " parts)")
end

------------------------------------------------------------------------
-- P0-6: FlashTriggerZone（ProximityPrompt 付き）
------------------------------------------------------------------------
local function setupFlashTrigger()
	if Workspace:FindFirstChild("FlashTriggerZone") then
		print("[MoWISE] FlashTriggerZone already exists, skipping")
		return
	end

	local zone = Instance.new("Part")
	zone.Name          = "FlashTriggerZone"
	zone.Size          = Vector3.new(10, 1, 10)
	zone.Anchored      = true
	zone.CanCollide    = false
	zone.Transparency  = 0.8
	zone.Color         = Color3.fromRGB(100, 200, 255)
	zone.Material      = Enum.Material.Neon
	zone.Position      = Vector3.new(0, 3, 0) -- Zone1 中央付近
	zone.Parent        = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name                  = "FlashTrigger"
	prompt.ActionText            = "英語チャレンジ！"
	prompt.ObjectText            = "Flash Output"
	prompt.MaxActivationDistance  = 10
	prompt.Parent                = zone

	print("[MoWISE] FlashTriggerZone placed at origin")
end

------------------------------------------------------------------------
-- P0-7: FlashOutputGui（StarterGui に自動生成）
------------------------------------------------------------------------
local function setupFlashOutputGui()
	if StarterGui:FindFirstChild("FlashOutputGui") then
		print("[MoWISE] FlashOutputGui already exists, skipping")
		return
	end

	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name              = "FlashOutputGui"
	screenGui.Enabled           = false
	screenGui.ResetOnSpawn      = false
	screenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
	screenGui.Parent            = StarterGui

	-- MainFrame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name                    = "MainFrame"
	mainFrame.AnchorPoint             = Vector2.new(0.5, 0.5)
	mainFrame.Position                = UDim2.new(0.5, 0, 0.55, 0)
	mainFrame.Size                    = UDim2.new(0.85, 0, 0.55, 0)
	mainFrame.BackgroundColor3        = Color3.fromRGB(20, 25, 40)
	mainFrame.BackgroundTransparency  = 0.1
	mainFrame.BorderSizePixel         = 0
	mainFrame.Parent                  = screenGui

	-- 角丸
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent       = mainFrame

	-- ProgressLabel  (1 / 5)
	local progressLabel = Instance.new("TextLabel")
	progressLabel.Name                    = "ProgressLabel"
	progressLabel.Text                    = "1 / 5"
	progressLabel.Size                    = UDim2.new(1, 0, 0.08, 0)
	progressLabel.Position                = UDim2.new(0, 0, 0, 0)
	progressLabel.BackgroundTransparency  = 1
	progressLabel.TextColor3              = Color3.fromRGB(180, 180, 180)
	progressLabel.Font                    = Enum.Font.Gotham
	progressLabel.TextSize                = 14
	progressLabel.Parent                  = mainFrame

	-- PromptLabel（日本語プロンプト）
	local promptLabel = Instance.new("TextLabel")
	promptLabel.Name                    = "PromptLabel"
	promptLabel.Text                    = "日本語プロンプト"
	promptLabel.Size                    = UDim2.new(1, 0, 0.18, 0)
	promptLabel.Position                = UDim2.new(0, 0, 0.08, 0)
	promptLabel.BackgroundTransparency  = 1
	promptLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
	promptLabel.Font                    = Enum.Font.GothamBold
	promptLabel.TextSize                = 22
	promptLabel.TextWrapped             = true
	promptLabel.Parent                  = mainFrame

	-- TilesFrame（タイルボタン領域）
	local tilesFrame = Instance.new("Frame")
	tilesFrame.Name                    = "TilesFrame"
	tilesFrame.Size                    = UDim2.new(1, -16, 0.25, 0)
	tilesFrame.Position                = UDim2.new(0, 8, 0.26, 0)
	tilesFrame.BackgroundTransparency  = 1
	tilesFrame.Parent                  = mainFrame

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize        = UDim2.new(0, 95, 0, 48)
	gridLayout.CellPadding     = UDim2.new(0, 8, 0, 6)
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.SortOrder       = Enum.SortOrder.LayoutOrder
	gridLayout.Parent          = tilesFrame

	-- SelectedFrame（選択済みタイル表示）
	local selectedFrame = Instance.new("Frame")
	selectedFrame.Name                    = "SelectedFrame"
	selectedFrame.Size                    = UDim2.new(1, -16, 0.18, 0)
	selectedFrame.Position                = UDim2.new(0, 8, 0.52, 0)
	selectedFrame.BackgroundColor3        = Color3.fromRGB(30, 40, 60)
	selectedFrame.BorderSizePixel         = 0
	selectedFrame.ClipsDescendants        = true
	selectedFrame.Parent                  = mainFrame

	local selCorner = Instance.new("UICorner")
	selCorner.CornerRadius = UDim.new(0, 8)
	selCorner.Parent       = selectedFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection    = Enum.FillDirection.Horizontal
	listLayout.Padding          = UDim.new(0, 4)
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder        = Enum.SortOrder.LayoutOrder
	listLayout.Parent           = selectedFrame

	-- SubmitButton（決定）
	local submitButton = Instance.new("TextButton")
	submitButton.Name                    = "SubmitButton"
	submitButton.Text                    = "決定"
	submitButton.Size                    = UDim2.new(0.5, 0, 0.12, 0)
	submitButton.Position                = UDim2.new(0.25, 0, 0.72, 0)
	submitButton.AnchorPoint             = Vector2.new(0, 0)
	submitButton.BackgroundColor3        = Color3.fromRGB(60, 120, 200)
	submitButton.TextColor3              = Color3.fromRGB(255, 255, 255)
	submitButton.Font                    = Enum.Font.GothamBold
	submitButton.TextSize                = 18
	submitButton.BorderSizePixel         = 0
	submitButton.Parent                  = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent       = submitButton

	-- FeedbackLabel（正誤フィードバック）
	local feedbackLabel = Instance.new("TextLabel")
	feedbackLabel.Name                    = "FeedbackLabel"
	feedbackLabel.Text                    = ""
	feedbackLabel.Size                    = UDim2.new(1, 0, 0.1, 0)
	feedbackLabel.Position                = UDim2.new(0, 0, 0.86, 0)
	feedbackLabel.BackgroundTransparency  = 1
	feedbackLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
	feedbackLabel.Font                    = Enum.Font.GothamBold
	feedbackLabel.TextSize                = 18
	feedbackLabel.Parent                  = mainFrame

	-- 既にスポーン済みのプレイヤーにも配布
	for _, p in ipairs(Players:GetPlayers()) do
		if p:FindFirstChild("PlayerGui") and not p.PlayerGui:FindFirstChild("FlashOutputGui") then
			screenGui:Clone().Parent = p.PlayerGui
		end
	end

	print("[MoWISE] FlashOutputGui created in StarterGui + distributed to existing players")
end

------------------------------------------------------------------------
-- Phase 1: InventoryHud（素材インベントリ常時表示）
------------------------------------------------------------------------
local function setupInventoryHud()
	if StarterGui:FindFirstChild("InventoryHud") then
		print("[MoWISE] InventoryHud already exists, skipping")
		return
	end

	local hud = Instance.new("ScreenGui")
	hud.Name           = "InventoryHud"
	hud.Enabled        = true
	hud.ResetOnSpawn   = false
	hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	hud.Parent         = StarterGui

	-- 背景フレーム（左上）
	local frame = Instance.new("Frame")
	frame.Name                    = "InventoryFrame"
	frame.AnchorPoint             = Vector2.new(0, 0)
	frame.Position                = UDim2.new(0, 12, 0, 12)
	frame.Size                    = UDim2.new(0, 180, 0, 124)
	frame.BackgroundColor3        = Color3.fromRGB(15, 20, 35)
	frame.BackgroundTransparency  = 0.25
	frame.BorderSizePixel         = 0
	frame.Parent                  = hud

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 10)
	frameCorner.Parent       = frame

	-- タイトル
	local title = Instance.new("TextLabel")
	title.Name                    = "Title"
	title.Text                    = "Materials"
	title.Size                    = UDim2.new(1, 0, 0, 22)
	title.Position                = UDim2.new(0, 0, 0, 4)
	title.BackgroundTransparency  = 1
	title.TextColor3              = Color3.fromRGB(200, 200, 220)
	title.Font                    = Enum.Font.GothamBold
	title.TextSize                = 13
	title.Parent                  = frame

	-- 素材行を生成するヘルパー
	local MATERIALS = {
		{ key = "Wood",   icon = "🪵", color = Color3.fromRGB(180, 120, 60)  },
		{ key = "Stone",  icon = "🪨", color = Color3.fromRGB(150, 150, 150) },
		{ key = "Flower", icon = "🌸", color = Color3.fromRGB(255, 150, 200) },
		{ key = "Seed",   icon = "🌱", color = Color3.fromRGB(120, 180, 80)  },
	}

	for i, mat in ipairs(MATERIALS) do
		local row = Instance.new("Frame")
		row.Name                    = mat.key .. "Row"
		row.Size                    = UDim2.new(1, -16, 0, 20)
		row.Position                = UDim2.new(0, 8, 0, 26 + (i - 1) * 24)
		row.BackgroundTransparency  = 1
		row.Parent                  = frame

		local icon = Instance.new("TextLabel")
		icon.Name                    = "Icon"
		icon.Text                    = mat.icon
		icon.Size                    = UDim2.new(0, 24, 1, 0)
		icon.BackgroundTransparency  = 1
		icon.TextSize                = 16
		icon.Font                    = Enum.Font.Gotham
		icon.Parent                  = row

		local label = Instance.new("TextLabel")
		label.Name                    = "Label"
		label.Text                    = mat.key
		label.Size                    = UDim2.new(0, 60, 1, 0)
		label.Position                = UDim2.new(0, 28, 0, 0)
		label.BackgroundTransparency  = 1
		label.TextColor3              = mat.color
		label.TextXAlignment          = Enum.TextXAlignment.Left
		label.Font                    = Enum.Font.GothamBold
		label.TextSize                = 14
		label.Parent                  = row

		local amount = Instance.new("TextLabel")
		amount.Name                    = "Amount"
		amount.Text                    = "0"
		amount.Size                    = UDim2.new(0, 50, 1, 0)
		amount.Position                = UDim2.new(1, -50, 0, 0)
		amount.BackgroundTransparency  = 1
		amount.TextColor3              = Color3.fromRGB(255, 255, 255)
		amount.TextXAlignment          = Enum.TextXAlignment.Right
		amount.Font                    = Enum.Font.GothamBold
		amount.TextSize                = 15
		amount.Parent                  = row
	end

	-- 既にスポーン済みのプレイヤーにも配布
	for _, p in ipairs(Players:GetPlayers()) do
		if p:FindFirstChild("PlayerGui") and not p.PlayerGui:FindFirstChild("InventoryHud") then
			hud:Clone().Parent = p.PlayerGui
		end
	end

	print("[MoWISE] InventoryHud created")
end

------------------------------------------------------------------------
-- API連動: LinkGui（アカウント連携画面）
------------------------------------------------------------------------
local function setupLinkGui()
	if StarterGui:FindFirstChild("LinkGui") then
		print("[MoWISE] LinkGui already exists, skipping")
		return
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name           = "LinkGui"
	screenGui.Enabled        = false
	screenGui.ResetOnSpawn   = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent         = StarterGui

	-- MainFrame（中央パネル）
	local mainFrame = Instance.new("Frame")
	mainFrame.Name                    = "MainFrame"
	mainFrame.AnchorPoint             = Vector2.new(0.5, 0.5)
	mainFrame.Position                = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.Size                    = UDim2.new(0, 420, 0, 360)
	mainFrame.BackgroundColor3        = Color3.fromRGB(20, 25, 45)
	mainFrame.BackgroundTransparency  = 0.05
	mainFrame.BorderSizePixel         = 0
	mainFrame.Parent                  = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent       = mainFrame

	-- TitleLabel
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name                    = "TitleLabel"
	titleLabel.Text                    = "MoWISE アカウント連携"
	titleLabel.Size                    = UDim2.new(1, 0, 0, 36)
	titleLabel.Position                = UDim2.new(0, 0, 0, 12)
	titleLabel.BackgroundTransparency  = 1
	titleLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
	titleLabel.Font                    = Enum.Font.GothamBold
	titleLabel.TextSize                = 20
	titleLabel.Parent                  = mainFrame

	-- DescLabel（説明文）
	local descLabel = Instance.new("TextLabel")
	descLabel.Name                    = "DescLabel"
	descLabel.Text                    = "MoWISE Webアプリと連携すると、\nWord Coins が 1.5倍になるよ！"
	descLabel.Size                    = UDim2.new(1, -32, 0, 44)
	descLabel.Position                = UDim2.new(0, 16, 0, 52)
	descLabel.BackgroundTransparency  = 1
	descLabel.TextColor3              = Color3.fromRGB(180, 200, 230)
	descLabel.Font                    = Enum.Font.Gotham
	descLabel.TextSize                = 14
	descLabel.TextWrapped             = true
	descLabel.Parent                  = mainFrame

	-- CodeFrame（コード表示エリア）
	local codeFrame = Instance.new("Frame")
	codeFrame.Name                    = "CodeFrame"
	codeFrame.AnchorPoint             = Vector2.new(0.5, 0)
	codeFrame.Position                = UDim2.new(0.5, 0, 0, 104)
	codeFrame.Size                    = UDim2.new(0, 320, 0, 70)
	codeFrame.BackgroundColor3        = Color3.fromRGB(30, 40, 65)
	codeFrame.BackgroundTransparency  = 0.2
	codeFrame.BorderSizePixel         = 0
	codeFrame.Parent                  = mainFrame

	local codeCorner = Instance.new("UICorner")
	codeCorner.CornerRadius = UDim.new(0, 10)
	codeCorner.Parent       = codeFrame

	-- CodeLabel（6桁コード）
	local codeLabel = Instance.new("TextLabel")
	codeLabel.Name                    = "CodeLabel"
	codeLabel.Text                    = "------"
	codeLabel.Size                    = UDim2.new(1, 0, 0, 36)
	codeLabel.Position                = UDim2.new(0, 0, 0, 8)
	codeLabel.BackgroundTransparency  = 1
	codeLabel.TextColor3              = Color3.fromRGB(255, 255, 255)
	codeLabel.Font                    = Enum.Font.Code
	codeLabel.TextSize                = 32
	codeLabel.Parent                  = codeFrame

	-- TimerLabel（残り時間）
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name                    = "TimerLabel"
	timerLabel.Text                    = ""
	timerLabel.Size                    = UDim2.new(1, 0, 0, 20)
	timerLabel.Position                = UDim2.new(0, 0, 0, 46)
	timerLabel.BackgroundTransparency  = 1
	timerLabel.TextColor3              = Color3.fromRGB(160, 160, 180)
	timerLabel.Font                    = Enum.Font.Gotham
	timerLabel.TextSize                = 13
	timerLabel.Parent                  = codeFrame

	-- StepsLabel（手順説明）
	local stepsLabel = Instance.new("TextLabel")
	stepsLabel.Name                    = "StepsLabel"
	stepsLabel.Text                    = "① MoWISE Webアプリを開く\n② 設定 → 「Roblox連携」をタップ\n③ 上のコードを入力する"
	stepsLabel.Size                    = UDim2.new(1, -32, 0, 56)
	stepsLabel.Position                = UDim2.new(0, 16, 0, 184)
	stepsLabel.BackgroundTransparency  = 1
	stepsLabel.TextColor3              = Color3.fromRGB(160, 170, 200)
	stepsLabel.Font                    = Enum.Font.Gotham
	stepsLabel.TextSize                = 13
	stepsLabel.TextWrapped             = true
	stepsLabel.TextXAlignment          = Enum.TextXAlignment.Left
	stepsLabel.TextYAlignment          = Enum.TextYAlignment.Top
	stepsLabel.Parent                  = mainFrame

	-- ReissueButton（コードを再発行）
	local reissueButton = Instance.new("TextButton")
	reissueButton.Name                    = "ReissueButton"
	reissueButton.Text                    = "コードを再発行"
	reissueButton.Size                    = UDim2.new(0, 150, 0, 36)
	reissueButton.Position                = UDim2.new(0, 24, 0, 260)
	reissueButton.BackgroundColor3        = Color3.fromRGB(60, 80, 130)
	reissueButton.TextColor3              = Color3.fromRGB(255, 255, 255)
	reissueButton.Font                    = Enum.Font.GothamBold
	reissueButton.TextSize                = 14
	reissueButton.BorderSizePixel         = 0
	reissueButton.Parent                  = mainFrame

	local reissueCorner = Instance.new("UICorner")
	reissueCorner.CornerRadius = UDim.new(0, 8)
	reissueCorner.Parent       = reissueButton

	-- CloseButton（あとで）
	local closeButton = Instance.new("TextButton")
	closeButton.Name                    = "CloseButton"
	closeButton.Text                    = "あとで"
	closeButton.Size                    = UDim2.new(0, 150, 0, 36)
	closeButton.Position                = UDim2.new(1, -174, 0, 260)
	closeButton.BackgroundColor3        = Color3.fromRGB(50, 50, 60)
	closeButton.TextColor3              = Color3.fromRGB(180, 180, 190)
	closeButton.Font                    = Enum.Font.GothamBold
	closeButton.TextSize                = 14
	closeButton.BorderSizePixel         = 0
	closeButton.Parent                  = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent       = closeButton

	-- StatusLabel（状態メッセージ）
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name                    = "StatusLabel"
	statusLabel.Text                    = ""
	statusLabel.Size                    = UDim2.new(1, -16, 0, 24)
	statusLabel.Position                = UDim2.new(0, 8, 0, 304)
	statusLabel.BackgroundTransparency  = 1
	statusLabel.TextColor3              = Color3.fromRGB(200, 200, 200)
	statusLabel.Font                    = Enum.Font.Gotham
	statusLabel.TextSize                = 12
	statusLabel.TextWrapped             = true
	statusLabel.Parent                  = mainFrame

	-- 注釈
	local noteLabel = Instance.new("TextLabel")
	noteLabel.Name                    = "NoteLabel"
	noteLabel.Text                    = "※ 連携しなくても遊べます。連携するとボーナスがもらえます。"
	noteLabel.Size                    = UDim2.new(1, -16, 0, 18)
	noteLabel.Position                = UDim2.new(0, 8, 0, 330)
	noteLabel.BackgroundTransparency  = 1
	noteLabel.TextColor3              = Color3.fromRGB(120, 120, 140)
	noteLabel.Font                    = Enum.Font.Gotham
	noteLabel.TextSize                = 11
	noteLabel.Parent                  = mainFrame

	-- 既にスポーン済みのプレイヤーにも配布
	for _, p in ipairs(Players:GetPlayers()) do
		if p:FindFirstChild("PlayerGui") and not p.PlayerGui:FindFirstChild("LinkGui") then
			screenGui:Clone().Parent = p.PlayerGui
		end
	end

	print("[MoWISE] LinkGui created")
end

------------------------------------------------------------------------
-- API連動: LinkTriggerZone（連携メニューを開くProximityPrompt）
------------------------------------------------------------------------
local function setupLinkTrigger()
	if Workspace:FindFirstChild("LinkTriggerZone") then
		print("[MoWISE] LinkTriggerZone already exists, skipping")
		return
	end

	local zone = Instance.new("Part")
	zone.Name          = "LinkTriggerZone"
	zone.Size          = Vector3.new(4, 6, 4)
	zone.Anchored      = true
	zone.CanCollide    = false
	zone.Transparency  = 0.6
	zone.Color         = Color3.fromRGB(180, 140, 255)
	zone.Material      = Enum.Material.Neon
	zone.Shape         = Enum.PartType.Cylinder
	zone.Position      = Vector3.new(15, 3, 0) -- FlashTrigger の近く
	zone.Parent        = Workspace

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name                  = "LinkTrigger"
	prompt.ActionText            = "MoWISEと連携"
	prompt.ObjectText            = "アカウント連携"
	prompt.MaxActivationDistance  = 8
	prompt.Parent                = zone

	-- OpenLinkMenu RemoteEvent を MoWISERemotes 内に作成
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local remotes = ReplicatedStorage:WaitForChild("MoWISERemotes", 10)
	if remotes then
		local openLinkMenu = Instance.new("RemoteEvent", remotes)
		openLinkMenu.Name  = "OpenLinkMenu"

		prompt.Triggered:Connect(function(player)
			openLinkMenu:FireClient(player)
		end)
	end

	print("[MoWISE] LinkTriggerZone placed at (15, 3, 0)")
end

------------------------------------------------------------------------
-- Phase 2: ワークベンチ（クラフト台）設置
------------------------------------------------------------------------
local function setupWorkbench()
	if Workspace:FindFirstChild("Workbench") then
		print("[MoWISE] Workbench already exists, skipping")
		return
	end

	local wb = Instance.new("Part")
	wb.Name      = "Workbench"
	wb.Size      = Vector3.new(3, 1.2, 2)
	wb.Material  = Enum.Material.Wood
	wb.Color     = Color3.fromRGB(120, 80, 40)
	wb.Anchored  = true
	wb.CFrame    = CFrame.new(20, 1.6, 20)  -- Zone1の整地エリア付近
	wb.Parent    = Workspace

	-- ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name                  = "CraftPrompt"
	prompt.ActionText            = "クラフトする"
	prompt.ObjectText            = "ワークベンチ"
	prompt.MaxActivationDistance  = 8
	prompt.Parent                = wb

	print("[MoWISE] Workbench placed at (20, 1.6, 20)")
end

------------------------------------------------------------------------
-- Phase 7: Zone 2（街の市場）地形生成
------------------------------------------------------------------------
local function setupZone2()
    if Workspace:FindFirstChild("Zone2Base") then
        print("[MoWISE] Zone2Base already exists, skipping")
        return
    end

    local ZONE2_CENTER = Vector3.new(0, 0, 300)

    -- Zone 2 地面（石畳で市場感を演出）
    local zone2Base = Instance.new("Part")
    zone2Base.Name      = "Zone2Base"
    zone2Base.Size      = Vector3.new(200, 1, 200)
    zone2Base.Position  = ZONE2_CENTER + Vector3.new(0, -0.5, 0)
    zone2Base.Anchored  = true
    zone2Base.Material  = Enum.Material.Cobblestone
    zone2Base.Color     = Color3.fromRGB(160, 150, 135)
    zone2Base.Parent    = Workspace

    -- Zone 2 看板
    local z2Sign = Instance.new("Part")
    z2Sign.Name       = "Zone2Sign"
    z2Sign.Size       = Vector3.new(8, 4, 0.5)
    z2Sign.Position   = ZONE2_CENTER + Vector3.new(0, 5, -95)
    z2Sign.Anchored   = true
    z2Sign.Material   = Enum.Material.Wood
    z2Sign.Color      = Color3.fromRGB(140, 100, 60)
    z2Sign.Parent     = Workspace

    local z2Label = Instance.new("SurfaceGui", z2Sign)
    z2Label.Face      = Enum.NormalId.Front
    local z2Text = Instance.new("TextLabel", z2Label)
    z2Text.Size       = UDim2.new(1, 0, 1, 0)
    z2Text.Text       = "Zone 2: Streets"
    z2Text.TextScaled = true
    z2Text.BackgroundTransparency = 1
    z2Text.TextColor3 = Color3.fromRGB(255, 240, 200)
    z2Text.Font       = Enum.Font.GothamBold

    print("[MoWISE] Zone 2 terrain generated")
end

------------------------------------------------------------------------
-- API連動: MoWISERemotes フォルダ作成（他スクリプトより先に実行）
------------------------------------------------------------------------
local function setupRemotes()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	if ReplicatedStorage:FindFirstChild("MoWISERemotes") then
		print("[MoWISE] MoWISERemotes already exists, skipping")
		return
	end

	local remotes = Instance.new("Folder")
	remotes.Name   = "MoWISERemotes"
	remotes.Parent = ReplicatedStorage

	print("[MoWISE] MoWISERemotes created in ReplicatedStorage")
end

------------------------------------------------------------------------
-- 実行（MoWISERemotes を最初に作成）
------------------------------------------------------------------------
setupRemotes()
setupLighting()
setupTerrain()
setupRuins()
setupFlashTrigger()
setupFlashOutputGui()
setupInventoryHud()
setupLinkGui()
setupLinkTrigger()
setupWorkbench()
setupZone2()

print("[MoWISE] === WorldSetup complete ===")
