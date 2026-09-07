--!strict

-- SushiRestaurantController.lua
-- Suwa Sushi Restaurant (諏訪すし店) Client Controller:
-- 1. Handles Takeaway mode (from Cash Register / レジ係)
-- 2. Handles Dine-In mode (floating HUD button appears when seated on restaurant chairs)
-- 3. Staff interaction: Waiter Ren delivers dish to table, Cashier Akira packages takeaway
-- 4. Premium bilingual UI (English / Japanese) responsive on PC and Mobile via UIScaling.

local Players = game:GetService('Players')
local SoundService = game:GetService('SoundService')
local TweenService = game:GetService('TweenService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local SushiRestaurantController = {}

type SushiItem = {
	id: string,
	name: string,
	japanese: string,
	category: string,
	price: number,
	icon: string,
	color: Color3,
	stats: string,
}

local screenGui: ScreenGui? = nil
local mainWindow: Frame? = nil
local headerTitle: TextLabel? = nil
local modeBadge: TextLabel? = nil
local yenBadge: TextLabel? = nil
local itemsList: ScrollingFrame? = nil
local floatingOrderBtn: TextButton? = nil

local currentCatalog: { SushiItem } = {
	{
		id = 'sushi_salmon_nigiri',
		name = 'Salmon Nigiri',
		japanese = 'サーモン握り',
		category = 'sushi',
		price = 450,
		icon = '🍣',
		color = Color3.fromRGB(240, 110, 80),
		stats = '+35 Hunger / 満腹度',
	},
	{
		id = 'sushi_maguro_nigiri',
		name = 'Maguro Nigiri',
		japanese = '本マグロ握り',
		category = 'sushi',
		price = 550,
		icon = '🍣',
		color = Color3.fromRGB(200, 60, 70),
		stats = '+40 Hunger / 満腹度',
	},
	{
		id = 'sushi_california_roll',
		name = 'California Roll',
		japanese = 'カリフォルニアロール',
		category = 'sushi',
		price = 600,
		icon = '🍱',
		color = Color3.fromRGB(100, 160, 90),
		stats = '+45 Hunger / 満腹度',
	},
	{
		id = 'sushi_sashimi_combo',
		name = 'Sashimi Combo Platter',
		japanese = '特選刺身盛り合わせ',
		category = 'sushi',
		price = 1200,
		icon = '🍱',
		color = Color3.fromRGB(220, 90, 100),
		stats = '+70 Hunger, +20 Energy',
	},
	{
		id = 'sushi_tempura_platter',
		name = 'Crispy Tempura Platter',
		japanese = '天ぷら盛り合わせ',
		category = 'dish',
		price = 850,
		icon = '🍤',
		color = Color3.fromRGB(230, 160, 50),
		stats = '+50 Hunger / 満腹度',
	},
	{
		id = 'sushi_miso_soup',
		name = 'Wakame Miso Soup',
		japanese = 'わかめ豆腐味噌汁',
		category = 'dish',
		price = 200,
		icon = '🥣',
		color = Color3.fromRGB(180, 130, 70),
		stats = '+15 Hunger, +15 Energy',
	},
	{
		id = 'sushi_edamame',
		name = 'Salted Edamame',
		japanese = '枝豆',
		category = 'dish',
		price = 250,
		icon = '🫛',
		color = Color3.fromRGB(90, 170, 70),
		stats = '+15 Hunger / 満腹度',
	},
	{
		id = 'sushi_green_tea',
		name = 'Uji Matcha Green Tea',
		japanese = '宇治抹茶・緑茶',
		category = 'drink',
		price = 150,
		icon = '🍵',
		color = Color3.fromRGB(60, 140, 80),
		stats = '+25 Energy / スタミナ',
	},
}

local currentMode: string = 'takeaway' -- 'takeaway' | 'dine_in'
local currentTableId: string = ''
local currentFilter: string = 'all' -- 'all' | 'sushi' | 'dish' | 'drink'
local currentYen: number = 1000
local isCurrentlySeatedAtSushi: boolean = false
local currentSeatPart: Seat? = nil

-- Audio
local SOUND_COIN = 'rbxassetid://242135745'
local SOUND_SERVE = 'rbxassetid://9114221764'

local function playLocalSound(soundId: string)
	local s = Instance.new('Sound')
	s.SoundId = soundId
	s.Volume = 0.85
	s.Parent = SoundService
	s:Play()
	game:GetService('Debris'):AddItem(s, 2)
end

local function refreshItemList()
	if not itemsList then return end

	-- Clear old cards
	for _, child in ipairs(itemsList:GetChildren()) do
		if child:IsA('Frame') and child.Name:find('Card_') then
			child:Destroy()
		end
	end

	for _, item in ipairs(currentCatalog) do
		if currentFilter ~= 'all' and item.category ~= currentFilter then
			continue
		end

		local canAfford = currentYen >= item.price

		local card = Instance.new('Frame')
		card.Name = `Card_{item.id}`
		card.BackgroundColor3 = Color3.fromRGB(26, 30, 40)
		card.BorderSizePixel = 0
		card.ZIndex = 4

		local cCorner = Instance.new('UICorner')
		cCorner.CornerRadius = UDim.new(0, 10)
		cCorner.Parent = card

		local cStroke = Instance.new('UIStroke')
		cStroke.Color = if canAfford then Color3.fromRGB(60, 68, 86) else Color3.fromRGB(45, 48, 58)
		cStroke.Thickness = 1.2
		cStroke.Parent = card

		-- Icon Badge (Left)
		local iconBg = Instance.new('Frame')
		iconBg.Name = 'IconBg'
		iconBg.AnchorPoint = Vector2.new(0, 0.5)
		iconBg.Position = UDim2.new(0, 10, 0.5, 0)
		iconBg.Size = UDim2.fromOffset(50, 50)
		iconBg.BackgroundColor3 = item.color or Color3.fromRGB(50, 55, 70)
		iconBg.BorderSizePixel = 0
		iconBg.ZIndex = 5
		iconBg.Parent = card

		local iCorner = Instance.new('UICorner')
		iCorner.CornerRadius = UDim.new(0, 8)
		iCorner.Parent = iconBg

		local iconLbl = Instance.new('TextLabel')
		iconLbl.BackgroundTransparency = 1
		iconLbl.Size = UDim2.fromScale(1, 1)
		iconLbl.Font = Enum.Font.FredokaOne
		iconLbl.TextSize = 24
		iconLbl.Text = item.icon
		iconLbl.ZIndex = 6
		iconLbl.Parent = iconBg

		-- Text Information Container (Middle)
		local textContainer = Instance.new('Frame')
		textContainer.Name = 'TextInfo'
		textContainer.BackgroundTransparency = 1
		textContainer.Position = UDim2.new(0, 68, 0, 8)
		textContainer.Size = UDim2.new(1, -190, 1, -16)
		textContainer.ZIndex = 5
		textContainer.Parent = card

		local titleLbl = Instance.new('TextLabel')
		titleLbl.Name = 'Title'
		titleLbl.BackgroundTransparency = 1
		titleLbl.Size = UDim2.new(1, 0, 0, 20)
		titleLbl.Font = Enum.Font.FredokaOne
		titleLbl.TextSize = 15
		titleLbl.TextColor3 = Color3.fromRGB(245, 248, 255)
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.Text = item.name
		titleLbl.ZIndex = 5
		titleLbl.Parent = textContainer

		local jpLbl = Instance.new('TextLabel')
		jpLbl.Name = 'Japanese'
		jpLbl.BackgroundTransparency = 1
		jpLbl.Position = UDim2.new(0, 0, 0, 21)
		jpLbl.Size = UDim2.new(1, 0, 0, 16)
		jpLbl.Font = Enum.Font.GothamMedium
		jpLbl.TextSize = 12
		jpLbl.TextColor3 = Color3.fromRGB(225, 185, 110)
		jpLbl.TextXAlignment = Enum.TextXAlignment.Left
		jpLbl.Text = item.japanese
		jpLbl.ZIndex = 5
		jpLbl.Parent = textContainer

		local statsLbl = Instance.new('TextLabel')
		statsLbl.Name = 'Stats'
		statsLbl.BackgroundTransparency = 1
		statsLbl.Position = UDim2.new(0, 0, 0, 39)
		statsLbl.Size = UDim2.new(1, 0, 0, 14)
		statsLbl.Font = Enum.Font.Gotham
		statsLbl.TextSize = 11
		statsLbl.TextColor3 = Color3.fromRGB(130, 200, 140)
		statsLbl.TextXAlignment = Enum.TextXAlignment.Left
		statsLbl.Text = item.stats or ''
		statsLbl.ZIndex = 5
		statsLbl.Parent = textContainer

		-- Action Button (Right)
		local orderBtn = Instance.new('TextButton')
		orderBtn.Name = 'OrderBtn'
		orderBtn.AnchorPoint = Vector2.new(1, 0.5)
		orderBtn.Position = UDim2.new(1, -12, 0.5, 0)
		orderBtn.Size = UDim2.fromOffset(108, 48)
		orderBtn.BorderSizePixel = 0
		orderBtn.ZIndex = 6
		orderBtn.AutoButtonColor = canAfford

		local oCorner = Instance.new('UICorner')
		oCorner.CornerRadius = UDim.new(0, 8)
		oCorner.Parent = orderBtn

		if canAfford then
			orderBtn.BackgroundColor3 = Color3.fromRGB(38, 140, 75)
			orderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
			orderBtn.Text = `¥{item.price}\n` .. (if currentMode == 'takeaway' then 'Takeaway / 持帰' else 'Order / 席で注文')
		else
			orderBtn.BackgroundColor3 = Color3.fromRGB(50, 53, 62)
			orderBtn.TextColor3 = Color3.fromRGB(150, 155, 165)
			orderBtn.Text = `¥{item.price}\nNo Yen / 不足`
		end
		orderBtn.Font = Enum.Font.FredokaOne
		orderBtn.TextSize = 12
		orderBtn.Parent = card

		if canAfford then
			orderBtn.MouseButton1Click:Connect(function()
				playLocalSound(SOUND_COIN)
				-- Feedback pulse animation
				local origSize = orderBtn.Size
				orderBtn.Size = UDim2.fromOffset(102, 44)
				TweenService:Create(orderBtn, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = origSize,
				}):Play()

				-- Send order to server
				if currentMode == 'dine_in' then
					isOrderPending = true
				end

				RemoteController.fire('SushiOrder', {
					mode = currentMode,
					itemId = item.id,
					tableId = currentTableId,
				})

				-- Close menu
				SushiRestaurantController.close()
			end)
		end

		card.Parent = itemsList
	end
end

local function createUI()
	if screenGui then return end

	screenGui = Instance.new('ScreenGui')
	screenGui.Name = 'SuwaSushiGui'
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 25
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dim Backdrop
	local backdrop = Instance.new('TextButton')
	backdrop.Name = 'Backdrop'
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.55
	backdrop.BorderSizePixel = 0
	backdrop.Text = ''
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui

	backdrop.MouseButton1Click:Connect(function()
		SushiRestaurantController.close()
	end)

	-- Main Window Frame
	mainWindow = Instance.new('Frame')
	mainWindow.Name = 'MainWindow'
	mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	mainWindow.Position = UDim2.fromScale(0.5, 0.5)
	mainWindow.Size = UDim2.fromOffset(700, 540)
	mainWindow.BackgroundColor3 = Color3.fromRGB(18, 21, 28)
	mainWindow.BorderSizePixel = 0
	mainWindow.Active = true
	mainWindow.ZIndex = 2

	local mainCorner = Instance.new('UICorner')
	mainCorner.CornerRadius = UDim.new(0, 14)
	mainCorner.Parent = mainWindow

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(60, 68, 86)
	stroke.Thickness = 1.5
	stroke.Parent = mainWindow
	mainWindow.Parent = screenGui

	-- Mobile Responsive Scaling
	UIScaling.fit(mainWindow)

	-- Header Frame
	local header = Instance.new('Frame')
	header.Name = 'Header'
	header.Size = UDim2.new(1, 0, 0, 56)
	header.BackgroundTransparency = 1
	header.ZIndex = 3
	header.Parent = mainWindow

	headerTitle = Instance.new('TextLabel')
	headerTitle.Name = 'Title'
	headerTitle.BackgroundTransparency = 1
	headerTitle.Position = UDim2.new(0, 20, 0, 6)
	headerTitle.Size = UDim2.new(0.5, 0, 0, 24)
	headerTitle.Font = Enum.Font.FredokaOne
	headerTitle.TextSize = 20
	headerTitle.TextColor3 = Color3.fromRGB(245, 248, 255)
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Text = '🍣 Suwa Sushi / 諏訪すし店'
	headerTitle.ZIndex = 3
	headerTitle.Parent = header

	modeBadge = Instance.new('TextLabel')
	modeBadge.Name = 'ModeBadge'
	modeBadge.BackgroundTransparency = 1
	modeBadge.Position = UDim2.new(0, 20, 0, 32)
	modeBadge.Size = UDim2.new(0.5, 0, 0, 18)
	modeBadge.Font = Enum.Font.GothamMedium
	modeBadge.TextSize = 13
	modeBadge.TextColor3 = Color3.fromRGB(235, 180, 90)
	modeBadge.TextXAlignment = Enum.TextXAlignment.Left
	modeBadge.Text = '🛍️ Takeaway Counter / 持ち帰りカウンター'
	modeBadge.ZIndex = 3
	modeBadge.Parent = header

	-- Yen Badge
	yenBadge = Instance.new('TextLabel')
	yenBadge.Name = 'YenBadge'
	yenBadge.AnchorPoint = Vector2.new(1, 0.5)
	yenBadge.Position = UDim2.new(1, -72, 0.5, 0)
	yenBadge.Size = UDim2.fromOffset(130, 34)
	yenBadge.BackgroundColor3 = Color3.fromRGB(30, 35, 46)
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
	closeBtn.Position = UDim2.new(1, -16, 0.5, 0)
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
		SushiRestaurantController.close()
	end)

	-- Category Tabs Row
	local tabRow = Instance.new('Frame')
	tabRow.Name = 'TabRow'
	tabRow.Position = UDim2.new(0, 20, 0, 60)
	tabRow.Size = UDim2.new(1, -40, 0, 36)
	tabRow.BackgroundTransparency = 1
	tabRow.ZIndex = 3
	tabRow.Parent = mainWindow

	local tabLayout = Instance.new('UIListLayout')
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
	tabLayout.Parent = tabRow

	local tabs = {
		{ id = 'all', label = 'All / すべて' },
		{ id = 'sushi', label = '🍣 Nigiri & Rolls / 握り' },
		{ id = 'dish', label = '🍤 Dishes & Soups / 一品' },
		{ id = 'drink', label = '🍵 Drinks / お飲み物' },
	}

	for idx, tabData in ipairs(tabs) do
		local tabBtn = Instance.new('TextButton')
		tabBtn.Name = `Tab_{tabData.id}`
		tabBtn.LayoutOrder = idx
		tabBtn.Size = UDim2.new(0.235, 0, 1, 0)
		tabBtn.BackgroundColor3 = if tabData.id == currentFilter
			then Color3.fromRGB(220, 75, 60)
			else Color3.fromRGB(30, 34, 44)
		tabBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
		tabBtn.Font = Enum.Font.FredokaOne
		tabBtn.TextSize = 12
		tabBtn.Text = tabData.label
		tabBtn.ZIndex = 3
		tabBtn.AutoButtonColor = true

		local tCorner = Instance.new('UICorner')
		tCorner.CornerRadius = UDim.new(0, 8)
		tCorner.Parent = tabBtn

		tabBtn.MouseButton1Click:Connect(function()
			currentFilter = tabData.id
			for _, sibling in ipairs(tabRow:GetChildren()) do
				if sibling:IsA('TextButton') then
					local sId = sibling.Name:gsub('Tab_', '')
					sibling.BackgroundColor3 = if sId == currentFilter
						then Color3.fromRGB(220, 75, 60)
						else Color3.fromRGB(30, 34, 44)
				end
			end
			refreshItemList()
		end)

		tabBtn.Parent = tabRow
	end

	-- Items Scroll Container
	itemsList = Instance.new('ScrollingFrame')
	itemsList.Name = 'ItemsList'
	itemsList.Position = UDim2.new(0, 20, 0, 108)
	itemsList.Size = UDim2.new(1, -40, 1, -122)
	itemsList.BackgroundTransparency = 1
	itemsList.BorderSizePixel = 0
	itemsList.ScrollBarThickness = 6
	itemsList.ScrollBarImageColor3 = Color3.fromRGB(80, 90, 110)
	itemsList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemsList.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemsList.ZIndex = 3
	itemsList.Parent = mainWindow

	local gridLayout = Instance.new('UIGridLayout')
	gridLayout.CellSize = UDim2.fromOffset(324, 76)
	gridLayout.CellPadding = UDim2.fromOffset(12, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemsList
end

-- Floating Button for Dine-In Table Service
local function setupFloatingOrderButton()
	local hudGui = playerGui:FindFirstChild('SuwaSushiHUD')
	if not hudGui then
		local newHud = Instance.new('ScreenGui')
		newHud.Name = 'SuwaSushiHUD'
		newHud.ResetOnSpawn = false
		newHud.DisplayOrder = 15
		newHud.Parent = playerGui
		hudGui = newHud
	end

	floatingOrderBtn = Instance.new('TextButton')
	floatingOrderBtn.Name = 'TableOrderFloatingBtn'
	floatingOrderBtn.AnchorPoint = Vector2.new(0.5, 1)
	-- Position above standard Roblox bottom controls, mobile-aware
	local bottomOffset = if UIScaling.isTouch() then -110 else -80
	floatingOrderBtn.Position = UDim2.new(0.5, 0, 1, bottomOffset)
	floatingOrderBtn.Size = UDim2.fromOffset(260, 52)
	floatingOrderBtn.BackgroundColor3 = Color3.fromRGB(215, 65, 55)
	floatingOrderBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	floatingOrderBtn.Font = Enum.Font.FredokaOne
	floatingOrderBtn.TextSize = 16
	floatingOrderBtn.Text = '🍣 Order at Table / 席で注文する'
	floatingOrderBtn.ZIndex = 15
	floatingOrderBtn.Visible = false

	local bCorner = Instance.new('UICorner')
	bCorner.CornerRadius = UDim.new(0, 12)
	bCorner.Parent = floatingOrderBtn

	local bStroke = Instance.new('UIStroke')
	bStroke.Color = Color3.fromRGB(255, 220, 120)
	bStroke.Thickness = 2
	bStroke.Parent = floatingOrderBtn

	-- Subtle floating glow animation
	local function pulse()
		if not floatingOrderBtn or not floatingOrderBtn.Visible then return end
		local tweenIn = TweenService:Create(floatingOrderBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundColor3 = Color3.fromRGB(240, 85, 70),
		})
		local tweenOut = TweenService:Create(floatingOrderBtn, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			BackgroundColor3 = Color3.fromRGB(215, 65, 55),
		})
		tweenIn.Completed:Connect(function()
			tweenOut:Play()
		end)
		tweenOut.Completed:Connect(function()
			if floatingOrderBtn and floatingOrderBtn.Visible then
				tweenIn:Play()
			end
		end)
		tweenIn:Play()
	end

	floatingOrderBtn:GetPropertyChangedSignal('Visible'):Connect(function()
		if floatingOrderBtn.Visible then
			pulse()
		end
	end)

	floatingOrderBtn.MouseButton1Click:Connect(function()
		playLocalSound(SOUND_COIN)
		SushiRestaurantController.open({
			mode = 'dine_in',
			tableId = currentTableId,
			yen = currentYen,
		})
	end)

	floatingOrderBtn.Parent = hudGui
end

local function getOrFindFloatingButton(): TextButton?
	if floatingOrderBtn and floatingOrderBtn.Parent then
		return floatingOrderBtn
	end
	local hudGui = playerGui:FindFirstChild('SuwaSushiHUD')
	if hudGui then
		local btn = hudGui:FindFirstChild('TableOrderFloatingBtn')
		if btn and btn:IsA('TextButton') then
			floatingOrderBtn = btn
			return btn
		end
	end
	return nil
end

local isOrderPending: boolean = false

function SushiRestaurantController.open(data: any)
	currentMode = (data and data.mode) or 'takeaway'
	currentTableId = (data and data.tableId) or currentTableId
	currentYen = (data and data.yen) or currentYen

	-- Always hide floating HUD button when menu modal is open
	local btn = getOrFindFloatingButton()
	if btn then
		btn.Visible = false
	end

	if not screenGui then
		createUI()
	end

	if modeBadge then
		if currentMode == 'takeaway' then
			modeBadge.Text = '🛍️ Takeaway Counter (Bag) / お持ち帰り'
			modeBadge.TextColor3 = Color3.fromRGB(235, 180, 90)
		else
			modeBadge.Text = `🍽️ Table Service ({currentTableId}) / 席で注文`
			modeBadge.TextColor3 = Color3.fromRGB(110, 210, 150)
		end
	end

	if yenBadge then
		yenBadge.Text = `💰 ¥{currentYen}`
	end

	refreshItemList()

	if screenGui then
		screenGui.Enabled = true
	end
end

function SushiRestaurantController.close()
	if screenGui then
		screenGui.Enabled = false
	end

	-- Only restore floating button if seated and not currently waiting for / eating food
	local btn = getOrFindFloatingButton()
	if btn then
		if isCurrentlySeatedAtSushi and not isOrderPending then
			btn.Visible = true
		else
			btn.Visible = false
		end
	end
end

-- Seating detection for dining chairs
local function handleHumanoidSeated(active: boolean, currentSeat: any)
	local btn = getOrFindFloatingButton()
	if active and currentSeat and currentSeat:IsA('Seat') then
		local isSushiSeat = currentSeat:GetAttribute('IsSushiSeat')
		if isSushiSeat == true then
			isCurrentlySeatedAtSushi = true
			currentSeatPart = currentSeat
			currentTableId = currentSeat:GetAttribute('TableId') or 'Table'

			if btn and not isOrderPending and (not screenGui or not screenGui.Enabled) then
				btn.Visible = true
			end
			return
		end
	end

	-- Stood up or seated elsewhere
	isCurrentlySeatedAtSushi = false
	currentSeatPart = nil
	isOrderPending = false
	if btn then
		btn.Visible = false
	end

	-- If dine-in menu is open, auto close when getting up
	if screenGui and screenGui.Enabled and currentMode == 'dine_in' then
		SushiRestaurantController.close()
	end
end

local function bindCharacter(char: Model)
	local hum = char:WaitForChild('Humanoid', 5) :: Humanoid?
	if hum then
		hum.Seated:Connect(function(active, seatPart)
			handleHumanoidSeated(active, seatPart)
		end)
	end
end

function SushiRestaurantController.init()
	setupFloatingOrderButton()

	-- Listen for takeaway menu event from cash register
	RemoteController.onEvent('SushiOpenMenu', function(data: any)
		SushiRestaurantController.open(data)
	end)

	-- Table served celebration sound / notification
	RemoteController.onEvent('SushiTableServed', function(data: any)
		playLocalSound(SOUND_SERVE)
		task.delay(8, function()
			isOrderPending = false
			if isCurrentlySeatedAtSushi and floatingOrderBtn and (not screenGui or not screenGui.Enabled) then
				floatingOrderBtn.Visible = true
			end
		end)
	end)

	-- Yen updates
	RemoteController.onEvent('ProfileUpdated', function(profile: any)
		if profile and profile.economy and profile.economy.yen then
			currentYen = profile.economy.yen
			if yenBadge then
				yenBadge.Text = `💰 ¥{currentYen}`
			end
			if screenGui and screenGui.Enabled then
				refreshItemList()
			end
		end
	end)

	-- Character setup for seating detection
	if localPlayer.Character then
		task.spawn(bindCharacter, localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(bindCharacter)

	print('[SushiRestaurantController] Suwa Sushi Restaurant bilingual client controller initialized')
end

return SushiRestaurantController
