--!strict

-- VendingMachineService.lua
-- Activates the two outdoor Japanese Vending Machines (自動販売機):
-- 1. ProximityPrompt for PC ([E]) and Mobile touch: opens interactive bilingual Vending Machine GUI.
-- 2. Physical 3D ClickDetectors on each button: lighting up button, playing sound, and dispensing items.
-- 3. Automatic dispensing of usable, animated food & drink Tools (drinking/eating animations, health boost, sounds).
-- 4. Yen deduction via ProfileService with fallback, plus bilingual notifications (ガタン！).

local Workspace = game:GetService('Workspace')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Debris = game:GetService('Debris')
local SoundService = game:GetService('SoundService')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local InventoryService = require(script.Parent:WaitForChild('InventoryService'))

local VendingMachineService = {}

export type VendingItem = {
	id: string,
	name: string,
	japanese: string,
	category: string, -- 'drink' | 'snack'
	price: number,
	icon: string,
	color: Color3,
	tool: string,
}

local CATALOG: { VendingItem } = {
	{ id = 'coca_cola', name = 'Coca-Cola', japanese = 'コカ・コーラ', category = 'drink', price = 120, icon = '🥤', color = Color3.fromRGB(220, 40, 40), tool = 'coca_cola' },
	{ id = 'pepsi', name = 'Pepsi', japanese = 'ペプシ', category = 'drink', price = 120, icon = '🥤', color = Color3.fromRGB(30, 80, 200), tool = 'pepsi' },
	{ id = 'sprite', name = 'Sprite', japanese = 'スプライト', category = 'drink', price = 120, icon = '🍋', color = Color3.fromRGB(30, 160, 70), tool = 'sprite' },
	{ id = 'mountain_dew', name = 'Mountain Dew', japanese = 'マウンテンデュー', category = 'drink', price = 120, icon = '⚡', color = Color3.fromRGB(120, 190, 30), tool = 'mountain_dew' },
	{ id = 'dr_pepper', name = 'Dr Pepper', japanese = 'ドクターペッパー', category = 'drink', price = 120, icon = '🍒', color = Color3.fromRGB(150, 20, 50), tool = 'dr_pepper' },
	{ id = 'fresh_milk', name = 'Fresh Milk', japanese = 'おいしい牛乳', category = 'drink', price = 110, icon = '🥛', color = Color3.fromRGB(240, 240, 245), tool = 'fresh_milk' },
	{ id = 'orange_juice', name = 'Orange Juice', japanese = 'オレンジジュース', category = 'drink', price = 120, icon = '🍊', color = Color3.fromRGB(245, 140, 20), tool = 'orange_juice' },

	{ id = 'doritos_chips', name = 'Doritos Chips', japanese = 'ドリトス', category = 'snack', price = 150, icon = '🔺', color = Color3.fromRGB(220, 60, 30), tool = 'doritos_chips' },
	{ id = 'hersheys_chocolate', name = "Hershey's Chocolate", japanese = 'ハーシーズチョコ', category = 'snack', price = 130, icon = '🍫', color = Color3.fromRGB(100, 50, 30), tool = 'hersheys_chocolate' },
	{ id = 'choco_chip_cookie', name = 'Choco Chip Cookie', japanese = 'クッキー', category = 'snack', price = 130, icon = '🍪', color = Color3.fromRGB(190, 130, 60), tool = 'choco_chip_cookie' },
	{ id = 'golden_waffle', name = 'Golden Waffle', japanese = '焼きたてワッフル', category = 'snack', price = 140, icon = '🧇', color = Color3.fromRGB(220, 160, 40), tool = 'golden_waffle' },
	{ id = 'bloxy_snack', name = 'Bloxy Snack', japanese = 'ブロックスナック', category = 'snack', price = 150, icon = '⭐', color = Color3.fromRGB(235, 185, 25), tool = 'bloxy_snack' },
}

local BUTTON_ITEM_MAP: { [string]: string } = {
	ColaB = 'coca_cola',
	Cola = 'coca_cola',
	PepsiB = 'pepsi',
	Pepsi = 'pepsi',
	SpriteB = 'sprite',
	Sprite = 'sprite',
	MDB = 'mountain_dew',
	MountainDew = 'mountain_dew',
	DrPepper = 'dr_pepper',
	DrPepperB = 'dr_pepper',
	MilkB = 'fresh_milk',
	Milk = 'fresh_milk',
	OrangeJuiceB = 'orange_juice',
	OrangeJuice = 'orange_juice',
	LaysB = 'doritos_chips',
	Doritos = 'doritos_chips',
	HersheyB = 'hersheys_chocolate',
	Hersheys = 'hersheys_chocolate',
	TwixB = 'hersheys_chocolate',
	CookiesB = 'choco_chip_cookie',
	Cookie = 'choco_chip_cookie',
	WaffleB = 'golden_waffle',
	WAFFLEB = 'golden_waffle',
	Waffle = 'golden_waffle',
	EpicSnackB = 'bloxy_snack',
	EpicSnack = 'bloxy_snack',
	AWB = 'coca_cola',
}

-- Sounds
local SOUND_COIN = 'rbxassetid://242135745'
local SOUND_CLUNK = 'rbxassetid://15047813'

local function findCatalogItem(id: string): VendingItem?
	for _, item in ipairs(CATALOG) do
		if item.id == id or item.tool == id then
			return item
		end
	end
	return nil
end

function VendingMachineService.dispense(player: Player, itemId: string, machineModel: Model?)
	local item = findCatalogItem(itemId)
	if not item then
		warn(`[VendingMachineService] Item not found: {itemId}`)
		return false
	end

	local profile = ProfileService.getProfile(player.UserId)
	local price = item.price
	local playerYen = (profile and profile.economy and profile.economy.yen) or 500

	if playerYen < price then
		local diff = price - playerYen
		RemoteRegistry.fireClient(player, 'ShopResult', false, `所持金が足りません (¥{diff} 不足)`)
		RemoteRegistry.fireClient(player, 'InventoryToast', `⚠️ Not enough Yen! (¥{diff} short / 所持金不足)`)
		return false
	end

	-- Deduct Yen & sync in real-time
	if profile and profile.economy and profile.economy.yen then
		profile.economy.yen = math.max(0, profile.economy.yen - price)
		RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
	end

	-- Add directly to Bag (InventoryService) - no auto-equip
	local invRes = InventoryService.addItem(player.UserId, item.id, 1)
	local snap = InventoryService.getSnapshot(player.UserId)
	if snap then
		RemoteRegistry.fireClient(player, 'InventoryUpdated', snap)
	end

	-- Audio & Visual feedback at machine
	local spotPart: BasePart? = nil
	if machineModel then
		spotPart = machineModel:FindFirstChild('Spot') or machineModel:FindFirstChild('Holder')
	end
	if not spotPart and player.Character then
		spotPart = player.Character:FindFirstChild('HumanoidRootPart') :: BasePart?
	end

	if spotPart then
		-- Play coin sound
		local coinSound = Instance.new('Sound')
		coinSound.SoundId = SOUND_COIN
		coinSound.Volume = 0.9
		coinSound.Parent = spotPart
		coinSound:Play()
		Debris:AddItem(coinSound, 2)

		-- Play dispenser clunk
		task.delay(0.25, function()
			if spotPart and spotPart.Parent then
				local clunkSound = Instance.new('Sound')
				clunkSound.SoundId = SOUND_CLUNK
				clunkSound.Volume = 1.0
				clunkSound.Parent = spotPart
				clunkSound:Play()
				Debris:AddItem(clunkSound, 2)
			end
		end)
	end

	-- Notify client
	local msg = `🥤「ガタン！」 {item.name} ({item.japanese}) を購入しました！ (¥{price})`
	RemoteRegistry.fireClient(player, 'ShopResult', true, msg)
	RemoteRegistry.fireClient(player, 'InventoryToast', `🎒 Packaged {item.name} in your bag! / バッグに入りました`)

	return true
end

local function setupMachine(machineModel: Model, displayName: string, promptPos: Vector3)
	-- 1. Create or update ProximityPrompt
	local promptPart = machineModel:FindFirstChild('PromptPart') :: BasePart?
	if not promptPart then
		promptPart = Instance.new('Part')
		promptPart.Name = 'PromptPart'
		promptPart.Size = Vector3.new(2, 4, 3)
		promptPart.Position = promptPos
		promptPart.Transparency = 1
		promptPart.Anchored = true
		promptPart.CanCollide = false
		promptPart.CanQuery = false
		promptPart.CanTouch = false
		promptPart.Parent = machineModel
	else
		promptPart.Position = promptPos
	end

	local prompt = promptPart:FindFirstChildOfClass('ProximityPrompt')
	if not prompt then
		prompt = Instance.new('ProximityPrompt')
		prompt.Name = 'VendingPrompt'
		prompt.ActionText = 'Buy / 買う'
		prompt.ObjectText = `{displayName} / 自動販売機`
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.HoldDuration = 0
		prompt.Parent = promptPart
	end

	prompt.Triggered:Connect(function(player: Player)
		local profile = ProfileService.getProfile(player.UserId)
		local currentYen = (profile and profile.economy and profile.economy.yen) or 500
		RemoteRegistry.fireClient(player, 'VendingOpen', {
			machineName = displayName,
			catalog = CATALOG,
			yen = currentYen,
		})
	end)

	-- 2. Make glass parts non-blocking for raycasts/clicks
	for _, p in ipairs(machineModel:GetDescendants()) do
		if p:IsA('BasePart') and (p.Transparency > 0 or p.Name:lower():find('glass') or p.Name:lower():find('trans')) then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end

	-- 3. Configure all physical 3D button ClickDetectors
	local buttonDebounces: { [Instance]: boolean } = {}

	for _, desc in ipairs(machineModel:GetDescendants()) do
		if desc:IsA('BasePart') and (BUTTON_ITEM_MAP[desc.Name] ~= nil or desc.Name:sub(-1) == 'B') then
			local mappedItem = BUTTON_ITEM_MAP[desc.Name]
			if mappedItem then
				local cd = desc:FindFirstChildOfClass('ClickDetector')
				if not cd then
					cd = Instance.new('ClickDetector')
					cd.MaxActivationDistance = 16
					cd.Parent = desc
				else
					cd.MaxActivationDistance = 16
				end

				-- Remove old conflicting scripts inside button
				for _, oldScript in ipairs(desc:GetChildren()) do
					if oldScript:IsA('Script') then
						oldScript.Disabled = true
						oldScript:Destroy()
					end
				end
				for _, oldScript in ipairs(cd:GetChildren()) do
					if oldScript:IsA('Script') then
						oldScript.Disabled = true
						oldScript:Destroy()
					end
				end

				local origColor = desc.BrickColor
				cd.MouseClick:Connect(function(player: Player)
					if buttonDebounces[desc] then return end
					buttonDebounces[desc] = true

					-- Glow red like authentic vending button
					desc.BrickColor = BrickColor.new('Really red')

					VendingMachineService.dispense(player, mappedItem, machineModel)

					task.delay(0.7, function()
						if desc and desc.Parent then
							desc.BrickColor = origColor
						end
						buttonDebounces[desc] = nil
					end)
				end)
			end
		end
	end
end

function VendingMachineService.init()
	-- 1. Setup left taller vending machine
	local v1 = Workspace:FindFirstChild('VendingMachine')
	if v1 and v1:IsA('Model') then
		setupMachine(v1, 'Drink & Snack Vending Machine', Vector3.new(-27.5, 11.8, 75.7))
	end

	-- 2. Setup right cold drinks vending machine
	local v2 = Workspace:FindFirstChild('Vending Machine')
	if v2 and v2:IsA('Model') then
		setupMachine(v2, 'Cold Beverage Vending Machine', Vector3.new(-31.8, 11.0, 66.0))
	end

	-- 3. Handle remote buy from client GUI
	RemoteRegistry.registerEvent('VendingBuy', function(player: Player, itemId: string)
		if typeof(itemId) == 'string' then
			VendingMachineService.dispense(player, itemId, nil)
		end
	end)

	print('[VendingMachineService] Successfully initialized outdoor Japanese Vending Machines (自動販売機)')
end

return VendingMachineService
