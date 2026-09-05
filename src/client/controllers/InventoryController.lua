--!strict

-- Player bag, item take-out actions and lakeside shop UI.
-- Positioned cleanly in the unified Top-Right Dock.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))
local UIDock = require(script.Parent:WaitForChild('UIDock'))
local FishingData = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Fishing'))

local InventoryController = {}
local gui: ScreenGui
local bagPanel: Frame
local bagList: ScrollingFrame
local yenLabel: TextLabel
local shopPanel: Frame
local shopList: Frame
local shopTitle: TextLabel
local toast: TextLabel
local latestSnapshot: any = nil

local function corner(parent: GuiObject, radius: number)
	local uiCorner = Instance.new('UICorner')
	uiCorner.CornerRadius = UDim.new(0, radius)
	uiCorner.Parent = parent
end

local function textLabel(parent: Instance, text: string, size: UDim2, textSize: number): TextLabel
	local label = Instance.new('TextLabel')
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(43, 50, 47)
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function clearRows(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA('GuiObject') and child.Name == 'InventoryRow' then
			child:Destroy()
		end
	end
end

local currentShopId: string? = nil

local function getItemName(id: string): string
	if FishingData.itemNames and FishingData.itemNames[id] then
		return FishingData.itemNames[id]
	end
	local words = {}
	for word in id:gmatch('[^_]+') do
		table.insert(words, word:sub(1, 1):upper() .. word:sub(2):lower())
	end
	return table.concat(words, ' ')
end

local function makeInventoryRow(category: string, id: string, name: string, count: number, order: number)
	local row = Instance.new('Frame')
	row.Name = 'InventoryRow'
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -10, 0, 48)
	row.BackgroundColor3 = Color3.fromRGB(235, 230, 216)
	row.Parent = bagList
	corner(row, 8)
	local label = textLabel(row, `{name}  ×{count}`, UDim2.new(1, -130, 1, 0), 15)
	label.Position = UDim2.fromOffset(12, 0)

	local action = Instance.new('TextButton')
	action.AnchorPoint = Vector2.new(1, 0.5)
	action.Position = UDim2.new(1, -8, 0.5, 0)
	action.Size = UDim2.fromOffset(108, 34)
	action.TextColor3 = Color3.new(1, 1, 1)
	action.Font = Enum.Font.GothamBold
	action.TextSize = 13
	action.Parent = row
	corner(action, 6)

	if category == 'fish' then
		action.Text = 'Sell'
		action.BackgroundColor3 = Color3.fromRGB(156, 92, 44)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'sell',
				category = 'fish',
				id = id,
			})
		end)
	else
		action.Text = 'Take Out'
		action.BackgroundColor3 = Color3.fromRGB(48, 98, 68)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'equip',
				category = 'item',
				id = id,
			})
			bagPanel.Visible = false
		end)
	end
end

local function makeShopRow(item: any, order: number)
	local row = Instance.new('Frame')
	row.Name = 'InventoryRow'
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -10, 0, 52)
	row.BackgroundColor3 = Color3.fromRGB(235, 230, 216)
	row.Parent = shopList
	corner(row, 8)

	local priceText = if not item.price or item.price == 0 then 'FREE (無料)' else `¥{item.price}`
	local label = textLabel(row, `{item.name}   {priceText}`, UDim2.new(1, -120, 1, 0), 15)
	label.Position = UDim2.fromOffset(12, 0)

	local buy = Instance.new('TextButton')
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -8, 0.5, 0)
	buy.Size = UDim2.fromOffset(92, 34)
	buy.BackgroundColor3 = Color3.fromRGB(48, 88, 62)
	buy.Text = if not item.price or item.price == 0 then 'Get' else 'Buy'
	buy.TextColor3 = Color3.new(1, 1, 1)
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 14
	buy.Parent = row
	corner(buy, 6)

	buy.Activated:Connect(function()
		RemoteController.fire('ShopBuy', {
			shopId = currentShopId or 'island_festival',
			itemId = item.id,
		})
	end)
end

local function showToast(message: string)
	toast.Text = message
	toast.Visible = true
	task.delay(2.5, function()
		if toast.Text == message then
			toast.Visible = false
		end
	end)
end

local function renderInventory(data: any)
	latestSnapshot = data
	clearRows(bagList)
	yenLabel.Text = `Bag   (¥{data.yen or 999999})`

	local order = 1
	for id, item in pairs(data.items or {}) do
		local count = if typeof(item) == 'number' then item else (item.count or 1)
		if count > 0 then
			local name = getItemName(id)
			makeInventoryRow('item', id, name, count, order)
			order += 1
		end
	end
	for id, count in pairs(data.fish or {}) do
		if count > 0 then
			local name = if FishingData.fish and FishingData.fish[id] then FishingData.fish[id].name else id
			makeInventoryRow('fish', id, name, count, order)
			order += 1
		end
	end
end

local function renderShop(data: any)
	clearRows(shopList)
	currentShopId = data.id or 'island_festival'
	shopTitle.Text = `{data.title or data.name or 'Shop'}   (Unlimited Yen)`
	local items = data.catalog or data.items or {}
	for order, item in ipairs(items) do
		makeShopRow(item, order)
	end
	shopPanel.Visible = true
end

local function buildGui()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild('PlayerGui')
	local existing = playerGui:FindFirstChild('InventoryGui')
	if existing then
		existing:Destroy()
	end

	gui = Instance.new('ScreenGui')
	gui.Name = 'InventoryGui'
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local touch = UIScaling.isTouch()

	-- 1. Top-Right Dock Button
	local bagButton = UIDock.pillButton(if touch then 'Bag' else 'Bag [B]', 3)
	bagButton.Name = 'BagButton'
	bagButton.ZIndex = 2
	bagButton.Parent = UIDock.getTopRightRow()

	-- 2. Bag Popup Panel
	bagPanel = Instance.new('Frame')
	bagPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	bagPanel.Position = UDim2.fromScale(0.5, 0.5)
	bagPanel.Size = UDim2.fromOffset(440, 440)
	bagPanel.BackgroundColor3 = Color3.fromRGB(248, 244, 232)
	bagPanel.Visible = false
	bagPanel.ZIndex = 10
	bagPanel.Parent = gui
	corner(bagPanel, 15)
	UIScaling.fit(bagPanel)

	local panelStroke = Instance.new('UIStroke')
	panelStroke.Color = Color3.fromRGB(180, 160, 130)
	panelStroke.Thickness = 1.5
	panelStroke.Parent = bagPanel

	yenLabel = textLabel(bagPanel, 'Bag', UDim2.new(1, -70, 0, 52), 20)
	yenLabel.Position = UDim2.fromOffset(16, 0)
	yenLabel.ZIndex = 11

	local closeBag = Instance.new('TextButton')
	closeBag.AnchorPoint = Vector2.new(1, 0)
	closeBag.Position = UDim2.new(1, -10, 0, 10)
	closeBag.Size = UDim2.fromOffset(36, 32)
	closeBag.BackgroundColor3 = Color3.fromRGB(162, 68, 60)
	closeBag.Text = '×'
	closeBag.TextColor3 = Color3.new(1, 1, 1)
	closeBag.Font = Enum.Font.GothamBold
	closeBag.TextSize = 20
	closeBag.ZIndex = 11
	closeBag.Parent = bagPanel
	corner(closeBag, 8)

	bagList = Instance.new('ScrollingFrame')
	bagList.Position = UDim2.fromOffset(12, 56)
	bagList.Size = UDim2.new(1, -24, 1, -68)
	bagList.BackgroundTransparency = 1
	bagList.BorderSizePixel = 0
	bagList.ScrollBarThickness = 6
	bagList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	bagList.CanvasSize = UDim2.new(0, 0, 0, 0)
	bagList.ZIndex = 11
	bagList.Parent = bagPanel
	local layout = Instance.new('UIListLayout')
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = bagList

	bagButton.Activated:Connect(function()
		bagPanel.Visible = not bagPanel.Visible
		if bagPanel.Visible and latestSnapshot then
			renderInventory(latestSnapshot)
		end
	end)
	closeBag.Activated:Connect(function()
		bagPanel.Visible = false
	end)

	-- 3. Shop Popup Panel
	shopPanel = Instance.new('Frame')
	shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	shopPanel.Size = UDim2.fromOffset(480, 420)
	shopPanel.BackgroundColor3 = Color3.fromRGB(248, 244, 232)
	shopPanel.Visible = false
	shopPanel.ZIndex = 10
	shopPanel.Parent = gui
	corner(shopPanel, 15)
	UIScaling.fit(shopPanel)

	local shopStroke = Instance.new('UIStroke')
	shopStroke.Color = Color3.fromRGB(180, 160, 130)
	shopStroke.Thickness = 1.5
	shopStroke.Parent = shopPanel

	shopTitle = textLabel(shopPanel, 'Shop', UDim2.new(1, -70, 0, 52), 21)
	shopTitle.Position = UDim2.fromOffset(16, 0)
	shopTitle.ZIndex = 11

	shopList = Instance.new('ScrollingFrame')
	shopList.Name = 'ShopList'
	shopList.Position = UDim2.fromOffset(12, 56)
	shopList.Size = UDim2.new(1, -24, 1, -68)
	shopList.BackgroundTransparency = 1
	shopList.BorderSizePixel = 0
	shopList.ScrollBarThickness = 6
	shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
	shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
	shopList.ZIndex = 11
	shopList.Parent = shopPanel

	local shopLayout = Instance.new('UIListLayout')
	shopLayout.Padding = UDim.new(0, 6)
	shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
	shopLayout.Parent = shopList

	local closeShop = Instance.new('TextButton')
	closeShop.AnchorPoint = Vector2.new(1, 0)
	closeShop.Position = UDim2.new(1, -10, 0, 10)
	closeShop.Size = UDim2.fromOffset(36, 32)
	closeShop.BackgroundColor3 = Color3.fromRGB(162, 68, 60)
	closeShop.Text = '×'
	closeShop.TextColor3 = Color3.new(1, 1, 1)
	closeShop.Font = Enum.Font.GothamBold
	closeShop.TextSize = 20
	closeShop.ZIndex = 11
	closeShop.Parent = shopPanel
	corner(closeShop, 8)
	closeShop.Activated:Connect(function()
		shopPanel.Visible = false
	end)

	-- 4. Toast Notification
	toast = Instance.new('TextLabel')
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.new(0.5, 0, 0, 70)
	toast.Size = UDim2.fromOffset(340, 42)
	toast.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	toast.BackgroundTransparency = 0.15
	toast.TextColor3 = Color3.fromRGB(255, 235, 170)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 14
	toast.Visible = false
	toast.ZIndex = 20
	toast.Parent = gui
	corner(toast, 10)

	local toastStroke = Instance.new('UIStroke')
	toastStroke.Color = Color3.fromRGB(255, 200, 120)
	toastStroke.Thickness = 1
	toastStroke.Transparency = 0.4
	toastStroke.Parent = toast
	UIScaling.fit(toast)
end

function InventoryController.init()
	buildGui()

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.B then
			if bagPanel then
				bagPanel.Visible = not bagPanel.Visible
				if bagPanel.Visible and latestSnapshot then
					renderInventory(latestSnapshot)
				end
			end
		end
	end)

	local function onInventoryUpdate(data)
		latestSnapshot = data
		if bagPanel and bagPanel.Visible then
			renderInventory(data)
		end
	end

	RemoteController.onEvent('InventoryUpdated', onInventoryUpdate)
	RemoteController.onEvent('InventorySnapshot', onInventoryUpdate)

	RemoteController.onEvent('OpenShop', function(data)
		renderShop(data)
	end)

	RemoteController.onEvent('ShopResult', function(success, message)
		if message then
			showToast(message)
		end
	end)

	RemoteController.onEvent('InventoryToast', function(message)
		if message then
			showToast(message)
		end
	end)

	task.spawn(function()
		local snapshot = RemoteController.invoke('GetInventory')
		if snapshot then
			latestSnapshot = snapshot
		end
	end)
end

return InventoryController
