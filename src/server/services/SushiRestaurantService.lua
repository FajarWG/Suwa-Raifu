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
	{ id = 'sushi_salmon_nigiri', name = 'Salmon Nigiri', japanese = 'サーモン握り', category = 'sushi', price = 450, icon = '🍣', desc = 'Fresh Atlantic salmon on seasoned sushi rice' },
	{ id = 'sushi_maguro_nigiri', name = 'Maguro Nigiri', japanese = '本マグロ握り', category = 'sushi', price = 550, icon = '🍣', desc = 'Prime bluefin maguro tuna, melt in your mouth' },
	{ id = 'sushi_california_roll', name = 'California Roll', japanese = 'カリフォルニアロール', category = 'sushi', price = 600, icon = '🍱', desc = 'Crab salad, fresh avocado & cucumber with sesame' },
	{ id = 'sushi_sashimi_combo', name = 'Sashimi Combo Platter', japanese = '特選刺身盛り合わせ', category = 'sushi', price = 1200, icon = '🥢', desc = "Chef's premium slices of salmon, tuna & sweetfish" },
	{ id = 'sushi_tempura_platter', name = 'Crispy Tempura Platter', japanese = '天ぷら盛り合わせ', category = 'dish', price = 850, icon = '🍤', desc = 'Light crispy battered prawns, lotus root & pumpkin' },
	{ id = 'sushi_miso_soup', name = 'Wakame Miso Soup', japanese = 'わかめ豆腐味噌汁', category = 'dish', price = 200, icon = '🍲', desc = 'Warm comforting dashi miso broth with silk tofu' },
	{ id = 'sushi_edamame', name = 'Salted Edamame', japanese = '枝豆', category = 'dish', price = 250, icon = '🌱', desc = 'Warm salted young Japanese soybeans' },
	{ id = 'sushi_green_tea', name = 'Uji Matcha Green Tea', japanese = '宇治抹茶・緑茶', category = 'drink', price = 150, icon = '🍵', desc = 'Steaming aromatic Japanese roasted green tea' },
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

	-- Arms
	local leftArm = Instance.new('Part')
	leftArm.Name = 'LeftUpperArm'
	leftArm.Size = Vector3.new(0.9, 1.8, 0.9)
	leftArm.CFrame = cf * CFrame.new(0, 0, -1.45)
	leftArm.Color = Color3.fromRGB(24, 30, 48)
	leftArm.Material = Enum.Material.Fabric
	leftArm.CanCollide = false
	leftArm.Parent = npc

	local weld5 = Instance.new('WeldConstraint')
	weld5.Part0 = hrp
	weld5.Part1 = leftArm
	weld5.Parent = hrp

	local rightArm = Instance.new('Part')
	rightArm.Name = 'RightUpperArm'
	rightArm.Size = Vector3.new(0.9, 1.8, 0.9)
	rightArm.CFrame = cf * CFrame.new(0, 0, 1.45)
	rightArm.Color = Color3.fromRGB(24, 30, 48)
	rightArm.Material = Enum.Material.Fabric
	rightArm.CanCollide = false
	rightArm.Parent = npc

	local weld6 = Instance.new('WeldConstraint')
	weld6.Part0 = hrp
	weld6.Part1 = rightArm
	weld6.Parent = hrp

	-- Overhead Billboard
	local bb = Instance.new('BillboardGui')
	bb.Name = 'RoleTag'
	bb.Size = UDim2.fromOffset(200, 50)
	bb.StudsOffset = Vector3.new(0, 3.0, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = 24
	bb.Adornee = head
	bb.Parent = head

	local badgeBg = Instance.new('Frame')
	badgeBg.Name = 'BadgeBg'
	badgeBg.Size = UDim2.fromScale(1, 1)
	badgeBg.BackgroundColor3 = Color3.fromRGB(16, 20, 28)
	badgeBg.BackgroundTransparency = 0.2
	badgeBg.BorderSizePixel = 0
	badgeBg.Parent = bb

	local bCorner = Instance.new('UICorner')
	bCorner.CornerRadius = UDim.new(0, 8)
	bCorner.Parent = badgeBg

	local bStroke = Instance.new('UIStroke')
	bStroke.Color = Color3.fromRGB(220, 175, 75)
	bStroke.Thickness = 1.2
	bStroke.Parent = badgeBg

	local roleLbl = Instance.new('TextLabel')
	roleLbl.Size = UDim2.new(1, 0, 0.48, 0)
	roleLbl.Position = UDim2.new(0, 0, 0.04, 0)
	roleLbl.BackgroundTransparency = 1
	roleLbl.Font = Enum.Font.FredokaOne
	roleLbl.TextSize = 13
	roleLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
	roleLbl.Text = roleTitle
	roleLbl.Parent = badgeBg

	local nameLbl = Instance.new('TextLabel')
	nameLbl.Position = UDim2.new(0, 0, 0.50, 0)
	nameLbl.Size = UDim2.new(1, 0, 0.46, 0)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font = Enum.Font.FredokaOne
	nameLbl.TextSize = 12
	nameLbl.TextColor3 = Color3.fromRGB(245, 248, 255)
	nameLbl.Text = name
	nameLbl.Parent = badgeBg

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
	local cashierCF = CFrame.new(24.5, 12.85, 89.0) * CFrame.Angles(0, math.rad(90), 0)
	cashierNPC = createStaffNPC('Tenin Akira (店員あきら)', '🍣 Cashier / レジ係', cashierCF)
	if cashierNPC.PrimaryPart then
		cashierNPC.PrimaryPart.Anchored = true
	end

	-- 2. Floor Waiter NPC near kitchen passage
	local waiterCF = CFrame.new(22.5, 12.85, 78.0) * CFrame.Angles(0, math.rad(90), 0)
	waiterNPC = createStaffNPC('Tenin Ren (店員れん)', '🥢 Waiter / 配膳係', waiterCF)
	if waiterNPC.PrimaryPart then
		waiterNPC.PrimaryPart.Anchored = true
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

				if child.Name == 'Table_7' then
					local pivot = child:GetPivot()
					if pivot.Position.X < 24 then
						child:PivotTo(pivot + Vector3.new(2.5, 0, 0))
						cf, sz = child:GetBoundingBox()
						tableCenters[tableId] = cf.Position
					end
				end

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

						-- Place 1 perfectly centered seat per chair cushion
						local seat = Instance.new('Seat')
						seat.Name = `DiningSeat_{seatNum}`
						seat.Size = Vector3.new(1.4, 0.4, 1.4)
						local basePos = benchPos + Vector3.new(0, 0.45, 0)
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

				tableIdx += 1
			end
		end
	end
	print(`[SushiRestaurantService] Initialized {tableIdx - 1} dining tables with interactive seats`)
end

-- Spawn an interactive food dish on table that the player eats bite-by-bite
function SushiRestaurantService.placeFoodOnTable(tablePos: Vector3, itemName: string, isDrink: boolean, orderingPlayer: Player?)
	local plate = Instance.new('Part')
	plate.Name = 'ServedDish'
	plate.Size = Vector3.new(2.4, 0.25, 1.6)
	plate.CFrame = CFrame.new(tablePos.X, 14.15, tablePos.Z)
	plate.Color = Color3.fromRGB(50, 42, 38) -- Dark lacquer sushi geta board
	plate.Material = Enum.Material.Wood
	plate.Anchored = true
	plate.CanCollide = false

	local food = Instance.new('Part')
	food.Name = 'Food'
	food.Size = if isDrink then Vector3.new(0.9, 1.3, 0.9) else Vector3.new(2.0, 0.35, 1.2)
	food.CFrame = plate.CFrame * CFrame.new(0, if isDrink then 0.75 else 0.25, 0)
	food.Color = if isDrink then Color3.fromRGB(60, 140, 70) else Color3.fromRGB(240, 110, 80)
	food.Material = if isDrink then Enum.Material.Glass else Enum.Material.SmoothPlastic
	food.Anchored = true
	food.CanCollide = false
	food.Parent = plate

	local bitesRemaining = 3
	plate:SetAttribute('BitesRemaining', bitesRemaining)

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'EatPrompt'
	prompt.ActionText = if isDrink then 'Take a sip / 一口飲む' else 'Take a bite / 一口食べる'
	prompt.ObjectText = `{itemName} ({bitesRemaining} bites left / 3口)`
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 14
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.RequiresLineOfSight = false
	prompt.Parent = plate

	local clickDetector = Instance.new('ClickDetector')
	clickDetector.MaxActivationDistance = 16
	clickDetector.Parent = plate

	local function onEat(eatingPlayer: Player)
		if bitesRemaining <= 0 then return end
		bitesRemaining -= 1
		plate:SetAttribute('BitesRemaining', bitesRemaining)

		local sound = Instance.new('Sound')
		sound.SoundId = if isDrink then 'http://www.roblox.com/asset/?id=10722059' else 'http://www.roblox.com/asset/?id=15047813'
		sound.Volume = 1.0
		sound.Parent = plate
		sound:Play()
		Debris:AddItem(sound, 2)

		-- Update player stats
		local profile = ProfileService.getProfile(eatingPlayer.UserId)
		if profile and profile.progress then
			profile.progress.energy = math.min(100, (profile.progress.energy or 50) + (if isDrink then 10 else 18))
			profile.progress.hunger = math.max(0, (profile.progress.hunger or 0) - (if isDrink then 8 else 20))
		end

		if bitesRemaining > 0 then
			local scale = bitesRemaining / 3
			food.Size = if isDrink then Vector3.new(0.9 * scale, 1.3 * scale, 0.9 * scale) else Vector3.new(2.0 * scale, 0.35, 1.2 * scale)
			prompt.ObjectText = `{itemName} ({bitesRemaining} bites left / 残り{bitesRemaining}口)`
			RemoteRegistry.fireClient(eatingPlayer, 'InventoryToast', if isDrink then `🍵 *Sip* ({bitesRemaining} sips left / 残り{bitesRemaining}口)` else `🍣 *Nom nom* ({bitesRemaining} bites left / 残り{bitesRemaining}口)`)
		else
			food:Destroy()
			prompt.Enabled = false
			clickDetector.MaxActivationDistance = 0
			RemoteRegistry.fireClient(eatingPlayer, 'InventoryToast', if isDrink then `🍵 Finished drink! Refreshing! / 完飲！ごちそうさまでした！` else `🍣 Finished meal! Delicious! / 完食！ごちそうさまでした！`)
			task.delay(1.5, function()
				if plate and plate.Parent then
					plate:Destroy()
				end
			end)
		end
	end

	prompt.Triggered:Connect(onEat)
	clickDetector.MouseClick:Connect(onEat)

	plate.Parent = restaurantModel or Workspace
	Debris:AddItem(plate, 180)
	return plate
end

-- Helper to smoothly walk an NPC along a list of Vector3 waypoints
local function walkNpcWaypoints(npc: Model, waypoints: { Vector3 }, speed: number?)
	local hrp = npc:FindFirstChild('HumanoidRootPart') :: BasePart?
	if not hrp then return end
	local walkSpeed = speed or 13.5 -- studs per second

	for i = 1, #waypoints do
		local targetPos = waypoints[i]
		local startPos = hrp.Position
		local flatCurrent = Vector3.new(startPos.X, targetPos.Y, startPos.Z)
		local delta = targetPos - flatCurrent
		local dist = delta.Magnitude

		if dist > 0.4 then
			local duration = dist / walkSpeed
			local steps = math.max(3, math.floor(duration / 0.035))
			local lookDir = Vector3.new(delta.X, 0, delta.Z).Unit

			for step = 1, steps do
				local alpha = step / steps
				local currentInterPos = startPos:Lerp(targetPos, alpha)
				local lookTarget = currentInterPos + lookDir
				npc:PivotTo(CFrame.lookAt(currentInterPos, Vector3.new(lookTarget.X, currentInterPos.Y, lookTarget.Z)))
				task.wait(0.035)
			end
		end
	end
end

-- Waiter serves the table
function SushiRestaurantService.serveTable(player: Player, tableId: string, item: any)
	local isDrink = item.category == 'drink' or item.category == 'drinks'
	local resolvedTableId = tostring(tableId or '')
	local tPos: Vector3? = tableCenters[resolvedTableId]
	if not tPos then
		local numOnly = resolvedTableId:gsub('%D', '')
		if numOnly ~= '' then
			tPos = tableCenters['Table_' .. numOnly]
		end
	end
	if not tPos and restaurantModel then
		local sub = restaurantModel:FindFirstChild('Model')
		local tModel = sub and (sub:FindFirstChild(resolvedTableId) or sub:FindFirstChild('Table_' .. resolvedTableId:gsub('%D', '')))
		if tModel and tModel:IsA('Model') then
			local cf = tModel:GetBoundingBox()
			tPos = cf.Position
		end
	end
	if not tPos then
		local char = player.Character
		local hum = char and char:FindFirstChild('Humanoid')
		local seat = hum and hum.SeatPart
		if seat and seat:GetAttribute('TablePos') then
			tPos = seat:GetAttribute('TablePos')
		end
	end
	tPos = tPos or tableCenters['Table_7'] or Vector3.new(25.37, 12.42, 42.92)

	if waiterBusy or not waiterNPC or not waiterNPC.PrimaryPart then
		SushiRestaurantService.placeFoodOnTable(tPos, item.name, isDrink, player)
		return
	end

	waiterBusy = true
	local stationPos = Vector3.new(22.5, 12.85, 78.0)
	local isTerrace = tPos.Z < 55

	task.spawn(function()
		-- 1. Create Serving Tray welded in front of Waiter Ren
		local tray = Instance.new('Part')
		tray.Name = 'LacquerTray'
		tray.Size = Vector3.new(2.2, 0.18, 1.5)
		tray.Color = Color3.fromRGB(45, 36, 32)
		tray.Material = Enum.Material.Wood
		tray.CanCollide = false
		tray.Anchored = false

		local trayFood = Instance.new('Part')
		trayFood.Name = 'TrayFood'
		trayFood.Size = if isDrink then Vector3.new(0.8, 1.1, 0.8) else Vector3.new(1.8, 0.3, 1.1)
		trayFood.Color = if isDrink then Color3.fromRGB(60, 140, 70) else Color3.fromRGB(240, 110, 80)
		trayFood.Material = if isDrink then Enum.Material.Glass else Enum.Material.SmoothPlastic
		trayFood.CanCollide = false
		trayFood.Anchored = false
		trayFood.Parent = tray

		local weldDish = Instance.new('WeldConstraint')
		weldDish.Part0 = tray
		weldDish.Part1 = trayFood
		weldDish.Parent = tray
		trayFood.CFrame = tray.CFrame * CFrame.new(0, if isDrink then 0.6 else 0.2, 0)

		local hrp = waiterNPC.PrimaryPart :: BasePart
		tray.CFrame = hrp.CFrame * CFrame.new(0, -0.2, -1.5)
		local weldTray = Instance.new('WeldConstraint')
		weldTray.Part0 = hrp
		weldTray.Part1 = tray
		weldTray.Parent = hrp
		tray.Parent = waiterNPC

		-- 2. Determine Outbound and Inbound Waypoints
		local outboundWaypoints: { Vector3 } = {}
		local inboundWaypoints: { Vector3 } = {}

		if isTerrace then
			-- Terrace table pathing through interior aisle and door (X=48.71, Z=55.8)
			local deliverySpot = Vector3.new(tPos.X, 12.85, tPos.Z - 3.2)
			outboundWaypoints = {
				Vector3.new(34.0, 12.85, 78.0),
				Vector3.new(48.7, 12.85, 68.0),
				Vector3.new(48.7, 12.85, 55.8), -- Door
				Vector3.new(48.7, 12.85, 48.0), -- Terrace walkway
				Vector3.new(tPos.X, 12.85, 48.0),
				deliverySpot,
			}
			inboundWaypoints = {
				Vector3.new(tPos.X, 12.85, 48.0),
				Vector3.new(48.7, 12.85, 48.0),
				Vector3.new(48.7, 12.85, 55.8), -- Door
				Vector3.new(48.7, 12.85, 68.0),
				Vector3.new(34.0, 12.85, 78.0),
				stationPos,
			}
		else
			-- Indoor dining table pathing along central aisle
			local aisleX = 34.0
			local deliverySpot = Vector3.new(tPos.X + (if tPos.X < aisleX then 3.2 else -3.2), 12.85, tPos.Z)
			outboundWaypoints = {
				Vector3.new(aisleX, 12.85, 78.0),
				Vector3.new(aisleX, 12.85, tPos.Z),
				deliverySpot,
			}
			inboundWaypoints = {
				Vector3.new(aisleX, 12.85, tPos.Z),
				Vector3.new(aisleX, 12.85, 78.0),
				stationPos,
			}
		end

		-- 3. Walk out to table
		walkNpcWaypoints(waiterNPC, outboundWaypoints, 13.5)

		-- 4. Arrive at table, face the table / customer
		local arrivalPos = hrp.Position
		waiterNPC:PivotTo(CFrame.lookAt(arrivalPos, Vector3.new(tPos.X, arrivalPos.Y, tPos.Z)))

		-- Remove tray from hands
		tray:Destroy()

		-- Bow & speak
		local head = waiterNPC:FindFirstChild('Head')
		playVoice(head, getIrasshaimaseSoundId(), 1.0)
		playVoice(head, SOUND_SERVE, 0.9)

		-- 5. Place interactive dish on table
		SushiRestaurantService.placeFoodOnTable(tPos, item.name, isDrink, player)

		RemoteRegistry.fireClient(player, 'SushiTableServed', {
			tableId = tableId,
			itemName = item.name,
		})
		RemoteRegistry.fireClient(player, 'InventoryToast', `🍣「へい、お待ち！」 {item.name} が配膳されました！`)

		-- Stay for 3.5 seconds so the customer clearly sees the waiter serving
		task.wait(3.5)

		-- 6. Walk back along waypoints to station
		walkNpcWaypoints(waiterNPC, inboundWaypoints, 13.5)

		-- Face default counter direction
		waiterNPC:PivotTo(CFrame.new(stationPos) * CFrame.Angles(0, math.rad(90), 0))
		waiterBusy = false
	end)
end

function SushiRestaurantService.init()
	local plaza = Workspace:FindFirstChild('DiningDistrictPlaza') or Workspace:WaitForChild('DiningDistrictPlaza', 10)
	restaurantModel = plaza and (plaza:FindFirstChild('SuwaSushiRestaurant') or plaza:WaitForChild('SuwaSushiRestaurant', 10)) :: Model?
	if not restaurantModel then
		warn('[SushiRestaurantService] SuwaSushiRestaurant model not found!')
	else
		setupNPCs()
		setupCashierRegister()
		setupEntranceSensor()
		setupDiningTables()
	end

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

		-- Deduct payment & sync real-time
		if profile and profile.economy and profile.economy.yen then
			profile.economy.yen = math.max(0, profile.economy.yen - price)
			RemoteRegistry.fireClient(player, 'ProfileUpdated', profile)
		end

		if mode == 'takeaway' then
			-- Takeaway: cashier says thank you, puts in bag
			local soundPart = cashierNPC and cashierNPC:FindFirstChild('Head') or (player.Character and player.Character:FindFirstChild('HumanoidRootPart'))
			playVoice(soundPart, getArigatouSoundId(), 1.0)

			-- Add to InventoryService & sync bag real-time
			InventoryService.addItem(player.UserId, selectedItem.id, 1)
			local snap = InventoryService.getSnapshot(player.UserId)
			if snap then
				RemoteRegistry.fireClient(player, 'InventoryUpdated', snap)
			end

			RemoteRegistry.fireClient(player, 'ShopResult', true, `「ありがとうございました！」 {selectedItem.name} を購入しました！ (¥{price})`)
			RemoteRegistry.fireClient(player, 'InventoryToast', `🎒 Packaged {selectedItem.name} in your bag! / バッグに入りました`)
		else
			-- Dine-In: Waiter serves to table
			RemoteRegistry.fireClient(player, 'ShopResult', true, `ご注文を承りました！ (¥{price})`)
			SushiRestaurantService.serveTable(player, tableId or 'Table_7', selectedItem)
		end
	end)

	print('[SushiRestaurantService] Suwa Sushi Restaurant fully activated with NPCs, Cashier, and Table Service!')
end

return SushiRestaurantService
