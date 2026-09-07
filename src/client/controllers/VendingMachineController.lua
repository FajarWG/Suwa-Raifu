--!strict

-- VendingMachineController.lua
-- Japanese Vending Machine (自動販売機) Client Interface:
-- 1. Prominently displays all available cold drinks and snacks.
-- 2. Fully bilingual UI (English & Japanese).
-- 3. Responsive on Mobile and PC via UIScaling.fit.
-- 4. Sound effects for coin insertion, button clicks, and dispenser drops.

local Players = game:GetService('Players')
local SoundService = game:GetService('SoundService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local VendingMachineController = {}

type VendingItem = {
	id: string,
	name: string,
	japanese: string,
	category: string,
	price: number,
	icon: string,
	color: Color3,
	tool: string,
}

local screenGui: ScreenGui? = nil
local mainWindow: Frame? = nil
local yenBadge: TextLabel? = nil
local itemsList: ScrollingFrame? = nil

local currentCatalog: { VendingItem } = {}
local currentFilter: string = 'all' -- 'all' | 'drink' | 'snack'
local currentYen: number = 500

-- Audio
local SOUND_COIN = 'rbxassetid://242135745'

local function playLocalSound(soundId: string)
	local s = Instance.new('Sound')
	s.SoundId = soundId
	s.Volume = 0.8
	s.Parent = SoundService
	s:Play()
	game:GetService('Debris'):AddItem(s, 2)
end

local function refreshItemList()
	if not itemsList then return end

	-- Clear previous item cards
	for _, child in ipairs(itemsList:GetChildren()) do
		if child:IsA('Frame') and child.Name:find('ItemCard_') then
			child:Destroy()
		end
	end

	for _, item in ipairs(currentCatalog) do
		if currentFilter ~= 'all' and item.category ~= currentFilter then
			continue
		end

		local card = Instance.new('Frame')
		card.Name = `ItemCard_{item.id}`
		card.BackgroundColor3 = Color3.fromRGB(32, 36, 46)
		card.BorderSizePixel = 0
		card.ZIndex = 3

		local cCorner = Instance.new('UICorner')
		cCorner.CornerRadius = UDim.new(0, 10)
		cCorner.Parent = card

		local cStroke = Instance.new('UIStroke')
		cStroke.Color = Color3.fromRGB(55, 62, 78)
		cStroke.Thickness = 1.2
		cStroke.Parent = card

		-- Icon Badge (Left)
		local iconBg = Instance.new('Frame')
		iconBg.Name = 'IconBg'
		iconBg.AnchorPoint = Vector2.new(0, 0.5)
		iconBg.Position = UDim2.new(0, 10, 0.5, 0)
		iconBg.Size = UDim2.fromOffset(48, 48)
		iconBg.BackgroundColor3 = item.color or Color3.fromRGB(50, 55, 70)
		iconBg.BorderSizePixel = 0
		iconBg.ZIndex = 4

		local iCorner = Instance.new('UICorner')
		iCorner.CornerRadius = UDim.new(0, 8)
		iCorner.Parent = iconBg

		local iconLbl = Instance.new('TextLabel')
		iconLbl.BackgroundTransparency = 1
		iconLbl.Size = UDim2.fromScale(1, 1)
		iconLbl.Font = Enum.Font.FredokaOne
		iconLbl.TextSize = 24
		iconLbl.Text = item.icon or '🥤'
		iconLbl.ZIndex = 4
		iconLbl.Parent = iconBg
		iconBg.Parent = card

		-- Title & Japanese name
		local titleLbl = Instance.new('TextLabel')
		titleLbl.Name = 'Title'
		titleLbl.BackgroundTransparency = 1
		titleLbl.Position = UDim2.new(0, 68, 0, 8)
		titleLbl.Size = UDim2.new(1, -165, 0, 18)
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.TextSize = 14
		titleLbl.TextColor3 = Color3.fromRGB(245, 248, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		titleLbl.Text = item.name
		titleLbl.ZIndex = 4
		titleLbl.Parent = card

		local subLbl = Instance.new('TextLabel')
		subLbl.Name = 'Sub'
		subLbl.BackgroundTransparency = 1
		subLbl.Position = UDim2.new(0, 68, 0, 26)
		subLbl.Size = UDim2.new(1, -165, 0, 16)
		subLbl.Font = Enum.Font.FredokaOne
		subLbl.TextSize = 12
		subLbl.TextColor3 = Color3.fromRGB(160, 175, 195)
		subLbl.TextXAlignment = Enum.TextXAlignment.Left
		subLbl.TextTruncate = Enum.TextTruncate.AtEnd
		subLbl.Text = item.japanese
		subLbl.ZIndex = 4
		subLbl.Parent = card

		-- Price
		local priceLbl = Instance.new('TextLabel')
		priceLbl.Name = 'Price'
		priceLbl.BackgroundTransparency = 1
		priceLbl.Position = UDim2.new(0, 68, 0, 44)
		priceLbl.Size = UDim2.new(1, -165, 0, 18)
		priceLbl.Font = Enum.Font.FredokaOne
		priceLbl.TextSize = 14
		priceLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
		priceLbl.TextXAlignment = Enum.TextXAlignment.Left
		priceLbl.Text = `¥{item.price}`
		priceLbl.ZIndex = 4
		priceLbl.Parent = card

		-- Buy Button (Right)
		local buyBtn = Instance.new('TextButton')
		buyBtn.Name = 'BuyBtn'
		buyBtn.AnchorPoint = Vector2.new(1, 0.5)
		buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
		buyBtn.Size = UDim2.fromOffset(86, 36)
		buyBtn.BackgroundColor3 = if item.category == 'drink' then Color3.fromRGB(25, 105, 215) else Color3.fromRGB(215, 95, 25)
		buyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		buyBtn.Text = 'Buy / 買う'
		buyBtn.Font = Enum.Font.FredokaOne
		buyBtn.TextSize = 13
		buyBtn.ZIndex = 4

		local bCorner = Instance.new('UICorner')
		bCorner.CornerRadius = UDim.new(0, 8)
		bCorner.Parent = buyBtn

		buyBtn.MouseButton1Click:Connect(function()
			playLocalSound(SOUND_COIN)
			buyBtn.Text = 'Dispensing...'
			buyBtn.BackgroundColor3 = Color3.fromRGB(70, 80, 100)

			RemoteController.fire('VendingBuy', item.id)

			task.delay(0.6, function()
				if buyBtn and buyBtn.Parent then
					buyBtn.Text = 'Buy / 買う'
					buyBtn.BackgroundColor3 = if item.category == 'drink' then Color3.fromRGB(25, 105, 215) else Color3.fromRGB(215, 95, 25)
				end
			end)
		end)

		buyBtn.Parent = card
		card.Parent = itemsList
	end
end

local function createUI()
	if screenGui then screenGui:Destroy() end

	screenGui = Instance.new('ScreenGui')
	screenGui.Name = 'VendingMachineScreenGui'
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dim background overlay (passive Frame, never accidentally closes)
	local overlay = Instance.new('Frame')
	overlay.Name = 'Overlay'
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.55
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = screenGui

	-- Main Window
	mainWindow = Instance.new('Frame')
	mainWindow.Name = 'MainWindow'
	mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	mainWindow.Position = UDim2.fromScale(0.5, 0.5)
	mainWindow.Size = UDim2.fromOffset(680, 520)
	mainWindow.BackgroundColor3 = Color3.fromRGB(22, 25, 32)
	mainWindow.BorderSizePixel = 0
	mainWindow.Active = true
	mainWindow.ZIndex = 2

	local mainCorner = Instance.new('UICorner')
	mainCorner.CornerRadius = UDim.new(0, 14)
	mainCorner.Parent = mainWindow

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(55, 62, 78)
	stroke.Thickness = 1.5
	stroke.Parent = mainWindow
	mainWindow.Parent = screenGui

	-- Mobile responsive auto-scaling
	UIScaling.fit(mainWindow)

	-- Header
	local header = Instance.new('Frame')
	header.Name = 'Header'
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundTransparency = 1
	header.ZIndex = 3
	header.Parent = mainWindow

	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 18, 0, 0)
	title.Size = UDim2.new(0.55, 0, 1, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 18
	title.TextColor3 = Color3.fromRGB(240, 245, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = '🥤 Vending Machine / 自動販売機'
	title.ZIndex = 3
	title.Parent = header

	-- Yen Balance Badge
	yenBadge = Instance.new('TextLabel')
	yenBadge.Name = 'YenBadge'
	yenBadge.AnchorPoint = Vector2.new(1, 0.5)
	yenBadge.Position = UDim2.new(1, -66, 0.5, 0)
	yenBadge.Size = UDim2.fromOffset(130, 32)
	yenBadge.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
	yenBadge.TextColor3 = Color3.fromRGB(255, 215, 80)
	yenBadge.Font = Enum.Font.FredokaOne
	yenBadge.TextSize = 15
	yenBadge.Text = `💰 ¥{currentYen}`
	yenBadge.ZIndex = 3

	local yCorner = Instance.new('UICorner')
	yCorner.CornerRadius = UDim.new(0, 8)
	yCorner.Parent = yenBadge
	local yStroke = Instance.new('UIStroke')
	yStroke.Color = Color3.fromRGB(70, 78, 95)
	yStroke.Thickness = 1
	yStroke.Parent = yenBadge
	yenBadge.Parent = header

	-- Red Close Button
	local closeBtn = Instance.new('TextButton')
	closeBtn.Name = 'CloseBtn'
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(40, 40)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = '✕'
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.ZIndex = 4

	local closeCorner = Instance.new('UICorner')
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn
	closeBtn.Parent = header

	closeBtn.MouseButton1Click:Connect(function()
		VendingMachineController.close()
	end)

	-- Category Tabs Row
	local tabRow = Instance.new('Frame')
	tabRow.Name = 'TabRow'
	tabRow.Position = UDim2.new(0, 18, 0, 54)
	tabRow.Size = UDim2.new(1, -36, 0, 36)
	tabRow.BackgroundTransparency = 1
	tabRow.ZIndex = 3
	tabRow.Parent = mainWindow

	local tabLayout = Instance.new('UIListLayout')
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 8)
	tabLayout.Parent = tabRow

	local tabs = {
		{ id = 'all', text = 'All / すべて' },
		{ id = 'drink', text = '❄️ Cold Drinks / つめたい' },
		{ id = 'snack', text = '🍪 Snacks / お菓子' },
	}

	local tabButtons: { [string]: TextButton } = {}

	for _, tab in ipairs(tabs) do
		local tBtn = Instance.new('TextButton')
		tBtn.Name = `Tab_{tab.id}`
		tBtn.Size = UDim2.fromOffset(if tab.id == 'all' then 100 else 185, 34)
		tBtn.BackgroundColor3 = if tab.id == currentFilter then Color3.fromRGB(45, 95, 200) else Color3.fromRGB(32, 36, 46)
		tBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		tBtn.Text = tab.text
		tBtn.Font = Enum.Font.FredokaOne
		tBtn.TextSize = 13
		tBtn.ZIndex = 3

		local tCorner = Instance.new('UICorner')
		tCorner.CornerRadius = UDim.new(0, 8)
		tCorner.Parent = tBtn

		tBtn.MouseButton1Click:Connect(function()
			currentFilter = tab.id
			for id, btn in pairs(tabButtons) do
				btn.BackgroundColor3 = if id == currentFilter then Color3.fromRGB(45, 95, 200) else Color3.fromRGB(32, 36, 46)
			end
			refreshItemList()
		end)

		tabButtons[tab.id] = tBtn
		tBtn.Parent = tabRow
	end

	-- Items Scroll Container
	itemsList = Instance.new('ScrollingFrame')
	itemsList.Name = 'ItemsList'
	itemsList.Position = UDim2.new(0, 18, 0, 98)
	itemsList.Size = UDim2.new(1, -36, 1, -112)
	itemsList.BackgroundTransparency = 1
	itemsList.BorderSizePixel = 0
	itemsList.ScrollBarThickness = 6
	itemsList.ScrollBarImageColor3 = Color3.fromRGB(80, 90, 110)
	itemsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemsList.ZIndex = 3
	itemsList.Parent = mainWindow

	local gridLayout = Instance.new('UIGridLayout')
	gridLayout.CellSize = UDim2.fromOffset(314, 70)
	gridLayout.CellPadding = UDim2.fromOffset(12, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemsList
end

function VendingMachineController.open(data: any)
	currentCatalog = (data and data.catalog) or currentCatalog
	currentYen = (data and data.yen) or currentYen

	if not screenGui then
		createUI()
	end

	if yenBadge then
		yenBadge.Text = `💰 ¥{currentYen}`
	end

	refreshItemList()

	if screenGui then
		screenGui.Enabled = true
	end
end

function VendingMachineController.close()
	if screenGui then
		screenGui.Enabled = false
	end
end

function VendingMachineController.init()
	RemoteController.onEvent('VendingOpen', function(data: any)
		VendingMachineController.open(data)
	end)

	RemoteController.onEvent('ProfileUpdated', function(profile: any)
		if profile and profile.economy and profile.economy.yen then
			currentYen = profile.economy.yen
			if yenBadge then
				yenBadge.Text = `💰 ¥{currentYen}`
			end
		end
	end)

	print('[VendingMachineController] Initialized bilingual Japanese Vending Machine GUI')
end

return VendingMachineController
