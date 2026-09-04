const fs = require('fs');
const { executeLuau } = require('./mcp-exec.js');

// 1. SuwaCostumeConfig source
const costumeConfigSrc = `local CostumeConfig = {}

CostumeConfig.Presets = {
	{
		id = "yukata_male",
		name = "Yukata Pria (Navy/Black)",
		category = "Budaya",
		categoryIcon = "👘",
		shirt = 12557329485,
		pants = 12557348926,
		description = "Yukata santai festival musim panas untuk pria di tepi Danau Suwa."
	},
	{
		id = "yukata_female",
		name = "Yukata Wanita (Sakura Pink)",
		category = "Budaya",
		categoryIcon = "👘",
		shirt = 79326241303163,
		pants = 101332222597295,
		description = "Yukata bermotif bunga sakura lembut untuk wanita di festival kembang api."
	},
	{
		id = "miko_shrine",
		name = "Miko Kuil (Suwa Taisha)",
		category = "Budaya",
		categoryIcon = "👘",
		shirt = 89608123771601,
		pants = 79227464689155,
		description = "Pakaian tradisional gadis kuil (Miko) penunggu Kuil Suwa Taisha."
	},
	{
		id = "haori_traditional",
		name = "Haori Kimono Tradisional",
		category = "Budaya",
		categoryIcon = "👘",
		shirt = 4901968882,
		pants = 4901972583,
		description = "Jubah kimono haori motif klasik perbukitan dan pedesaan Jepang."
	},
	{
		id = "gakuran_male",
		name = "Gakuran SMA Jepang",
		category = "Sekolah",
		categoryIcon = "🎒",
		shirt = 6914550284,
		pants = 6914552071,
		description = "Seragam formal sekolah menengah pria Jepang dengan kancing emas elegan."
	},
	{
		id = "sailor_female",
		name = "Sailor Fuku SMA Jepang",
		category = "Sekolah",
		categoryIcon = "🎒",
		shirt = 8959935056,
		pants = 1770015436,
		description = "Seragam pelaut klasik siswi Jepang dengan dasi pita dan rok lipit."
	},
	{
		id = "taki_kiminonawa",
		name = "Taki Tachibana (Your Name)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 6954255835,
		pants = 6954258490,
		description = "Seragam kemeja kasual Taki saat mencari Danau Itomori / Danau Suwa."
	},
	{
		id = "mitsuha_kiminonawa",
		name = "Mitsuha Miyamizu (Your Name)",
		category = "Anime",
		categoryIcon = "🌠",
		shirt = 5277682977,
		pants = 6477106900,
		description = "Seragam sekolah dengan pita merah ikonik Mitsuha di Kuil Miyamizu."
	},
	{
		id = "halloween_kimono",
		name = "Halloween Gothic Kimono",
		category = "Event",
		categoryIcon = "🎃",
		shirt = 11181822839,
		pants = 11181826079,
		description = "Kimono pesta malam Halloween bernuansa gelap dan labu mistis."
	},
	{
		id = "kitsune_shrine",
		name = "Kitsune Fox Shrine Spirit",
		category = "Event",
		categoryIcon = "🎃",
		shirt = 3450917036,
		pants = 3450917639,
		description = "Kostum rubah penjaga kuil Jepang (Kitsune) untuk festival malam."
	},
}

CostumeConfig.Categories = {
	{ id = "All", label = "Semua" },
	{ id = "Budaya", label = "👘 Budaya" },
	{ id = "Sekolah", label = "🎒 Sekolah" },
	{ id = "Anime", label = "🌠 Anime" },
	{ id = "Event", label = "🎃 Event" },
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

// 2. BebeqAvatarServer source
const avatarServerSrc = `-- ServerScriptService.BebeqAvatarServer
-- Mengaplikasikan kostum Suwa Life ke karakter pemain secara instan dan aman
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

		-- Kloning deskripsi karakter agar aksesoris, rambut, dan bentuk tubuh tetap sama
		local newDesc = currentDesc:Clone()
		newDesc.Shirt = preset.shirt
		newDesc.Pants = preset.pants

		-- Pertahankan emote pemain
		pcall(function()
			newDesc:SetEmotes(currentEmotes)
			newDesc:SetEquippedEmotes(currentEquipped)
		end)

		local ok, err = pcall(function()
			hum:ApplyDescription(newDesc)
		end)
		if not ok then
			-- Fallback langsung ke instance Shirt & Pants jika ApplyDescription terhambat
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

// 3. BebeqAvatarLocal source
const avatarLocalSrc = `-- StarterPlayerScripts.BebeqAvatarLocal
-- Katalog Kostum Suwa-Raifu (Jepang & Anime Edition)
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
local previewModel = nil
local previewRotConn = nil

-- ==========================================
-- 1. BANGUN UI KATALOG
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "OutfitCatalogGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0.82, 0, 0.78, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 26)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainAspectRatio = Instance.new("UIAspectRatioConstraint")
MainAspectRatio.AspectRatio = 1.48
MainAspectRatio.DominantAxis = Enum.DominantAxis.Height
MainAspectRatio.Parent = MainFrame

local UISizeConstraint = Instance.new("UISizeConstraint")
UISizeConstraint.MaxSize = Vector2.new(880, 580)
UISizeConstraint.MinSize = Vector2.new(340, 240)
UISizeConstraint.Parent = MainFrame

local UIScale = Instance.new("UIScale")
UIScale.Scale = 0
UIScale.Parent = MainFrame

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 12)
Corner.Parent = MainFrame

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(50, 50, 60)
Stroke.Thickness = 1.5
Stroke.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundTransparency = 1
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 0, 26)
Title.Position = UDim2.new(0, 18, 0, 6)
Title.BackgroundTransparency = 1
Title.Text = "👘 Katalog Kostum Suwa Life"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -60, 0, 16)
Subtitle.Position = UDim2.new(0, 18, 0, 30)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "Pilih kostum khas Jepang & anime gratis untuk dipakai di Suwa-Raifu!"
Subtitle.TextColor3 = Color3.fromRGB(160, 160, 175)
Subtitle.TextSize = 11
Subtitle.Font = Enum.Font.Gotham
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -44, 0, 9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
CloseBtn.TextSize = 15
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.AutoButtonColor = true
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)

-- Tab Kategori Bar
local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, -36, 0, 32)
TabBar.Position = UDim2.new(0, 18, 0, 54)
TabBar.BackgroundTransparency = 1
TabBar.Parent = MainFrame

local TabListLayout = Instance.new("UIListLayout")
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabListLayout.Padding = UDim.new(0, 8)
TabListLayout.Parent = TabBar

-- Panel Kiri: List Scroll
local ListContainer = Instance.new("Frame")
ListContainer.Size = UDim2.new(0.55, -12, 1, -102)
ListContainer.Position = UDim2.new(0, 18, 0, 94)
ListContainer.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
ListContainer.BorderSizePixel = 0
ListContainer.Parent = MainFrame
Instance.new("UICorner", ListContainer).CornerRadius = UDim.new(0, 10)
local listStroke = Instance.new("UIStroke", ListContainer)
listStroke.Color = Color3.fromRGB(42, 42, 50)

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, -12, 1, -12)
ScrollingFrame.Position = UDim2.new(0, 6, 0, 6)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 4
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
ScrollingFrame.Parent = ListContainer

local UIList = Instance.new("UIListLayout")
UIList.SortOrder = Enum.SortOrder.LayoutOrder
UIList.Padding = UDim.new(0, 8)
UIList.Parent = ScrollingFrame

UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 12)
end)

-- Panel Kanan: 3D Preview
local PreviewPanel = Instance.new("Frame")
PreviewPanel.Size = UDim2.new(0.45, -24, 1, -102)
PreviewPanel.Position = UDim2.new(0.55, 12, 0, 94)
PreviewPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
PreviewPanel.BorderSizePixel = 0
PreviewPanel.Parent = MainFrame
Instance.new("UICorner", PreviewPanel).CornerRadius = UDim.new(0, 10)
local prevStroke = Instance.new("UIStroke", PreviewPanel)
prevStroke.Color = Color3.fromRGB(42, 42, 50)

local Viewport = Instance.new("ViewportFrame")
Viewport.Size = UDim2.new(1, -20, 0.58, 0)
Viewport.Position = UDim2.new(0, 10, 0, 10)
Viewport.BackgroundTransparency = 1
Viewport.Parent = PreviewPanel

local WorldModel = Instance.new("WorldModel")
WorldModel.Parent = Viewport

local PrevTitle = Instance.new("TextLabel")
PrevTitle.Size = UDim2.new(1, -20, 0, 20)
PrevTitle.Position = UDim2.new(0, 10, 0.58, 12)
PrevTitle.BackgroundTransparency = 1
PrevTitle.Text = "Pilih Kostum"
PrevTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
PrevTitle.Font = Enum.Font.GothamBold
PrevTitle.TextSize = 14
PrevTitle.TextTruncate = Enum.TextTruncate.AtEnd
PrevTitle.Parent = PreviewPanel

local PrevDesc = Instance.new("TextLabel")
PrevDesc.Size = UDim2.new(1, -20, 0, 36)
PrevDesc.Position = UDim2.new(0, 10, 0.58, 34)
PrevDesc.BackgroundTransparency = 1
PrevDesc.Text = "Klik salah satu kostum di daftar sebelah kiri untuk mencoba."
PrevDesc.TextColor3 = Color3.fromRGB(150, 150, 165)
PrevDesc.Font = Enum.Font.Gotham
PrevDesc.TextSize = 11
PrevDesc.TextWrapped = true
PrevDesc.TextYAlignment = Enum.TextYAlignment.Top
PrevDesc.Parent = PreviewPanel

local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Size = UDim2.new(1, -20, 0, 36)
ApplyBtn.Position = UDim2.new(0, 10, 1, -78)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(50, 125, 235)
ApplyBtn.Text = "✨ Pakai Kostum (Apply)"
ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.TextSize = 13
ApplyBtn.AutoButtonColor = true
ApplyBtn.Parent = PreviewPanel
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 8)

local ResetBtn = Instance.new("TextButton")
ResetBtn.Size = UDim2.new(1, -20, 0, 28)
ResetBtn.Position = UDim2.new(0, 10, 1, -36)
ResetBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
ResetBtn.Text = "↺ Kembali ke Avatar Asli"
ResetBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
ResetBtn.Font = Enum.Font.GothamMedium
ResetBtn.TextSize = 11
ResetBtn.AutoButtonColor = true
ResetBtn.Parent = PreviewPanel
Instance.new("UICorner", ResetBtn).CornerRadius = UDim.new(0, 8)

-- Toast Feedback
local Toast = Instance.new("TextLabel")
Toast.Size = UDim2.new(0.6, 0, 0, 32)
Toast.Position = UDim2.new(0.2, 0, 0, 12)
Toast.BackgroundColor3 = Color3.fromRGB(35, 120, 220)
Toast.TextColor3 = Color3.fromRGB(255, 255, 255)
Toast.Font = Enum.Font.GothamBold
Toast.TextSize = 12
Toast.Visible = false
Toast.ZIndex = 10
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
-- 2. 3D PREVIEW MODEL & ROTASI
-- ==========================================
local camera3D = Instance.new("Camera")
camera3D.FieldOfView = 32
camera3D.Parent = Viewport
Viewport.CurrentCamera = camera3D

local function update3DPreview(preset)
	selectedPreset = preset
	PrevTitle.Text = preset.name
	PrevDesc.Text = preset.description

	WorldModel:ClearAllChildren()

	local desc = Instance.new("HumanoidDescription")
	desc.Shirt = preset.shirt
	desc.Pants = preset.pants

	-- Coba salin warna kulit dan aksesoris kepala pemain saat ini agar mirip pemain aslinya
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			local cDesc = hum:GetAppliedDescription()
			if cDesc then
				desc.HeadColor = cDesc.HeadColor
				desc.LeftArmColor = cDesc.LeftArmColor
				desc.RightArmColor = cDesc.RightArmColor
				desc.TorsoColor = cDesc.TorsoColor
				desc.LeftLegColor = cDesc.LeftLegColor
				desc.RightLegColor = cDesc.RightLegColor
				desc.HairAccessory = cDesc.HairAccessory
				desc.FaceAccessory = cDesc.FaceAccessory
			end
		end
	end

	local ok, dummy = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)

	if ok and dummy then
		previewModel = dummy
		dummy.Parent = WorldModel

		local hrp = dummy:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = true
			camera3D.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 1.2, -6.5), hrp.Position + Vector3.new(0, 0.4, 0))
		end

		-- Animasi rotasi halus
		if previewRotConn then previewRotConn:Disconnect() end
		local rotAngle = 0
		previewRotConn = RunService.RenderStepped:Connect(function(dt)
			if dummy and dummy.Parent and hrp then
				rotAngle = rotAngle + dt * 0.7
				local center = hrp.Position + Vector3.new(0, 0.4, 0)
				local camDist = 6.2
				local camX = math.sin(rotAngle) * camDist
				local camZ = math.cos(rotAngle) * camDist
				camera3D.CFrame = CFrame.new(center + Vector3.new(camX, 0.8, camZ), center)
			end
		end)
	end
end

-- ==========================================
-- 3. RENDER KARTU PRESET & FILTER
-- ==========================================
local cardButtons = {}

local function renderList()
	for _, ch in ipairs(ScrollingFrame:GetChildren()) do
		if ch:IsA("Frame") then ch:Destroy() end
	end
	cardButtons = {}

	for i, preset in ipairs(CostumeConfig.Presets) do
		if currentFilter == "All" or preset.category == currentFilter then
			local card = Instance.new("Frame")
			card.Size = UDim2.new(1, 0, 0, 58)
			card.BackgroundColor3 = (selectedPreset and selectedPreset.id == preset.id) and Color3.fromRGB(45, 55, 75) or Color3.fromRGB(36, 36, 44)
			card.BorderSizePixel = 0
			card.LayoutOrder = i
			card.Parent = ScrollingFrame
			Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

			local cStroke = Instance.new("UIStroke", card)
			cStroke.Color = (selectedPreset and selectedPreset.id == preset.id) and Color3.fromRGB(70, 140, 240) or Color3.fromRGB(48, 48, 58)
			cStroke.Thickness = (selectedPreset and selectedPreset.id == preset.id) and 1.5 or 1

			-- Icon box
			local iconBox = Instance.new("TextLabel")
			iconBox.Size = UDim2.new(0, 42, 0, 42)
			iconBox.Position = UDim2.new(0, 8, 0.5, -21)
			iconBox.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
			iconBox.Text = preset.categoryIcon or "👘"
			iconBox.TextSize = 22
			iconBox.Parent = card
			Instance.new("UICorner", iconBox).CornerRadius = UDim.new(0, 6)

			-- Title
			local cTitle = Instance.new("TextLabel")
			cTitle.Size = UDim2.new(1, -120, 0, 20)
			cTitle.Position = UDim2.new(0, 58, 0, 8)
			cTitle.BackgroundTransparency = 1
			cTitle.Text = preset.name
			cTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
			cTitle.Font = Enum.Font.GothamBold
			cTitle.TextSize = 13
			cTitle.TextXAlignment = Enum.TextXAlignment.Left
			cTitle.TextTruncate = Enum.TextTruncate.AtEnd
			cTitle.Parent = card

			-- Subtitle / Category
			local cSub = Instance.new("TextLabel")
			cSub.Size = UDim2.new(1, -120, 0, 18)
			cSub.Position = UDim2.new(0, 58, 0, 28)
			cSub.BackgroundTransparency = 1
			cSub.Text = preset.category .. "  •  Gratis"
			cSub.TextColor3 = Color3.fromRGB(140, 140, 155)
			cSub.Font = Enum.Font.Gotham
			cSub.TextSize = 11
			cSub.TextXAlignment = Enum.TextXAlignment.Left
			cSub.Parent = card

			-- Try button
			local tryBtn = Instance.new("TextButton")
			tryBtn.Size = UDim2.new(0, 54, 0, 30)
			tryBtn.Position = UDim2.new(1, -62, 0.5, -15)
			tryBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
			tryBtn.Text = "Coba"
			tryBtn.TextColor3 = Color3.fromRGB(220, 220, 240)
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

			-- Klik seluruh baris kartu untuk memilih
			local clickArea = Instance.new("TextButton")
			clickArea.Size = UDim2.new(1, -66, 1, 0)
			clickArea.BackgroundTransparency = 1
			clickArea.Text = ""
			clickArea.Parent = card
			clickArea.MouseButton1Click:Connect(selectThis)
		end
	end
end

-- Render Kategori Tabs
local tabButtons = {}
for _, cat in ipairs(CostumeConfig.Categories) do
	local tab = Instance.new("TextButton")
	tab.Size = UDim2.new(0, 72, 1, 0)
	tab.BackgroundColor3 = (cat.id == currentFilter) and Color3.fromRGB(50, 125, 235) or Color3.fromRGB(34, 34, 42)
	tab.Text = cat.label
	tab.TextColor3 = (cat.id == currentFilter) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 185)
	tab.Font = Enum.Font.GothamMedium
	tab.TextSize = 11
	tab.AutoButtonColor = true
	tab.Parent = TabBar
	Instance.new("UICorner", tab).CornerRadius = UDim.new(0, 6)

	tab.MouseButton1Click:Connect(function()
		currentFilter = cat.id
		for id, btn in pairs(tabButtons) do
			btn.BackgroundColor3 = (id == currentFilter) and Color3.fromRGB(50, 125, 235) or Color3.fromRGB(34, 34, 42)
			btn.TextColor3 = (id == currentFilter) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(170, 170, 185)
		end
		renderList()
	end)
	tabButtons[cat.id] = tab
end

-- Inisialisasi awal
renderList()
if #CostumeConfig.Presets > 0 then
	update3DPreview(CostumeConfig.Presets[1])
end

-- ==========================================
-- 4. APPLY & RESET EVENT HANDLERS
-- ==========================================
ApplyBtn.MouseButton1Click:Connect(function()
	if selectedPreset then
		ApplyBtn.Text = "Applying..."
		outfitEvent:FireServer("Apply", selectedPreset.id)
		showToast("✨ Kostum " .. selectedPreset.name .. " dipakai!")
		task.wait(0.6)
		ApplyBtn.Text = "✨ Pakai Kostum (Apply)"
	end
end)

ResetBtn.MouseButton1Click:Connect(function()
	ResetBtn.Text = "Resetting..."
	outfitEvent:FireServer("Reset")
	showToast("↺ Avatar dikembalikan ke pakaian asli!")
	task.wait(0.6)
	ResetBtn.Text = "↺ Kembali ke Avatar Asli"
end)

-- ==========================================
-- 5. BUKA / TUTUP & TOPBARPLUS INTEGRATION
-- ==========================================
local isOpen = false
local openTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local closeTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function OpenUI()
	isOpen = true
	MainFrame.Visible = true
	if #CostumeConfig.Presets > 0 and not selectedPreset then
		update3DPreview(CostumeConfig.Presets[1])
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

local outfitIcon = Icon.new()
	:setLabel("Avatar")
	:setCaption("Katalog Kostum Suwa Life")
	:bindEvent("selected", function() OpenUI() end)
	:bindEvent("deselected", function() CloseUI() end)

task.spawn(function()
	_G.SuwaTopbarApps = _G.SuwaTopbarApps or {}
	table.insert(_G.SuwaTopbarApps, outfitIcon)
end)

CloseBtn.MouseButton1Click:Connect(function()
	outfitIcon:deselect()
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

  // 1. Create or update ReplicatedStorage.SuwaCostumeConfig
  const deployConfig = `
local rs = game:GetService("ReplicatedStorage")
local mod = rs:FindFirstChild("SuwaCostumeConfig")
if not mod then
    mod = Instance.new("ModuleScript")
    mod.Name = "SuwaCostumeConfig"
    mod.Parent = rs
end
mod.Source = [===[${costumeConfigSrc}]===]
return "SuwaCostumeConfig deployed!"
`;
  const res1 = await executeLuau(deployConfig, 'Edit');
  console.log('Deploy SuwaCostumeConfig:', res1.content[0].text);

  // 2. Update ServerScriptService.BebeqAvatarServer
  const deployServer = `
local sss = game:GetService("ServerScriptService")
local s = sss:FindFirstChild("BebeqAvatarServer")
if not s then
    s = Instance.new("Script")
    s.Name = "BebeqAvatarServer"
    s.Parent = sss
end
s.Source = [===[${avatarServerSrc}]===]
return "BebeqAvatarServer deployed!"
`;
  const res2 = await executeLuau(deployServer, 'Edit');
  console.log('Deploy BebeqAvatarServer:', res2.content[0].text);

  // 3. Update StarterPlayerScripts.BebeqAvatarLocal
  const deployLocal = `
local sps = game:GetService("StarterPlayer").StarterPlayerScripts
local s = sps:FindFirstChild("BebeqAvatarLocal")
if not s then
    s = Instance.new("LocalScript")
    s.Name = "BebeqAvatarLocal"
    s.Parent = sps
end
s.Source = [===[${avatarLocalSrc}]===]
return "BebeqAvatarLocal deployed!"
`;
  const res3 = await executeLuau(deployLocal, 'Edit');
  console.log('Deploy BebeqAvatarLocal:', res3.content[0].text);

  console.log('ALL 3 MODULES DEPLOYED SUCCESSFULLY!');
}

main().catch(console.error);
