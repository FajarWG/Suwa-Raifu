const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

// 1. SuwaCostumeConfig (14 premium presets in English & Japanese)
const costumeConfigSrc = `local CostumeConfig = {}

CostumeConfig.Presets = {
	-- 👘 TRADITIONAL & CULTURAL
	{
		id = "yukata_navy",
		name = "Navy Summer Yukata (紺の夏浴衣)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 12557329485,
		pants = 12557348926,
		description = "Traditional summer yukata, ideal for peaceful evening strolls along Lake Suwa.\\n諏訪湖の夕涼みや花火祭りにぴったりの伝統的な浴衣。"
	},
	{
		id = "yukata_sakura",
		name = "Sakura Floral Yukata (桜の浴衣)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 79326241303163,
		pants = 101332222597295,
		description = "Graceful soft pink sakura blossom yukata with an elegant obi sash.\\n淡い桜模様が華やかな、優美な夏祭り用レディース浴衣。"
	},
	{
		id = "miko_shrine",
		name = "Suwa Shrine Maiden (諏訪の巫女装束)",
		category = "Traditional",
		categoryIcon = "⛩️",
		shirt = 89608123771601,
		pants = 79227464689155,
		description = "Sacred red hakama and pure white vestments of the Suwa Taisha shrine maidens.\\n諏訪大社に仕える巫女の清らかな白衣と緋袴。"
	},
	{
		id = "haori_classic",
		name = "Nagano Heritage Haori (信州の羽織着物)",
		category = "Traditional",
		categoryIcon = "👘",
		shirt = 4901968882,
		pants = 4901972583,
		description = "Classic outer haori robe inspired by traditional Nagano countryside craftsmanship.\\n信州の豊かな自然と伝統が息づく気品ある羽織スタイル。"
	},

	-- 🎒 SCHOOL UNIFORMS
	{
		id = "gakuran_male",
		name = "Gakuran High School (男子学ラン制服)",
		category = "School",
		categoryIcon = "🎒",
		shirt = 6914550284,
		pants = 6914552071,
		description = "Classic Japanese high school boys uniform with golden buttons.\\n金ボタンが引き締める、凛々しく伝統的な男子高校生詰襟制服。"
	},
	{
		id = "sailor_female",
		name = "Classic Sailor Uniform (セーラー女子制服)",
		category = "School",
		categoryIcon = "🎒",
		shirt = 8959935056,
		pants = 1770015436,
		description = "Iconic navy pleated skirt and crisp neckerchief Japanese sailor uniform.\\n定番のネイビータイとプリーツスカートが清楚なセーラー服。"
	},

	-- 🌠 ANIME SPECIAL
	{
		id = "taki_tachibana",
		name = "Taki Tachibana - Your Name (立花 瀧)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 8047583641,
		pants = 8047585078,
		description = "Tokyo school uniform worn by Taki when searching for Itomori & Lake Suwa.\\n糸守と諏訪湖の記憶を辿る瀧の東京学生制服スタイル。"
	},
	{
		id = "mitsuha_miyamizu",
		name = "Mitsuha Miyamizu - Your Name (宮水 三葉)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 8661711667,
		pants = 8661713338,
		description = "Itomori High School sailor uniform with the iconic braided red ribbon.\\n組紐の赤リボンが心をつなぐ、三葉の糸守高校制服。"
	},
	{
		id = "tanjiro_kamado",
		name = "Tanjiro - Demon Slayer (竈門 炭治郎)",
		category = "Anime",
		categoryIcon = "⚔️",
		shirt = 3830911721,
		pants = 3830913164,
		description = "Iconic green & black checkered haori worn by the Demon Slayer Corps warrior.\\n市松模様の羽織が象徴的な、心優しき鬼殺隊士の装束。"
	},
	{
		id = "nezuko_kamado",
		name = "Nezuko - Demon Slayer (竈門 禰豆子)",
		category = "Anime",
		categoryIcon = "🌸",
		shirt = 3833290635,
		pants = 3833292415,
		description = "Pink asanoha geometric kimono with dark haori and checkered sash.\\n麻の葉文様の桜色着物と黒羽織を身に纏った可憐な姿。"
	},
	{
		id = "satoru_gojo",
		name = "Satoru Gojo - Jujutsu Kaisen (五条 悟)",
		category = "Anime",
		categoryIcon = "👁️",
		shirt = 6271928011,
		pants = 6271929319,
		description = "High-collar dark uniform worn by the strongest Jujutsu High teacher.\\n現代最強の呪術師が着こなすスタイリッシュな高専制服。"
	},

	-- 🎃 EVENT & FESTIVALS
	{
		id = "halloween_vampire",
		name = "Halloween Gothic Kimono (宵闇の着物)",
		category = "Event",
		categoryIcon = "🦇",
		shirt = 5683226955,
		pants = 5683228198,
		description = "Enchanting gothic dark-red kimono for mysterious lakeside Halloween nights.\\n諏訪の夜に映える妖美なゴシック・ハロウィン着物。"
	},
	{
		id = "halloween_pumpkin",
		name = "Pumpkin Festival Haori (南瓜の祭法被)",
		category = "Event",
		categoryIcon = "🎃",
		shirt = 7531776939,
		pants = 7531778216,
		description = "Vibrant orange & midnight black Jack-o'-Lantern festival festival coat.\\n鮮やかなカボチャ色と黒が祝祭を彩るハロウィン法被。"
	},
	{
		id = "kitsune_guardian",
		name = "Kitsune Shrine Guardian (白狐の霊装)",
		category = "Event",
		categoryIcon = "🦊",
		shirt = 3450917036,
		pants = 3450917639,
		description = "Sacred white fox spirit robe blessed for night lantern processions.\\n夜の灯籠祭りを清め守護する神聖な白狐の霊験装束。"
	},
}

CostumeConfig.Categories = {
	{ id = "All", label = "All / すべて" },
	{ id = "Traditional", label = "👘 Traditional / 和風" },
	{ id = "School", label = "🎒 School / 制服" },
	{ id = "Anime", label = "🌠 Anime / アニメ" },
	{ id = "Event", label = "🎃 Event / 祭" },
}

function CostumeConfig.GetById(id)
	for _, preset in ipairs(CostumeConfig.Presets) do
		if preset.id == id then
			return preset
		end
	end
	return nil
end

return CostumeConfig
`;

// 2. BebeqAvatarServer
const avatarServerSrc = `-- ServerScriptService.BebeqAvatarServer
-- Applies Suwa Life costumes to player characters safely and instantly
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local outfitEvent = ReplicatedStorage:FindFirstChild("ApplyOutfitEvent")
if not outfitEvent then
	outfitEvent = Instance.new("RemoteEvent")
	outfitEvent.Name = "ApplyOutfitEvent"
	outfitEvent.Parent = ReplicatedStorage
end

local CostumeConfig = require(ReplicatedStorage:WaitForChild("SuwaCostumeConfig"))

outfitEvent.OnServerEvent:Connect(function(player, action, outfitId)
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChild("Humanoid")
	if not hum then return end

	if action == "Apply" and outfitId then
		local preset = CostumeConfig.GetById(outfitId)
		if not preset then return end

		local currentDesc = hum:GetAppliedDescription() or Instance.new("HumanoidDescription")
		local currentEmotes = currentDesc:GetEmotes()
		local currentEquipped = currentDesc:GetEquippedEmotes()

		-- Clone current description to preserve body shape, hair, and accessories
		local newDesc = currentDesc:Clone()
		newDesc.Shirt = preset.shirt
		newDesc.Pants = preset.pants

		-- Preserve player equipped emotes
		pcall(function()
			newDesc:SetEmotes(currentEmotes)
			newDesc:SetEquippedEmotes(currentEquipped)
		end)

		local ok, err = pcall(function()
			hum:ApplyDescription(newDesc)
		end)
		if not ok then
			local shirt = char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", char)
			shirt.ShirtTemplate = "rbxassetid://" .. tostring(preset.shirt)
			local pants = char:FindFirstChildOfClass("Pants") or Instance.new("Pants", char)
			pants.PantsTemplate = "rbxassetid://" .. tostring(preset.pants)
		end

	elseif action == "Reset" then
		local success, defaultDesc = pcall(function()
			return Players:GetHumanoidDescriptionFromUserId(player.UserId)
		end)

		if success and defaultDesc then
			local currentDesc = hum:GetAppliedDescription()
			if currentDesc then
				pcall(function()
					defaultDesc:SetEmotes(currentDesc:GetEmotes())
					defaultDesc:SetEquippedEmotes(currentDesc:GetEquippedEmotes())
				end)
			end
			pcall(function()
				hum:ApplyDescription(defaultDesc)
			end)
		end
	end
end)
`;

// 3. BebeqAvatarLocal (English / Japanese bilingual interface with player avatar cloning preview)
const avatarLocalSrc = `-- StarterPlayerScripts.BebeqAvatarLocal
-- SUWA LIFE WARDROBE (Japanese & Anime Costume Catalog)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local outfitEvent = ReplicatedStorage:WaitForChild("ApplyOutfitEvent")
local CostumeConfig = require(ReplicatedStorage:WaitForChild("SuwaCostumeConfig"))
local Icon = require(ReplicatedStorage:WaitForChild("Icon"))

local selectedPreset = nil
local currentFilter = "All"
local previewRotConn = nil

-- ==========================================
-- 1. BUILD WARDROBE UI (ENGLISH & JAPANESE)
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OutfitCatalogGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0.84, 0, 0.80, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainAspectRatio = Instance.new("UIAspectRatioConstraint")
MainAspectRatio.AspectRatio = 1.48
MainAspectRatio.DominantAxis = Enum.DominantAxis.Height
MainAspectRatio.Parent = MainFrame

local UISizeConstraint = Instance.new("UISizeConstraint")
UISizeConstraint.MaxSize = Vector2.new(900, 600)
UISizeConstraint.MinSize = Vector2.new(340, 240)
UISizeConstraint.Parent = MainFrame

local UIScale = Instance.new("UIScale")
UIScale.Scale = 0
UIScale.Parent = MainFrame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(52, 52, 64)
Stroke.Thickness = 1.5
Stroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 24)
Title.Position = UDim2.new(0, 18, 0, 8)
Title.BackgroundTransparency = 1
Title.Text = "👘 SUWA LIFE WARDROBE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -60, 0, 16)
Subtitle.Position = UDim2.new(0, 18, 0, 32)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "諏訪ライフ 衣装カタログ  •  Free Japanese & Anime Outfits"
Subtitle.TextColor3 = Color3.fromRGB(155, 155, 175)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -44, 0, 10)
CloseBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 235)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = true
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- TabBar
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -36, 0, 32)
TabBar.Position = UDim2.new(0, 18, 0, 56)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 8)
TabListLayout.Parent = TabBar

-- Left: Scroll Container
local ListContainer = Instance.new("Frame")
ListContainer.Name = "ListContainer"
ListContainer.Size = UDim2.new(0.55, -12, 1, -104)
ListContainer.Position = UDim2.new(0, 18, 0, 96)
ListContainer.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
ListContainer.BorderSizePixel = 0
ListContainer.Parent = MainFrame
Instance.new("UICorner", ListContainer).CornerRadius = UDim.new(0, 10)
local listStroke = Instance.new("UIStroke", ListContainer)
listStroke.Color = Color3.fromRGB(42, 42, 52)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Name = "ScrollingFrame"
ScrollingFrame.Size = UDim2.new(1, -12, 1, -12)
ScrollingFrame.Position = UDim2.new(0, 6, 0, 6)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 115)
ScrollingFrame.Parent = ListContainer

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.Parent = ScrollingFrame

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 14)
end)

-- Right: 3D Preview Panel
local PreviewPanel = Instance.new("Frame")
PreviewPanel.Name = "PreviewPanel"
PreviewPanel.Size = UDim2.new(0.45, -24, 1, -104)
PreviewPanel.Position = UDim2.new(0.55, 12, 0, 96)
PreviewPanel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
PreviewPanel.BorderSizePixel = 0
PreviewPanel.Parent = MainFrame
Instance.new("UICorner", PreviewPanel).CornerRadius = UDim.new(0, 10)
local prevStroke = Instance.new("UIStroke", PreviewPanel)
prevStroke.Color = Color3.fromRGB(42, 42, 52)

local Viewport = Instance.new("ViewportFrame")
Viewport.Name = "Viewport"
Viewport.Size = UDim2.new(1, -20, 0.58, 0)
Viewport.Position = UDim2.new(0, 10, 0, 10)
Viewport.BackgroundTransparency = 1
Viewport.Parent = PreviewPanel

local WorldModel = Instance.new("WorldModel")
WorldModel.Name = "WorldModel"
WorldModel.Parent = Viewport

local PrevTitle = Instance.new("TextLabel")
PrevTitle.Name = "PrevTitle"
PrevTitle.Size = UDim2.new(1, -20, 0, 20)
PrevTitle.Position = UDim2.new(0, 10, 0.58, 12)
PrevTitle.BackgroundTransparency = 1
PrevTitle.Text = "Select an Outfit / 衣装を選択"
PrevTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevTitle.Font = Enum.Font.GothamBold
PrevTitle.TextSize = 13
PrevTitle.TextTruncate = Enum.TextTruncate.AtEnd
PrevTitle.Parent = PreviewPanel

local PrevDesc = Instance.new("TextLabel")
PrevDesc.Name = "PrevDesc"
PrevDesc.Size = UDim2.new(1, -20, 0, 38)
PrevDesc.Position = UDim2.new(0, 10, 0.58, 34)
PrevDesc.BackgroundTransparency = 1
PrevDesc.Text = "Click any costume from the list to preview.\\nリストから衣装を選んでプレビュー。"
PrevDesc.TextColor3 = Color3.fromRGB(150, 150, 170)
PrevDesc.Font = Enum.Font.Gotham
PrevDesc.TextSize = 11
PrevDesc.TextWrapped = true
PrevDesc.TextYAlignment = Enum.TextYAlignment.Top
PrevDesc.Parent = PreviewPanel

local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Name = "ApplyBtn"
ApplyBtn.Size = UDim2.new(1, -20, 0, 36)
ApplyBtn.Position = UDim2.new(0, 10, 1, -78)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(45, 120, 230)
ApplyBtn.Text = "✨ Equip Outfit / 着替える"
ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.TextSize = 13
ApplyBtn.AutoButtonColor = true
ApplyBtn.Parent = PreviewPanel
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 8)

local ResetBtn = Instance.new("TextButton")
ResetBtn.Name = "ResetBtn"
ResetBtn.Size = UDim2.new(1, -20, 0, 28)
ResetBtn.Position = UDim2.new(0, 10, 1, -36)
ResetBtn.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
ResetBtn.Text = "↺ Reset to Default / リセット"
ResetBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
ResetBtn.Font = Enum.Font.GothamMedium
ResetBtn.TextSize = 11
ResetBtn.AutoButtonColor = true
ResetBtn.Parent = PreviewPanel
Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 8)

-- Toast Notification
local Toast = Instance.new("TextLabel")
Toast.Size = UDim2.new(0.65, 0, 0, 32)
Toast.Position = UDim2.new(0.175, 0, 0, 12)
Toast.BackgroundColor3 = Color3.fromRGB(30, 115, 215)
Toast.TextColor3 = Color3.fromRGB(255, 255, 255)
Toast.Font = Enum.Font.GothamBold
Toast.TextSize = 12
Toast.Visible = false
Toast.ZIndex = 15
Toast.Parent = MainFrame
Instance.new("UICorner", Toast).CornerRadius = UDim.new(0, 8)

local function showToast(msg)
	Toast.Text = msg
	Toast.Visible = true
	Toast.BackgroundTransparency = 0
	Toast.TextTransparency = 0
	task.delay(2.5, function()
		if Toast and Toast.Parent then
			TweenService:Create(Toast, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			task.wait(0.3)
			Toast.Visible = false
		end
	end)
end

-- ==========================================
-- 2. 3D PREVIEW WITH REAL PLAYER CLONING
-- ==========================================
local camera3D = Instance.new("Camera")
camera3D.FieldOfView = 30
camera3D.Parent = Viewport
Viewport.CurrentCamera = camera3D

local function update3DPreview(preset)
	selectedPreset = preset
	PrevTitle.Text = preset.name
	PrevDesc.Text = preset.description

	WorldModel:ClearAllChildren()

	local dummy = nil
	local char = player.Character
	if char then
		char.Archivable = true
		local clone = char:Clone()
		char.Archivable = false
		if clone then
			for _, d in ipairs(clone:GetDescendants()) do
				if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("Sound") or d:IsA("ParticleEmitter") then
					d:Destroy()
				end
			end
			local hum = clone:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
			local shirt = clone:FindFirstChildOfClass("Shirt") or Instance.new("Shirt", clone)
			shirt.ShirtTemplate = "rbxassetid://" .. tostring(preset.shirt)
			local pants = clone:FindFirstChildOfClass("Pants") or Instance.new("Pants", clone)
			pants.PantsTemplate = "rbxassetid://" .. tostring(preset.pants)
			dummy = clone
		end
	end

	-- Fallback to warm-toned anime mannequin if player character is not ready
	if not dummy then
		local desc = Instance.new("HumanoidDescription")
		local skin = Color3.fromRGB(245, 215, 190)
		desc.HeadColor = skin; desc.TorsoColor = skin
		desc.LeftArmColor = skin; desc.RightArmColor = skin
		desc.LeftLegColor = skin; desc.RightLegColor = skin
		desc.Shirt = preset.shirt
		desc.Pants = preset.pants
		pcall(function()
			dummy = Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if dummy then
			local head = dummy:FindFirstChild("Head")
			if head and not head:FindFirstChildOfClass("Decal") then
				local face = Instance.new("Decal", head)
				face.Name = "face"
				face.Texture = "rbxasset://textures/face.png"
			end
		end
	end

	if dummy then
		dummy.Parent = WorldModel
		local hrp = dummy:FindFirstChild("HumanoidRootPart") or dummy:FindFirstChild("Torso") or dummy:FindFirstChild("UpperTorso")
		if hrp then
			hrp.Anchored = true
			local focusPos = hrp.Position + Vector3.new(0, 0.4, 0)
			camera3D.CFrame = CFrame.new(focusPos + Vector3.new(0, 0.5, -6.0), focusPos)

			if previewRotConn then previewRotConn:Disconnect() end
			local rotAngle = 0
			previewRotConn = RunService.RenderStepped:Connect(function(dt)
				if dummy and dummy.Parent and hrp then
					rotAngle = rotAngle + dt * 0.75
					local camDist = 6.0
					local camX = math.sin(rotAngle) * camDist
					local camZ = math.cos(rotAngle) * camDist
					camera3D.CFrame = CFrame.new(focusPos + Vector3.new(camX, 0.6, camZ), focusPos)
				end
			end)
		end
	end
end

-- ==========================================
-- 3. RENDER CARD LIST & CATEGORY TABS
-- ==========================================
local function renderList()
	for _, ch in ipairs(ScrollingFrame:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end

	for i, preset in ipairs(CostumeConfig.Presets) do
		if currentFilter == "All" or preset.category == currentFilter then
			local isSelected = (selectedPreset and selectedPreset.id == preset.id)
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 58)
			card.BackgroundColor3 = isSelected and Color3.fromRGB(42, 52, 72) or Color3.fromRGB(34, 34, 42)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			card.Parent = ScrollingFrame
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			local cStroke = Instance.new("UIStroke", card)
			cStroke.Color = isSelected and Color3.fromRGB(65, 135, 235) or Color3.fromRGB(46, 46, 56)
			cStroke.Thickness = isSelected and 1.5 or 1

			local iconBox = Instance.new("TextLabel")
			iconBox.Size = UDim2.new(0, 42, 0, 42)
			iconBox.Position = UDim2.new(0, 8, 0.5, -21)
			iconBox.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
			iconBox.Text = preset.categoryIcon or "👘"
			iconBox.TextSize = 22
			iconBox.Parent = card
			Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 6)

			local cTitle = Instance.new("TextLabel")
			cTitle.Size = UDim2.new(1, -125, 0, 20)
			cTitle.Position = UDim2.new(0, 58, 0, 8)
			cTitle.BackgroundTransparency = 1
			cTitle.Text = preset.name
			cTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			cTitle.Font = Enum.Font.GothamBold
			cTitle.TextSize = 13
			cTitle.TextXAlignment = Enum.TextXAlignment.Left
			cTitle.TextTruncate = Enum.TextTruncate.AtEnd
			cTitle.Parent = card

			local cSub = Instance.new("TextLabel")
			cSub.Size = UDim2.new(1, -125, 0, 18)
			cSub.Position = UDim2.new(0, 58, 0, 28)
			cSub.BackgroundTransparency = 1
			cSub.Text = preset.category .. "  •  Free to Wear (無料)"
			cSub.TextColor3 = Color3.fromRGB(140, 140, 155)
			cSub.Font = Enum.Font.Gotham
			cSub.TextSize = 11
			cSub.TextXAlignment = Enum.TextXAlignment.Left
			cSub.Parent = card

			local tryBtn = Instance.new("TextButton")
			tryBtn.Size = UDim2.new(0, 58, 0, 30)
			tryBtn.Position = UDim2.new(1, -66, 0.5, -15)
			tryBtn.BackgroundColor3 = isSelected and Color3.fromRGB(45, 120, 230) or Color3.fromRGB(48, 48, 58)
			tryBtn.Text = isSelected and "Viewing" or "Try / 試着"
			tryBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tryBtn.Font = Enum.Font.GothamMedium
			tryBtn.TextSize = 11
			tryBtn.AutoButtonColor = true
			tryBtn.Parent = card
			Instance.new("UICorner", tryBtn).CornerRadius = UDim.new(0, 6)

			local function selectThis()
				update3DPreview(preset)
				renderList()
			end

			tryBtn.MouseButton1Click:Connect(selectThis)

			local clickArea = Instance.new("TextButton")
			clickArea.Size = UDim2.new(1, -70, 1, 0)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.Parent = card
			clickArea.MouseButton1Click:Connect(selectThis)
		end
	end
end

-- Render Category Tabs
local tabButtons = {}
for _, cat in ipairs(CostumeConfig.Categories) do
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0, 0, 1, 0)
	tab.AutomaticSize = Enum.AutomaticSize.X
	tab.BackgroundColor3 = (cat.id == currentFilter) and Color3.fromRGB(45, 120, 230) or Color3.fromRGB(32, 32, 40)
	tab.Text = cat.label
	tab.TextColor3 = (cat.id == currentFilter) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 185)
	tab.Font = Enum.Font.GothamMedium
	tab.TextSize = 11
	tab.AutoButtonColor = true
	tab.Parent = TabBar
	Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)

	local tPad = Instance.new("UIPadding", tab)
	tPad.PaddingLeft = UDim.new(0, 12)
	tPad.PaddingRight = UDim.new(0, 12)

	tab.MouseButton1Click:Connect(function()
		currentFilter = cat.id
		for id, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = (id == currentFilter) and Color3.fromRGB(45, 120, 230) or Color3.fromRGB(32, 32, 40)
			btn.TextColor3 = (id == currentFilter) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 185)
		end
		renderList()
	end)
	tabButtons[cat.id] = tab
end

renderList()
if #CostumeConfig.Presets > 0 then
	update3DPreview(CostumeConfig.Presets[1])
end

-- ==========================================
-- 4. APPLY & RESET EVENT HANDLERS
-- ==========================================
ApplyBtn.MouseButton1Click:Connect(function()
	if selectedPreset then
		ApplyBtn.Text = "Equipping... / 着替え中..."
		outfitEvent:FireServer("Apply", selectedPreset.id)
		showToast("✨ Equipped: " .. selectedPreset.name .. "!")
		task.wait(0.6)
		ApplyBtn.Text = "✨ Equip Outfit / 着替える"
	end
end)

ResetBtn.MouseButton1Click:Connect(function()
	ResetBtn.Text = "Resetting... / リセット中..."
	outfitEvent:FireServer("Reset")
	showToast("↺ Avatar restored to default! / アバターを初期化しました！")
	task.wait(0.6)
	ResetBtn.Text = "↺ Reset to Default / リセット"
end)

-- ==========================================
-- 5. OPEN / CLOSE & TOPBARPLUS INTEGRATION
-- ==========================================
local isOpen = false
local openTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function OpenUI()
	isOpen = true
	MainFrame.Visible = true
	if #CostumeConfig.Presets > 0 then
		update3DPreview(selectedPreset or CostumeConfig.Presets[1])
	end
	TweenService:Create(UIScale, openTweenInfo, { Scale = 1 }):Play()
end

local function CloseUI()
	isOpen = false
	local tw = TweenService:Create(UIScale, closeTweenInfo, { Scale = 0 })
	tw:Play()
	tw.Completed:Once(function()
		if not isOpen then
			MainFrame.Visible = false
		end
	end)
end

local wardrobeIcon = Icon.new()
	:setLabel("Wardrobe")
	:setCaption("Suwa Life Wardrobe | 衣装カタログ")
	:bindEvent("selected", function() OpenUI() end)
	:bindEvent("deselected", function() CloseUI() end)

task.spawn(function()
	_G.SuwaTopbarApps = _G.SuwaTopbarApps or {}
	table.insert(_G.SuwaTopbarApps, wardrobeIcon)
end)

CloseBtn.MouseButton1Click:Connect(function()
	wardrobeIcon:deselect()
	CloseUI()
end)

MainFrame.Visible = false
`;

async function main() {
  console.log('Writing scratch files...');
  fs.writeFileSync('scripts/scratch_SuwaCostumeConfig.lua', costumeConfigSrc);
  fs.writeFileSync('scripts/scratch_BebeqAvatarServer.lua', avatarServerSrc);
  fs.writeFileSync('scripts/scratch_BebeqAvatarLocal.lua', avatarLocalSrc);

  console.log('Deploying to Roblox Studio...');

  // 1. ReplicatedStorage.SuwaCostumeConfig
  const deploy1 = `
local rs = game:GetService("ReplicatedStorage")
local mod = rs:FindFirstChild("SuwaCostumeConfig")
if not mod then
    mod = Instance.new("ModuleScript")
    mod.Name = "SuwaCostumeConfig"
    mod.Parent = rs
end
mod.Source = [===[${costumeConfigSrc}]===]
return "SuwaCostumeConfig updated!"
`;
  const res1 = await executeLuau(deploy1, 'Edit');
  console.log(res1.content[0].text);

  // 2. ServerScriptService.BebeqAvatarServer
  const deploy2 = `
local sss = game:GetService("ServerScriptService")
local s = sss:FindFirstChild("BebeqAvatarServer")
if not s then
    s = Instance.new("Script")
    s.Name = "BebeqAvatarServer"
    s.Parent = sss
end
s.Source = [===[${avatarServerSrc}]===]
return "BebeqAvatarServer updated!"
`;
  const res2 = await executeLuau(deploy2, 'Edit');
  console.log(res2.content[0].text);

  // 3. StarterPlayerScripts.BebeqAvatarLocal
  const deploy3 = `
local sps = game:GetService("StarterPlayer").StarterPlayerScripts
local s = sps:FindFirstChild("BebeqAvatarLocal")
if not s then
    s = Instance.new("LocalScript")
    s.Name = "BebeqAvatarLocal"
    s.Parent = sps
end
s.Source = [===[${avatarLocalSrc}]===]
return "BebeqAvatarLocal updated!"
`;
  const res3 = await executeLuau(deploy3, 'Edit');
  console.log(res3.content[0].text);

  console.log('ALL MODULES UPDATED TO BILINGUAL WARDROBE!');
}

main().catch(console.error);
