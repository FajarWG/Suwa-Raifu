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
local currentShopTitle: string = 'Shop'
local currentShopData: any = nil

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
	row.ZIndex = 12
	row.Parent = bagList
	corner(row, 8)
	local label = textLabel(row, `{name}  ×{count}`, UDim2.new(1, -130, 1, 0), 15)
	label.Position = UDim2.fromOffset(12, 0)
	label.ZIndex = 13

	local action = Instance.new('TextButton')
	action.AnchorPoint = Vector2.new(1, 0.5)
	action.Position = UDim2.new(1, -8, 0.5, 0)
	action.Size = UDim2.fromOffset(108, 34)
	action.TextColor3 = Color3.new(1, 1, 1)
	action.Font = Enum.Font.GothamBold
	action.TextSize = 13
	action.ZIndex = 13
	action.Parent = row
	corner(action, 6)

	local isDrink = id == 'ramune' or id == 'matcha_tea' or id == 'ice_coffee' or id == 'fisherman_tea'
	local isFood = id == 'dango' or id == 'yakisoba' or id == 'taiyaki' or id == 'onigiri' or id == 'umeboshi_onigiri' or string.find(id, 'ice_cream') ~= nil or id == 'apple_sorbet'
	local isBait = id == 'worm_bait' or id == 'shrimp_bait' or id == 'golden_lure'
	local isRod = id == 'fishing_rod' or id == 'pro_fishing_rod'
	local isJunk = id == 'old_boot' or id == 'empty_can'

	if category == 'fish' then
		local def = FishingData.fish and FishingData.fish[id]
		local price = def and (def.baseValue or def.price) or 150
		action.Text = `Sell (+¥{price})`
		action.BackgroundColor3 = Color3.fromRGB(156, 92, 44)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'sell',
				category = 'fish',
				id = id,
			})
		end)
	elseif isJunk then
		local price = if id == 'old_boot' then 5 else 3
		action.Text = `Sell (+¥{price})`
		action.BackgroundColor3 = Color3.fromRGB(130, 90, 60)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'sell',
				category = 'item',
				id = id,
			})
		end)
	elseif isBait then
		action.Text = 'Bait'
		action.BackgroundColor3 = Color3.fromRGB(115, 125, 135)
		action.AutoButtonColor = false
		action.Active = false
	elseif isFood then
		action.Text = 'Eat'
		action.BackgroundColor3 = Color3.fromRGB(48, 120, 75)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'equip',
				category = 'item',
				id = id,
			})
			bagPanel.Visible = false
		end)
	elseif isDrink then
		action.Text = 'Drink'
		action.BackgroundColor3 = Color3.fromRGB(38, 110, 125)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'equip',
				category = 'item',
				id = id,
			})
			bagPanel.Visible = false
		end)
	elseif isRod then
		action.Text = 'Equip'
		action.BackgroundColor3 = Color3.fromRGB(48, 98, 68)
		action.Activated:Connect(function()
			RemoteController.fire('InventoryAction', {
				action = 'equip',
				category = 'item',
				id = id,
			})
			bagPanel.Visible = false
		end)
	else
		action.Text = 'Use'
		action.BackgroundColor3 = Color3.fromRGB(60, 95, 80)
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
	row.ZIndex = 12
	row.Parent = shopList
	corner(row, 8)

	local isFree = not item.price or item.price == 0
	local isOwnedRod = (item.id == 'fishing_rod' or item.id == 'pro_fishing_rod') and (latestSnapshot and latestSnapshot.items and (latestSnapshot.items[item.id] or 0) >= 1)
	local isMaxWorm = item.id == 'worm_bait' and (latestSnapshot and latestSnapshot.items and (latestSnapshot.items.worm_bait or 0) >= 5)
	local isDisabled = isOwnedRod or isMaxWorm

	local priceText = if isOwnedRod then 'MAX (1/1)' elseif isMaxWorm then 'MAX (5/5)' elseif isFree then 'FREE (無料)' else `¥{item.price}`
	local label = textLabel(row, `{item.name}   {priceText}`, UDim2.new(1, -120, 1, 0), 14)
	label.Position = UDim2.fromOffset(12, 0)
	label.ZIndex = 13

	local buy = Instance.new('TextButton')
	buy.AnchorPoint = Vector2.new(1, 0.5)
	buy.Position = UDim2.new(1, -8, 0.5, 0)
	buy.Size = UDim2.fromOffset(92, 34)
	buy.BackgroundColor3 = if isDisabled then Color3.fromRGB(115, 125, 135) elseif isFree then Color3.fromRGB(48, 108, 62) else Color3.fromRGB(156, 92, 44)
	buy.Text = if isOwnedRod then 'Owned' elseif isMaxWorm then 'Max (5/5)' elseif isFree then 'Get' else 'Buy'
	buy.TextColor3 = Color3.new(1, 1, 1)
	buy.Font = Enum.Font.GothamBold
	buy.TextSize = 14
	buy.ZIndex = 13
	buy.AutoButtonColor = not isDisabled
	buy.Parent = row
	corner(buy, 6)

	buy.Activated:Connect(function()
		if isOwnedRod then
			showToast('You already own this fishing rod!')
			return
		end
		if isMaxWorm then
			showToast('You already have max Worm Bait (5/5)!')
			return
		end
		local price = item.price or 0
		if price > 0 and latestSnapshot and latestSnapshot.yen and latestSnapshot.yen < price then
			showToast('Not enough yen.')
			return
		end
		if price > 0 and latestSnapshot and latestSnapshot.yen then
			latestSnapshot.yen = math.max(0, latestSnapshot.yen - price)
			local title = if currentShopTitle and currentShopTitle ~= '' then currentShopTitle else 'Shop'
			shopTitle.Text = `{title}  (¥{latestSnapshot.yen})`
			if yenLabel then
				yenLabel.Text = `Bag   (¥{latestSnapshot.yen})`
			end
		end
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
	yenLabel.Text = `Bag   (¥{data.yen or 500})`

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
	currentShopData = data
	clearRows(shopList)
	currentShopId = data.shopId or data.id or 'ice_cream'
	currentShopTitle = data.title or data.name or 'Shop'
	local yen = if latestSnapshot and latestSnapshot.yen ~= nil then latestSnapshot.yen else (if data.yen ~= nil then data.yen else 500)
	shopTitle.Text = `{currentShopTitle}  (¥{yen})`
	local items = data.catalog or data.items or {}
	for order, item in ipairs(items) do
		makeShopRow(item, order)
	end
	if bagPanel then
		bagPanel.Visible = false
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
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
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

	shopTitle = textLabel(shopPanel, 'Shop', UDim2.new(1, -70, 0, 52), 16)
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
	-- Permanently disable Roblox default Backpack CoreGui hotbar
	local StarterGui = game:GetService('StarterGui')
	task.spawn(function()
		local attempts = 0
		while attempts < 20 do
			local ok = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end)
			if ok then break end
			task.wait(0.2)
			attempts += 1
		end
	end)

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
		if shopPanel and shopPanel.Visible and currentShopData then
			renderShop(currentShopData)
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

	-- Consumable Tool Equipping & Screen Action Button
	local function bindCharacter(char: Model)
		local currentTool: Tool? = nil
		local actionGui: ScreenGui? = nil
		local toolActivatedConn: RBXScriptConnection? = nil

		local function cleanupAction()
			if actionGui then
				actionGui:Destroy()
				actionGui = nil
			end
			if toolActivatedConn then
				toolActivatedConn:Disconnect()
				toolActivatedConn = nil
			end
			currentTool = nil
		end

		char.ChildAdded:Connect(function(child)
			if child:IsA('Tool') and child:GetAttribute('IsConsumable') then
				currentTool = child
				local isDrink = child:GetAttribute('IsDrink')
				local itemId = child:GetAttribute('ItemId')

				local function triggerConsume()
					RemoteController.fire('InventoryAction', {
						action = 'consume',
						id = itemId or (currentTool and currentTool:GetAttribute('ItemId')),
					})
				end

				if toolActivatedConn then
					toolActivatedConn:Disconnect()
				end
				toolActivatedConn = child.Activated:Connect(triggerConsume)

				local player = Players.LocalPlayer
				local playerGui = player and player:FindFirstChildOfClass('PlayerGui')
				if playerGui then
					if actionGui then actionGui:Destroy() end
					actionGui = Instance.new('ScreenGui')
					actionGui.Name = 'ConsumeActionGui'
					actionGui.ResetOnSpawn = false
					actionGui.DisplayOrder = 20
					actionGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

					local btn = Instance.new('TextButton')
					btn.Name = 'ConsumeButton'
					btn.AnchorPoint = Vector2.new(0.5, 1)
					btn.Position = UDim2.new(0.5, 0, 1, -85)
					btn.Size = UDim2.fromOffset(220, 48)
					btn.BackgroundColor3 = if isDrink then Color3.fromRGB(38, 110, 125) else Color3.fromRGB(48, 120, 75)
					btn.Text = ''
					btn.AutoButtonColor = true
					btn.ZIndex = 25
					btn.Parent = actionGui

					corner(btn, 24)

					-- Crisp border stroke only (does not blur text)
					local stroke = Instance.new('UIStroke')
					stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					stroke.Color = Color3.fromRGB(255, 255, 255)
					stroke.Thickness = 1.5
					stroke.Transparency = 0.25
					stroke.Parent = btn

					-- High-definition, sharp text label without text stroke blur
					local label = Instance.new('TextLabel')
					label.Size = UDim2.new(1, 0, 1, 0)
					label.BackgroundTransparency = 1
					label.Text = if isDrink then 'Drink (Click / Tap)' else 'Eat (Click / Tap)'
					label.TextColor3 = Color3.new(1, 1, 1)
					label.Font = Enum.Font.GothamBold
					label.TextSize = 16
					label.ZIndex = 26
					label.Parent = btn

					btn.Activated:Connect(triggerConsume)
					actionGui.Parent = playerGui
				end
			end
		end)

		char.ChildRemoved:Connect(function(child)
			if child == currentTool then
				cleanupAction()
			end
		end)
	end

	local player = Players.LocalPlayer
	if player.Character then
		bindCharacter(player.Character)
	end
	player.CharacterAdded:Connect(bindCharacter)
end

return InventoryController
