--!strict

-- Player bag, item take-out actions and lakeside shop UI.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
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
	local equip = Instance.new('TextButton')
	equip.AnchorPoint = Vector2.new(1, 0.5)
	equip.Position = UDim2.new(1, -8, 0.5, 0)
	equip.Size = UDim2.fromOffset(105, 34)
	equip.BackgroundColor3 = Color3.fromRGB(61, 111, 105)
	equip.Text = 'Take Out'
	equip.TextColor3 = Color3.new(1, 1, 1)
	equip.Font = Enum.Font.GothamBold
	equip.TextSize = 14
	equip.Parent = row
	corner(equip, 7)
	equip.Activated:Connect(function()
		RemoteController.fire('InventoryAction', { action = 'equip', category = category, id = id })
	end)
end

local function renderInventory(data: any)
	if not data then
		return
	end
	latestSnapshot = data
	yenLabel.Text = `Bag   •   ¥{data.yen or 0}   •   Fishing Lv. {data.fishingLevel or 0}`
	clearRows(bagList)
	local entries = {}
	for id, count in data.items or {} do
		if count > 0 then
			table.insert(
				entries,
				{ category = 'items', id = id, name = FishingData.itemNames[id] or id, count = count }
			)
		end
	end
	for id, count in data.fish or {} do
		if count > 0 then
			local definition = FishingData.fish[id]
			table.insert(
				entries,
				{ category = 'fish', id = id, name = if definition then definition.name else id, count = count }
			)
		end
	end
	table.sort(entries, function(a, b)
		return a.name < b.name
	end)
	for index, entry in entries do
		makeInventoryRow(entry.category, entry.id, entry.name, entry.count, index)
	end
	bagList.CanvasSize = UDim2.fromOffset(0, #entries * 54 + 10)
end

local function showToast(message: string, success: boolean)
	toast.Text = message
	toast.BackgroundColor3 = if success then Color3.fromRGB(55, 116, 88) else Color3.fromRGB(161, 67, 58)
	toast.Visible = true
	task.delay(2.8, function()
		if toast.Text == message then
			toast.Visible = false
		end
	end)
end

local function openShop(catalog: any)
	shopTitle.Text = catalog.name
	clearRows(shopList)
	for index, item in catalog.items do
		local row = Instance.new('Frame')
		row.Name = 'InventoryRow'
		row.Position = UDim2.fromOffset(12, 58 + (index - 1) * 58)
		row.Size = UDim2.new(1, -24, 0, 50)
		row.BackgroundColor3 = Color3.fromRGB(235, 230, 216)
		row.Parent = shopList
		corner(row, 8)
		local label = textLabel(row, `{item.name}   ¥{item.price}`, UDim2.new(1, -115, 1, 0), 15)
		label.Position = UDim2.fromOffset(10, 0)
		local buy = Instance.new('TextButton')
		buy.AnchorPoint = Vector2.new(1, 0.5)
		buy.Position = UDim2.new(1, -8, 0.5, 0)
		buy.Size = UDim2.fromOffset(88, 34)
		buy.BackgroundColor3 = Color3.fromRGB(210, 144, 54)
		buy.Text = 'Buy'
		buy.TextColor3 = Color3.fromRGB(36, 31, 25)
		buy.Font = Enum.Font.GothamBold
		buy.TextSize = 15
		buy.Parent = row
		corner(buy, 7)
		buy.Activated:Connect(function()
			RemoteController.fire('ShopBuy', { shopId = catalog.id, itemId = item.id })
		end)
	end
	shopPanel.Visible = true
end

local function buildGui()
	local playerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
	gui = Instance.new('ScreenGui')
	gui.Name = 'InventoryGui'
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 25
	gui.Parent = playerGui

	local bagButton = Instance.new('TextButton')
	bagButton.Position = UDim2.new(0, 18, 1, -70)
	bagButton.Size = UDim2.fromOffset(126, 48)
	bagButton.BackgroundColor3 = Color3.fromRGB(75, 104, 85)
	bagButton.Text = '🎒  Bag  [B]'
	bagButton.TextColor3 = Color3.new(1, 1, 1)
	bagButton.Font = Enum.Font.GothamBold
	bagButton.TextSize = 17
	bagButton.Parent = gui
	corner(bagButton, 11)

	bagPanel = Instance.new('Frame')
	bagPanel.Position = UDim2.new(0, 18, 0.5, -245)
	bagPanel.Size = UDim2.fromOffset(440, 470)
	bagPanel.BackgroundColor3 = Color3.fromRGB(248, 244, 232)
	bagPanel.Visible = false
	bagPanel.Parent = gui
	corner(bagPanel, 15)
	yenLabel = textLabel(bagPanel, 'Bag', UDim2.new(1, -70, 0, 52), 20)
	yenLabel.Position = UDim2.fromOffset(16, 0)

	local closeBag = Instance.new('TextButton')
	closeBag.AnchorPoint = Vector2.new(1, 0)
	closeBag.Position = UDim2.new(1, -10, 0, 10)
	closeBag.Size = UDim2.fromOffset(38, 34)
	closeBag.BackgroundColor3 = Color3.fromRGB(142, 78, 70)
	closeBag.Text = '×'
	closeBag.TextColor3 = Color3.new(1, 1, 1)
	closeBag.Font = Enum.Font.GothamBold
	closeBag.TextSize = 22
	closeBag.Parent = bagPanel
	corner(closeBag, 8)

	bagList = Instance.new('ScrollingFrame')
	bagList.Position = UDim2.fromOffset(12, 56)
	bagList.Size = UDim2.new(1, -24, 1, -68)
	bagList.BackgroundTransparency = 1
	bagList.BorderSizePixel = 0
	bagList.ScrollBarThickness = 6
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

	shopPanel = Instance.new('Frame')
	shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	shopPanel.Position = UDim2.fromScale(0.5, 0.5)
	shopPanel.Size = UDim2.fromOffset(480, 320)
	shopPanel.BackgroundColor3 = Color3.fromRGB(248, 244, 232)
	shopPanel.Visible = false
	shopPanel.Parent = gui
	corner(shopPanel, 15)
	shopList = shopPanel
	shopTitle = textLabel(shopPanel, 'Shop', UDim2.new(1, -70, 0, 52), 21)
	shopTitle.Position = UDim2.fromOffset(16, 0)
	local closeShop = Instance.new('TextButton')
	closeShop.AnchorPoint = Vector2.new(1, 0)
	closeShop.Position = UDim2.new(1, -10, 0, 10)
	closeShop.Size = UDim2.fromOffset(38, 34)
	closeShop.BackgroundColor3 = Color3.fromRGB(142, 78, 70)
	closeShop.Text = '×'
	closeShop.TextColor3 = Color3.new(1, 1, 1)
	closeShop.Font = Enum.Font.GothamBold
	closeShop.TextSize = 22
	closeShop.Parent = shopPanel
	corner(closeShop, 8)
	closeShop.Activated:Connect(function()
		shopPanel.Visible = false
	end)

	toast = Instance.new('TextLabel')
	toast.AnchorPoint = Vector2.new(0.5, 1)
	toast.Position = UDim2.new(0.5, 0, 1, -24)
	toast.Size = UDim2.fromOffset(420, 44)
	toast.BackgroundColor3 = Color3.fromRGB(55, 116, 88)
	toast.TextColor3 = Color3.new(1, 1, 1)
	toast.Font = Enum.Font.GothamBold
	toast.TextSize = 16
	toast.Visible = false
	toast.Parent = gui
	corner(toast, 10)
end

function InventoryController.init()
	buildGui()
	RemoteController.onEvent('InventoryUpdated', renderInventory)
	RemoteController.onEvent('OpenShop', openShop)
	RemoteController.onEvent('ShopResult', function(success: boolean, message: string)
		showToast(message, success)
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.B then
			bagPanel.Visible = not bagPanel.Visible
		end
	end)
	task.spawn(function()
		local result = RemoteController.invoke('GetInventory')
		if result then
			renderInventory(result)
		end
	end)
end

return InventoryController
