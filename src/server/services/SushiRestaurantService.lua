--!strict

-- SushiRestaurantService.lua
-- Activates the Suwa Sushi Restaurant (諏訪すし店):
-- 1. Entrance sensor triggers "Irasshaimase! / いらっしゃいませ！".
-- 2. Cashier counter (Reji) with Staff NPC (Tenin) for Takeaway orders.
-- 3. All 8 dining tables (outdoor terrace & indoor) equipped with interactive Seats.
-- 4. Dine-in table service: Waiter NPC walks to the table, collects payment with "Arigatou gozaimasu!", and serves food.
-- 5. Full yen economy integration and bilingual English & Japanese notifications.

local Workspace = game:GetService('Workspace')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local SoundService = game:GetService('SoundService')
local Debris = game:GetService('Debris')
local TweenService = game:GetService('TweenService')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local InventoryService = require(script.Parent:WaitForChild('InventoryService'))
local FishingData = require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('data'):WaitForChild('Fishing'))

local SushiRestaurantService = {}

-- Audio assets (pre-loaded in SoundService or Creator Dashboard fallback)
local SOUND_IRASSHAIMASE = 'rbxassetid://118590628485091'
local SOUND_ARIGATOU = 'rbxassetid://107094107671003'
local SOUND_COIN = 'rbxassetid://242135745'
local SOUND_SERVE = 'rbxassetid://15047813'

local function getIrasshaimaseSoundId(): string
	local s = SoundService:FindFirstChild('Konbini_Irasshaimase')
	if s and s:IsA('Sound') and s.SoundId ~= '' then
		return s.SoundId
	end
	return SOUND_IRASSHAIMASE
end

local function getArigatouSoundId(): string
	local s = SoundService:FindFirstChild('Konbini_Arigatou')
	if s and s:IsA('Sound') and s.SoundId ~= '' then
		return s.SoundId
	end
	return SOUND_ARIGATOU
end

local function playVoice(parent: Instance?, soundId: string, volume: number?)
	if not parent then return end
	local s = Instance.new('Sound')
	s.SoundId = soundId
	s.Volume = volume or 1.0
	s.RollOffMaxDistance = 50
	s.RollOffMinDistance = 6
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 4)
end

-- Catalog items for Suwa Sushi
local SUSHI_CATALOG = {
	{ id = 'sushi_salmon_nigiri', name = 'Salmon Nigiri', japanese = 'サーモン握り寿司', category = 'nigiri', price = 420, icon = '🍣', desc = 'Fresh Atlantic salmon on seasoned sushi rice' },
	{ id = 'sushi_maguro_nigiri', name = 'Tuna Nigiri', japanese = '本マグロ握り寿司', category = 'nigiri', price = 480, icon = '🍣', desc = 'Prime bluefin maguro tuna, melt in your mouth' },
	{ id = 'sushi_california_roll', name = 'California Roll', japanese = 'カリフォルニアロール', category = 'nigiri', price = 380, icon = '🍱', desc = 'Crab salad, fresh avocado & cucumber with sesame' },
	{ id = 'sushi_sashimi_combo', name = 'Sashimi Platter', japanese = '特選刺身盛り合わせ', category = 'dishes', price = 780, icon = '🥢', desc = "Chef's premium slices of salmon, tuna & sweetfish" },
	{ id = 'sushi_tempura_platter', name = 'Crispy Tempura', japanese = '天ぷら盛り合わせ', category = 'dishes', price = 550, icon = '🍤', desc = 'Light crispy battered prawns, lotus root & pumpkin' },
	{ id = 'sushi_miso_soup', name = 'Tofu Miso Soup', japanese = 'わかめと豆腐の味噌汁', category = 'dishes', price = 150, icon = '🍲', desc = 'Warm comforting dashi miso broth with silk tofu' },
	{ id = 'sushi_edamame', name = 'Steamed Edamame', japanese = '塩ゆで枝豆', category = 'dishes', price = 200, icon = '🌱', desc = 'Warm salted young Japanese soybeans' },
	{ id = 'sushi_green_tea', name = 'Hot Sencha Green Tea', japanese = '熱い宇治煎茶', category = 'drinks', price = 120, icon = '🍵', desc = 'Steaming aromatic Japanese roasted green tea' },
	{ id = 'ramune', name = 'Cold Ramune Soda', japanese = '冷たいラムネ', category = 'drinks', price = 140, icon = '🥤', desc = 'Classic Japanese marble soda pop' },
}

-- References
local restaurantModel: Model? = nil
local cashierNPC: Model? = nil
local waiterNPC: Model? = nil
local registerPrompt: ProximityPrompt? = nil
local tableCenters: { [string]: Vector3 } = {}
local waiterBusy = false

-- Create Staff NPC (R15 appearance dummy with uniform & overhead tag)
local function createStaffNPC(name: string, roleTitle: string, cf: CFrame): Model
	local npc = Instance.new('Model')
	npc.Name = name

	local hrp = Instance.new('Part')
	hrp.Name = 'HumanoidRootPart'
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.CFrame = cf
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Anchored = false
	hrp.Parent = npc
	npc.PrimaryPart = hrp

	local torso = Instance.new('Part')
	torso.Name = 'UpperTorso'
	torso.Size = Vector3.new(2, 1.6, 1)
	torso.CFrame = cf
	torso.Color = Color3.fromRGB(24, 30, 48) -- Navy chef coat
	torso.Material = Enum.Material.Fabric
	torso.CanCollide = false
	torso.Parent = npc

	local head = Instance.new('Part')
	head.Name = 'Head'
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.CFrame = cf * CFrame.new(0, 1.4, 0)
	head.Color = Color3.fromRGB(255, 219, 172)
	head.Material = Enum.Material.SmoothPlastic
	head.CanCollide = false
	head.Parent = npc

	local mesh = Instance.new('SpecialMesh')
	mesh.MeshType = Enum.MeshType.Head
	mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	mesh.Parent = head

	local face = Instance.new('Decal')
	face.Name = 'face'
	face.Texture = 'rbxasset://textures/face.png'
	face.Parent = head

	-- Headband / Chef Hat Accent
	local headband = Instance.new('Part')
	headband.Name = 'Headband'
	headband.Size = Vector3.new(1.25, 0.25, 1.25)
	headband.CFrame = head.CFrame * CFrame.new(0, 0.35, 0)
	headband.Color = Color3.fromRGB(200, 35, 35) -- Red hachimaki headband
	headband.Material = Enum.Material.Fabric
	headband.CanCollide = false
	headband.Parent = npc

	local weld1 = Instance.new('WeldConstraint')
	weld1.Part0 = hrp
	weld1.Part1 = torso
	weld1.Parent = hrp

	local weld2 = Instance.new('WeldConstraint')
	weld2.Part0 = hrp
	weld2.Part1 = head
	weld2.Parent = hrp

	local weld3 = Instance.new('WeldConstraint')
	weld3.Part0 = head
	weld3.Part1 = headband
	weld3.Parent = head

	-- Legs
	local legs = Instance.new('Part')
	legs.Name = 'LowerTorso'
	legs.Size = Vector3.new(2, 2.2, 1)
	legs.CFrame = cf * CFrame.new(0, -1.5, 0)
	legs.Color = Color3.fromRGB(20, 20, 25) -- Dark trousers
	legs.Material = Enum.Material.Fabric
	legs.CanCollide = false
	legs.Parent = npc

	local weld4 = Instance.new('WeldConstraint')
	weld4.Part0 = hrp
	weld4.Part1 = legs
	weld4.Parent = hrp

	local hum = Instance.new('Humanoid')
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.WalkSpeed = 12
	hum.Parent = npc

	-- Overhead Billboard
	local bb = Instance.new('BillboardGui')
	bb.Name = 'RoleTag'
	bb.Size = UDim2.fromOffset(180, 48)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = head
	bb.Parent = head

	local roleLbl = Instance.new('TextLabel')
	roleLbl.Size = UDim2.new(1, 0, 0.5, 0)
	roleLbl.BackgroundTransparency = 1
	roleLbl.Font = Enum.Font.FredokaOne
	roleLbl.TextSize = 13
	roleLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
	roleLbl.TextStrokeTransparency = 0.4
	roleLbl.Text = roleTitle
	roleLbl.Parent = bb

	local nameLbl = Instance.new('TextLabel')
	nameLbl.Position = UDim2.new(0, 0, 0.5, 0)
	nameLbl.Size = UDim2.new(1, 0, 0.5, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 14
	nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLbl.TextStrokeTransparency = 0.3
	nameLbl.Text = name
	nameLbl.Parent = bb

	local staffFolder = (restaurantModel or Workspace):FindFirstChild('Staff')
	if not staffFolder then
		staffFolder = Instance.new('Folder')
		staffFolder.Name = 'Staff'
		staffFolder.Parent = restaurantModel or Workspace
	end
	npc.Parent = staffFolder
	return npc
end

-- Spawn Cashier & Waiter NPCs
local function setupNPCs()
	-- 1. Cashier NPC behind counter
	local cashierCF = CFrame.new(24.5, 11.0, 89.0) * CFrame.Angles(0, math.rad(90), 0)
	cashierNPC = createStaffNPC('Tenin Akira (店員あきら)', '🍣 Cashier / レジ係', cashierCF)
	if cashierNPC.PrimaryPart then
		cashierNPC.PrimaryPart.Anchored = true
	end

	-- 2. Floor Waiter NPC near kitchen passage
	local waiterCF = CFrame.new(22.5, 11.0, 78.0) * CFrame.Angles(0, math.rad(90), 0)
	waiterNPC = createStaffNPC('Tenin Ren (店員れん)', '🥢 Waiter / 配膳係', waiterCF)
	if waiterNPC.PrimaryPart then
		waiterNPC.PrimaryPart.Anchored = false
	end
end

-- Setup Cash Register prop and Takeaway Prompt
local function setupCashierRegister()
	if not restaurantModel then return end

	local regPart = Instance.new('Part')
	regPart.Name = 'SushiCashRegister'
	regPart.Size = Vector3.new(2.4, 1.4, 2.2)
	regPart.CFrame = CFrame.new(26.8, 13.2, 89.0) * CFrame.Angles(0, math.rad(90), 0)
	regPart.Color = Color3.fromRGB(35, 40, 50)
	regPart.Material = Enum.Material.SmoothPlastic
	regPart.Anchored = true
	regPart.CanCollide = true
	regPart.Parent = restaurantModel

	-- Register Screen
	local screen = Instance.new('Part')
	screen.Name = 'RegisterScreen'
	screen.Size = Vector3.new(1.4, 0.9, 0.2)
	screen.CFrame = regPart.CFrame * CFrame.new(0, 0.9, 0.4) * CFrame.Angles(math.rad(-20), 0, 0)
	screen.Color = Color3.fromRGB(30, 160, 90) -- Glowing green POS display
	screen.Material = Enum.Material.Neon
	screen.Anchored = true
	screen.CanCollide = false
	screen.Parent = regPart

	registerPrompt = Instance.new('ProximityPrompt')
	registerPrompt.Name = 'SushiRegisterPrompt'
	registerPrompt.ActionText = 'Order (Takeaway) / 持ち帰り注文'
	registerPrompt.ObjectText = 'Sushi Cashier / 諏訪すし店 (レジ)'
	registerPrompt.KeyboardKeyCode = Enum.KeyCode.E
	registerPrompt.MaxActivationDistance = 10
	registerPrompt.RequiresLineOfSight = false
	registerPrompt.HoldDuration = 0
	registerPrompt.Parent = regPart

	registerPrompt.Triggered:Connect(function(player: Player)
		local profile = ProfileService.getProfile(player.UserId)
		local currentYen = (profile and profile.economy and profile.economy.yen) or 500
		RemoteRegistry.fireClient(player, 'SushiOpenMenu', {
			mode = 'takeaway',
			catalog = SUSHI_CATALOG,
			yen = currentYen,
			shopName = 'Suwa Sushi Takeaway / 諏訪すし店 (お持ち帰り)',
		})
	end)
end

-- Entrance Sensor (Irasshaimase Greeting)
local function setupEntranceSensor()
	if not restaurantModel then return end

	local sensor = Instance.new('Part')
	sensor.Name = 'SushiEntranceSensor'
	sensor.Size = Vector3.new(10, 8, 4)
	sensor.CFrame = CFrame.new(48.7, 13.0, 56.5)
	sensor.Transparency = 1
	sensor.Anchored = true
	sensor.CanCollide = false
	sensor.CanQuery = false
	sensor.Parent = restaurantModel

	local debounceList: { [Player]: number } = {}

	sensor.Touched:Connect(function(hit: BasePart)
		local char = hit.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if not player then return end

		local now = tick()
		if debounceList[player] and (now - debounceList[player]) < 8 then
			return
		end

		-- Check if player is moving inwards into the restaurant (heading +Z)
		local hrp = char:FindFirstChild('HumanoidRootPart') :: BasePart?
		if hrp and hrp.Velocity.Z > 0.5 then
			debounceList[player] = now
			playVoice(sensor, getIrasshaimaseSoundId(), 1.0)
		end
	end)
end

-- Setup Dining Tables with Seats
local function setupDiningTables()
	if not restaurantModel then return end
	local modelRoot = restaurantModel:FindFirstChild('Model')
	if not modelRoot then return end

	local tableIdx = 1
	for _, child in ipairs(modelRoot:GetChildren()) do
		if child:IsA('Model') and (child.Name == 'Model' or child.Name:find('Table_') ~= nil) then
			local cf, sz = child:GetBoundingBox()
			-- Identify the dining table sets (8.76 x 5.15 x 5.93)
			if sz.X > 7 and sz.X < 10 and sz.Z > 4.5 and sz.Z < 7 then
				local tableId = `Table_{tableIdx}`
				child.Name = tableId
				tableCenters[tableId] = cf.Position

				local isTerrace = cf.Position.Z < 55
				local tableName = if isTerrace then `Terrace Table {tableIdx} (テラス席)` else `Dining Table {tableIdx} (店内席)`

				-- Remove any prior DiningSeats if re-running
				for _, s in ipairs(child:GetChildren()) do
					if s:IsA('Seat') and s.Name:find('DiningSeat') then
						s:Destroy()
					end
				end

				-- Find bench cushions around this table (sz ~ 2.96 x 0.40 x 2.77, Y in [11.5, 12.3])
				local seatNum = 1
				for _, part in ipairs(child:GetDescendants()) do
					if part:IsA('BasePart') and part.Position.Y >= 11.5 and part.Position.Y <= 12.3 and part.Size.X > 2.0 and part.Size.Z > 2.0 then
						local benchPos = part.Position
						local lookDir = Vector3.new(cf.Position.X - benchPos.X, 0, cf.Position.Z - benchPos.Z)

						-- Place 2 comfortable seats per bench cushion
						local rightVec = CFrame.lookAt(Vector3.zero, lookDir).RightVector
						for _, sideOffset in ipairs({ -0.75, 0.75 }) do
							local seat = Instance.new('Seat')
							seat.Name = `DiningSeat_{seatNum}`
							seat.Size = Vector3.new(1.2, 0.4, 1.2)
							local basePos = benchPos + Vector3.new(0, 0.5, 0) + (rightVec * sideOffset)
							seat.CFrame = CFrame.lookAt(basePos, basePos + lookDir)
							seat.Transparency = 1
							seat.Anchored = true
							seat.CanCollide = false
							seat:SetAttribute('IsSushiSeat', true)
							seat:SetAttribute('TableId', tableId)
							seat:SetAttribute('TableName', tableName)
							seat:SetAttribute('TablePos', cf.Position)
							seat.Parent = child
							seatNum += 1
						end
					end
				end

				tableIdx += 1
			end
		end
	end
	print(`[SushiRestaurantService] Initialized {tableIdx - 1} dining tables with interactive seats`)
end

-- Spawn a temporary visual food dish on table
local function placeFoodOnTable(tablePos: Vector3, itemName: string)
	local plate = Instance.new('Part')
	plate.Name = 'ServedDish'
	plate.Size = Vector3.new(2.4, 0.25, 1.6)
	plate.CFrame = CFrame.new(tablePos.X, 11.75, tablePos.Z)
	plate.Color = Color3.fromRGB(50, 42, 38) -- Dark lacquer sushi geta board
	plate.Material = Enum.Material.Wood
	plate.Anchored = true
	plate.CanCollide = false

	local food = Instance.new('Part')
	food.Name = 'Food'
	food.Size = Vector3.new(2.0, 0.35, 1.2)
	food.CFrame = plate.CFrame * CFrame.new(0, 0.25, 0)
	food.Color = Color3.fromRGB(240, 110, 80) -- Salmon orange / sushi accents
	food.Material = Enum.Material.SmoothPlastic
	food.Anchored = true
	food.CanCollide = false
	food.Parent = plate

	plate.Parent = restaurantModel or Workspace
	Debris:AddItem(plate, 120) -- Cleans up after 2 minutes
end

-- Create edible Tool for the player
local function createEdibleTool(itemId: string, itemName: string, isDrink: boolean): Tool
	local tool = Instance.new('Tool')
	tool.Name = itemName
	tool:SetAttribute('ItemId', itemId)
	tool.CanBeDropped = false

	local handle = Instance.new('Part')
	handle.Name = 'Handle'
	handle.Size = if isDrink then Vector3.new(1, 1.4, 1) else Vector3.new(1.8, 0.4, 1.2)
	handle.Color = if isDrink then Color3.fromRGB(50, 120, 60) else Color3.fromRGB(230, 110, 70)
	handle.Material = if isDrink then Enum.Material.Ceramic else Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Parent = tool

	local sound = Instance.new('Sound')
	sound.Name = 'ConsumeSound'
	sound.SoundId = if isDrink then 'http://www.roblox.com/asset/?id=10722059' else 'http://www.roblox.com/asset/?id=15047813'
	sound.Volume = 1.0
	sound.Parent = handle

	tool.Activated:Connect(function()
		sound:Play()
		local char = tool.Parent
		local player = char and Players:GetPlayerFromCharacter(char)
		if player then
			local profile = ProfileService.getProfile(player.UserId)
			if profile and profile.progress then
				profile.progress.energy = math.min(100, (profile.progress.energy or 50) + (if isDrink then 20 else 35))
				profile.progress.hunger = math.max(0, (profile.progress.hunger or 0) - (if isDrink then 15 else 45))
			end
			RemoteRegistry.fireClient(player, 'ShopResult', true, if isDrink then `*Gulp* Refreshing {itemName}!` else `*Nom nom* Delicious {itemName}!`)
		end
		task.wait(1)
		tool:Destroy()
	end)

	return tool
end

-- Waiter serves the table
local function serveTable(player: Player, tableId: string, item: any)
	if waiterBusy or not waiterNPC then
		-- Instant fallback if waiter is occupied
		local tPos = tableCenters[tableId] or Vector3.new(41.5, 12.4, 67.3)
		placeFoodOnTable(tPos, item.name)
		local tool = createEdibleTool(item.id, item.name, item.category == 'drinks')
		tool.Parent = player.Backpack
		return
	end

	waiterBusy = true
	local hum = waiterNPC:FindFirstChildOfClass('Humanoid')
	local tPos = tableCenters[tableId] or Vector3.new(41.5, 12.4, 67.3)

	task.spawn(function()
		-- 1. Walk to table
		if hum then
			hum:MoveTo(tPos + Vector3.new(3, 0, 0))
			hum.MoveToFinished:Wait()
		end

		-- 2. Bow & speak
		local head = waiterNPC:FindFirstChild('Head')
		playVoice(head, getArigatouSoundId(), 1.0)
		playVoice(head, SOUND_SERVE, 0.8)

		-- 3. Place dish on table
		placeFoodOnTable(tPos, item.name)

		-- 4. Give player edible tool
		local isDrink = item.category == 'drinks'
		local tool = createEdibleTool(item.id, item.name, isDrink)
		tool.Parent = player.Backpack

		RemoteRegistry.fireClient(player, 'SushiTableServed', {
			tableId = tableId,
			itemName = item.name,
		})
		RemoteRegistry.fireClient(player, 'InventoryToast', `🍣「へい、お待ち！」 {item.name} が配膳されました！`)

		task.wait(2)

		-- 5. Return to station
		if hum and waiterNPC then
			hum:MoveTo(Vector3.new(22.5, 11.0, 78.0))
		end
		waiterBusy = false
	end)
end

function SushiRestaurantService.init()
	restaurantModel = Workspace:FindFirstChild('DiningDistrictPlaza') and Workspace.DiningDistrictPlaza:FindFirstChild('SuwaSushiRestaurant') :: Model?
	if not restaurantModel then
		warn('[SushiRestaurantService] SuwaSushiRestaurant model not found!')
		return
	end

	setupNPCs()
	setupCashierRegister()
	setupEntranceSensor()
	setupDiningTables()

	-- Remote Handler: Order from Takeaway or Dine-in Table
	RemoteRegistry.registerEvent('SushiOrder', function(player: Player, payload: any)
		if typeof(payload) ~= 'table' or typeof(payload.itemId) ~= 'string' then return end

		local itemId = payload.itemId
		local mode = payload.mode or 'takeaway' -- 'takeaway' | 'dine_in'
		local tableId = payload.tableId

		local selectedItem: any = nil
		for _, item in ipairs(SUSHI_CATALOG) do
			if item.id == itemId then
				selectedItem = item
				break
			end
		end
		if not selectedItem then return end

		local profile = ProfileService.getProfile(player.UserId)
		local price = selectedItem.price or 0
		local playerYen = (profile and profile.economy and profile.economy.yen) or 500

		if playerYen < price then
			local diff = price - playerYen
			RemoteRegistry.fireClient(player, 'ShopResult', false, `所持金が足りません (¥{diff} 不足)`)
			RemoteRegistry.fireClient(player, 'InventoryToast', `⚠️ Not enough Yen! (¥{diff} short / 所持金不足)`)
			return
		end

		-- Deduct payment
		if profile and profile.economy and profile.economy.yen then
			profile.economy.yen = math.max(0, profile.economy.yen - price)
			RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
		end

		if mode == 'takeaway' then
			-- Takeaway: cashier says thank you, puts in bag
			local soundPart = cashierNPC and cashierNPC:FindFirstChild('Head') or (player.Character and player.Character:FindFirstChild('HumanoidRootPart'))
			playVoice(soundPart, getArigatouSoundId(), 1.0)

			-- Add to InventoryService & Backpack
			InventoryService.addItem(player.UserId, selectedItem.id, 1)

			local isDrink = selectedItem.category == 'drinks'
			local tool = createEdibleTool(selectedItem.id, selectedItem.name, isDrink)
			tool.Parent = player.Backpack

			RemoteRegistry.fireClient(player, 'ShopResult', true, `「ありがとうございました！」 {selectedItem.name} を購入しました！ (¥{price})`)
			RemoteRegistry.fireClient(player, 'InventoryToast', `🥡 Packaged {selectedItem.name} in your bag! / お持ち帰り`)
		else
			-- Dine-In: Waiter serves to table
			RemoteRegistry.fireClient(player, 'ShopResult', true, `ご注文を承りました！ (¥{price})`)
			serveTable(player, tableId or 'Table_1', selectedItem)
		end
	end)

	print('[SushiRestaurantService] Suwa Sushi Restaurant fully activated with NPCs, Cashier, and Table Service!')
end

return SushiRestaurantService
