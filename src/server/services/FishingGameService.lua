--!strict

-- Complete lakeside fishing, shops and inventory-display gameplay loop.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Debris = game:GetService('Debris')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local InventoryService = require(script.Parent:WaitForChild('InventoryService'))
local FishingData = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Fishing'))

local CAST_TIME = 0.85
local MIN_WAIT = 4
local MAX_WAIT = 9
local BITE_WINDOW = 2.6
local MAX_SPOT_DISTANCE = 24

type FishingSession = {
	token: number,
	state: string,
	spot: BasePart,
	bobber: BasePart?,
	rodTool: Tool?,
}

local FishingGameService = {}
local sessions: { [Player]: FishingSession } = {}
local activeShops: { [Player]: { id: string, expiresAt: number } } = {}
local nextToken = 0

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = Instance.new('Part')
	object.Name = name
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = material
	object.Anchored = true
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.Parent = parent
	return object
end

local function snapshot(player: Player): any
	return InventoryService.getSnapshot(player.UserId)
end

local function pushInventory(player: Player)
	local current = snapshot(player)
	if current then
		RemoteRegistry.fireClient(player, 'InventoryUpdated', current)
	end
end

local function sendState(player: Player, state: string, payload: any?)
	RemoteRegistry.fireClient(player, 'FishingState', state, payload or {})
end

local function weldTo(handle: BasePart, part: BasePart, relative: CFrame)
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.Massless = true
	part.CFrame = handle.CFrame * relative
	local weld = Instance.new('WeldConstraint')
	weld.Part0 = handle
	weld.Part1 = part
	weld.Parent = part
end

local function clearDisplayedTool(player: Player)
	local function clear(container: Instance?)
		if not container then
			return
		end
		for _, child in container:GetChildren() do
			if child:IsA('Tool') and child:GetAttribute('InventoryDisplayTool') then
				child:Destroy()
			end
		end
	end
	clear(player.Character)
	clear(player:FindFirstChildOfClass('Backpack'))
end

local function createRodTool(player: Player, sessionOnly: boolean): Tool?
	local backpack = player:FindFirstChildOfClass('Backpack')
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if not backpack or not humanoid then
		return nil
	end

	if not sessionOnly then
		clearDisplayedTool(player)
	end
	local tool = Instance.new('Tool')
	tool.Name = if sessionOnly then 'Active Fishing Rod' else 'Beginner Fishing Rod'
	tool.CanBeDropped = false
	tool:SetAttribute('InventoryDisplayTool', not sessionOnly)
	tool:SetAttribute('FishingSessionTool', sessionOnly)

	local handle = Instance.new('Part')
	handle.Name = 'Handle'
	handle.Size = Vector3.new(0.25, 3.5, 0.25)
	handle.Color = Color3.fromRGB(91, 62, 41)
	handle.Material = Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local upper = Instance.new('Part')
	upper.Name = 'RodUpper'
	upper.Size = Vector3.new(0.16, 4.2, 0.16)
	upper.Color = Color3.fromRGB(45, 51, 48)
	upper.Material = Enum.Material.Metal
	upper.Parent = tool
	weldTo(handle, upper, CFrame.new(0, 3.7, 0) * CFrame.Angles(0, 0, math.rad(-7)))

	local reel = Instance.new('Part')
	reel.Name = 'Reel'
	reel.Shape = Enum.PartType.Cylinder
	reel.Size = Vector3.new(0.6, 0.8, 0.8)
	reel.Color = Color3.fromRGB(111, 117, 113)
	reel.Material = Enum.Material.Metal
	reel.Parent = tool
	weldTo(handle, reel, CFrame.new(0.42, 0.9, 0) * CFrame.Angles(0, math.rad(90), 0))

	local tipAttachment = Instance.new('Attachment')
	tipAttachment.Name = 'LineAttachment'
	tipAttachment.Position = Vector3.new(0, upper.Size.Y / 2, 0)
	tipAttachment.Parent = upper
	tool.Parent = backpack
	humanoid:EquipTool(tool)
	return tool
end

local function createFishTool(player: Player, fishId: string, displayName: string, color: Color3): Tool?
	local backpack = player:FindFirstChildOfClass('Backpack')
	if not backpack then
		return nil
	end
	clearDisplayedTool(player)
	local tool = Instance.new('Tool')
	tool.Name = displayName
	tool.CanBeDropped = false
	tool:SetAttribute('InventoryDisplayTool', true)
	tool:SetAttribute('ItemId', fishId)

	local handle = Instance.new('Part')
	handle.Name = 'Handle'
	handle.Shape = Enum.PartType.Ball
	handle.Size = if fishId == 'eel' then Vector3.new(0.55, 0.55, 3.8) else Vector3.new(1.0, 0.75, 2.6)
	handle.Color = color
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local tail = Instance.new('WedgePart')
	tail.Name = 'Tail'
	tail.Size = Vector3.new(0.9, 0.75, 0.8)
	tail.Color = color:Lerp(Color3.new(0, 0, 0), 0.15)
	tail.Material = Enum.Material.SmoothPlastic
	tail.Parent = tool
	weldTo(handle, tail, CFrame.new(0, 0, 1.65) * CFrame.Angles(0, math.rad(180), 0))

	for _, side in { -1, 1 } do
		local eye = Instance.new('Part')
		eye.Name = 'Eye'
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.14, 0.14, 0.14)
		eye.Color = Color3.fromRGB(20, 22, 21)
		eye.Material = Enum.Material.SmoothPlastic
		eye.Parent = tool
		weldTo(handle, eye, CFrame.new(side * 0.42, 0.18, -0.9))
	end
	tool.Parent = backpack
	return tool
end

local function createSimpleItemTool(player: Player, itemId: string, displayName: string): Tool?
	local backpack = player:FindFirstChildOfClass('Backpack')
	if not backpack then
		return nil
	end
	if itemId == 'fishing_rod' then
		return createRodTool(player, false)
	end
	clearDisplayedTool(player)
	local tool = Instance.new('Tool')
	tool.Name = displayName
	tool.CanBeDropped = false
	tool:SetAttribute('InventoryDisplayTool', true)
	tool:SetAttribute('ItemId', itemId)

	local handle = Instance.new('Part')
	handle.Name = 'Handle'
	handle.Size = Vector3.new(1.2, 1.8, 1.2)
	handle.Color = Color3.fromRGB(145, 104, 61)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	if string.find(itemId, 'ice_cream') or itemId == 'apple_sorbet' then
		handle.Shape = Enum.PartType.Cylinder
		handle.Size = Vector3.new(1.4, 0.8, 0.8)
		handle.CFrame *= CFrame.Angles(0, 0, math.rad(90))
		local scoop = Instance.new('Part')
		scoop.Name = 'Scoop'
		scoop.Shape = Enum.PartType.Ball
		scoop.Size = Vector3.new(1.25, 1.25, 1.25)
		scoop.Color = if itemId == 'matcha_ice_cream'
			then Color3.fromRGB(126, 160, 91)
			elseif itemId == 'apple_sorbet' then Color3.fromRGB(239, 170, 139)
			else Color3.fromRGB(244, 232, 203)
		scoop.Material = Enum.Material.SmoothPlastic
		scoop.Parent = tool
		weldTo(handle, scoop, CFrame.new(0.9, 0, 0))
		tool.Activated:Connect(function()
			local profile = ProfileService.getProfile(player.UserId)
			if not profile or (profile.inventory.items[itemId] or 0) <= 0 then
				tool:Destroy()
				return
			end
			profile.inventory.items[itemId] -= 1
			profile.progress.energy = math.min(100, profile.progress.energy + 5)
			profile.progress.hunger = math.max(0, profile.progress.hunger - 12)
			pushInventory(player)
			RemoteRegistry.fireClient(player, 'ShopResult', true, `{displayName} eaten.`)
			tool:Destroy()
		end)
	elseif itemId == 'ramune' or itemId == 'yakisoba' then
		if itemId == 'ramune' then
			handle.Shape = Enum.PartType.Cylinder
			handle.Size = Vector3.new(1.8, 0.65, 0.65)
			handle.Color = Color3.fromRGB(89, 187, 215)
			handle.Material = Enum.Material.Glass
		else
			handle.Size = Vector3.new(1.9, 0.55, 1.4)
			handle.Color = Color3.fromRGB(171, 92, 54)
			handle.Material = Enum.Material.SmoothPlastic
		end
		tool.Activated:Connect(function()
			local profile = ProfileService.getProfile(player.UserId)
			if not profile or (profile.inventory.items[itemId] or 0) <= 0 then
				tool:Destroy()
				return
			end
			profile.inventory.items[itemId] -= 1
			profile.progress.energy = math.min(100, profile.progress.energy + (if itemId == 'ramune' then 8 else 4))
			profile.progress.hunger = math.max(0, profile.progress.hunger - (if itemId == 'yakisoba' then 28 else 5))
			pushInventory(player)
			RemoteRegistry.fireClient(player, 'ShopResult', true, `{displayName} used.`)
			tool:Destroy()
		end)
	elseif itemId == 'sparkler_pack' then
		handle.Size = Vector3.new(0.45, 3.2, 0.45)
		handle.Color = Color3.fromRGB(214, 65, 52)
		handle.Material = Enum.Material.Wood
	elseif itemId == 'old_boot' then
		handle.Color = Color3.fromRGB(74, 55, 42)
		handle.Material = Enum.Material.Leather
		handle.Size = Vector3.new(1.1, 1.4, 2.2)
	elseif itemId == 'empty_can' then
		handle.Shape = Enum.PartType.Cylinder
		handle.Color = Color3.fromRGB(139, 151, 153)
		handle.Material = Enum.Material.Metal
		handle.Size = Vector3.new(1.5, 0.8, 0.8)
	elseif itemId == 'worm_bait' then
		handle.Color = Color3.fromRGB(104, 73, 53)
		handle.Size = Vector3.new(1.8, 0.65, 1.3)
	else
		handle.Color = Color3.fromRGB(63, 108, 91)
		handle.Material = Enum.Material.Fabric
		handle.Size = Vector3.new(2.2, 1.5, 1.2)
	end
	tool.Parent = backpack
	return tool
end

local function removeSessionVisuals(session: FishingSession)
	if session.bobber then
		session.bobber:Destroy()
	end
	if session.rodTool then
		session.rodTool:Destroy()
	end
end

local function finishSession(player: Player, state: string, payload: any?)
	local session = sessions[player]
	if not session then
		return
	end
	removeSessionVisuals(session)
	sessions[player] = nil
	sendState(player, state, payload)
end

local function isSessionValid(player: Player, token: number): boolean
	local session = sessions[player]
	if not session or session.token ~= token then
		return false
	end
	local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
	if not root or not root:IsA('BasePart') then
		return false
	end
	return (root.Position - session.spot.Position).Magnitude <= MAX_SPOT_DISTANCE
end

local function createBobber(player: Player, spot: BasePart, tool: Tool): BasePart
	local bobber = Instance.new('Part')
	bobber.Name = `FishingBobber_{player.UserId}`
	bobber.Shape = Enum.PartType.Ball
	bobber.Size = Vector3.new(0.65, 0.65, 0.65)
	bobber.Color = Color3.fromRGB(231, 71, 58)
	bobber.Material = Enum.Material.SmoothPlastic
	bobber.Anchored = true
	bobber.CanCollide = false
	bobber.CanTouch = false
	bobber.Position = spot.Position + Vector3.new(0, -1.75, -13)
	bobber.Parent = workspace
	local bobberAttachment = Instance.new('Attachment')
	bobberAttachment.Parent = bobber
	local tipAttachment = tool:FindFirstChild('LineAttachment', true)
	if tipAttachment and tipAttachment:IsA('Attachment') then
		local line = Instance.new('Beam')
		line.Name = 'FishingLine'
		line.Attachment0 = tipAttachment
		line.Attachment1 = bobberAttachment
		line.Width0 = 0.035
		line.Width1 = 0.035
		line.Color = ColorSequence.new(Color3.fromRGB(224, 228, 220))
		line.Transparency = NumberSequence.new(0.2)
		line.FaceCamera = true
		line.Parent = bobber
	end
	return bobber
end

local function rollCatch(fishingLevel: number): (string, any, boolean)
	local candidates = {}
	local totalWeight = 0
	for id, definition in FishingData.fish do
		local rarityBoost = if definition.rarity == 'Rare' then 1 + fishingLevel * 0.06 else 1
		local weight = definition.weight * rarityBoost
		table.insert(candidates, { id = id, definition = definition, weight = weight, isFish = true })
		totalWeight += weight
	end
	for id, definition in FishingData.junk do
		local weight = math.max(1.5, definition.weight - fishingLevel * 0.35)
		table.insert(candidates, { id = id, definition = definition, weight = weight, isFish = false })
		totalWeight += weight
	end
	local cursor = math.random() * totalWeight
	for _, candidate in candidates do
		cursor -= candidate.weight
		if cursor <= 0 then
			return candidate.id, candidate.definition, candidate.isFish
		end
	end
	local fallback = FishingData.fish.wakasagi
	return 'wakasagi', fallback, true
end

local function createCatchDisplay(player: Player, id: string, definition: any, isFish: boolean)
	local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
	if not root or not root:IsA('BasePart') then
		return
	end
	local model = Instance.new('Model')
	model.Name = `Caught_{id}`
	model.Parent = workspace
	local position = root.Position + root.CFrame.LookVector * 4 + Vector3.new(0, 3, 0)
	if isFish then
		local length = if id == 'eel' then 4.5 else 2.8
		local body = makePart(
			model,
			'FishBody',
			Vector3.new(0.95, 0.75, length),
			CFrame.new(position) * CFrame.Angles(0, math.rad(90), math.rad(-8)),
			definition.color,
			Enum.Material.SmoothPlastic
		)
		body.Shape = Enum.PartType.Ball
		local tail = makePart(
			model,
			'Tail',
			Vector3.new(0.8, 0.75, 0.8),
			body.CFrame * CFrame.new(0, 0, length * 0.55),
			definition.color:Lerp(Color3.new(0, 0, 0), 0.15),
			Enum.Material.SmoothPlastic
		)
		tail.Shape = Enum.PartType.Ball
	else
		makePart(
			model,
			'JunkCatch',
			Vector3.new(1.4, 1.7, 2.2),
			CFrame.new(position) * CFrame.Angles(math.rad(12), math.rad(20), 0),
			if id == 'old_boot' then Color3.fromRGB(74, 55, 42) else Color3.fromRGB(133, 145, 147),
			if id == 'old_boot' then Enum.Material.Leather else Enum.Material.Metal
		)
	end
	local anchor = model:FindFirstChildWhichIsA('BasePart')
	if anchor then
		local gui = Instance.new('BillboardGui')
		gui.Size = UDim2.fromOffset(220, 44)
		gui.StudsOffset = Vector3.new(0, 2, 0)
		gui.AlwaysOnTop = true
		gui.Adornee = anchor
		gui.Parent = anchor
		local label = Instance.new('TextLabel')
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundColor3 = Color3.fromRGB(25, 42, 49)
		label.BackgroundTransparency = 0.18
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Font = Enum.Font.GothamBold
		label.TextScaled = true
		label.Text = definition.name
		label.Parent = gui
	end
	Debris:AddItem(model, 4)
end

local function completeCatch(player: Player)
	local profile = ProfileService.getProfile(player.UserId)
	if not profile then
		finishSession(player, 'FAILED', { message = 'Profile is not ready.' })
		return
	end
	local id, definition, isFish = rollCatch(profile.progress.fishingLevel)
	local lengthCm: number? = nil
	local weightKg: number? = nil
	if isFish then
		lengthCm = math.random(definition.minLength, definition.maxLength)
		local ratio = lengthCm / definition.maxLength
		local maxWeight = if id == 'wakasagi'
			then 0.04
			elseif id == 'crucian_carp' then 1.4
			elseif id == 'common_carp' then 10
			elseif id == 'black_bass' then 3.5
			elseif id == 'rainbow_trout' then 4
			else 2
		weightKg = math.floor(maxWeight * ratio * ratio * ratio * 100 + 0.5) / 100
		InventoryService.addFish(player.UserId, id, 1)
		local totalCaught = 0
		for _, count in profile.inventory.fish do
			totalCaught += count
		end
		profile.progress.fishingLevel = math.max(profile.progress.fishingLevel, 1 + math.floor(totalCaught / 5))
	else
		InventoryService.addItem(player.UserId, id, 1)
	end
	createCatchDisplay(player, id, definition, isFish)
	pushInventory(player)
	finishSession(player, 'CAUGHT', {
		id = id,
		name = definition.name,
		japaneseName = definition.japaneseName,
		rarity = definition.rarity,
		isFish = isFish,
		lengthCm = lengthCm,
		weightKg = weightKg,
		value = definition.baseValue,
		fishingLevel = profile.progress.fishingLevel,
	})
end

local function beginFishing(player: Player, spot: BasePart)
	if sessions[player] then
		sendState(player, 'FAILED', { message = 'You already have a line in the water.' })
		return
	end
	local profile = ProfileService.getProfile(player.UserId)
	if not profile then
		sendState(player, 'FAILED', { message = 'Your profile is still loading.' })
		return
	end
	if (profile.inventory.items.fishing_rod or 0) < 1 then
		sendState(player, 'FAILED', { message = 'Buy a fishing rod at the tackle shop first.' })
		return
	end
	if (profile.inventory.items.worm_bait or 0) < 1 then
		sendState(player, 'FAILED', { message = 'You need worm bait from the tackle shop.' })
		return
	end
	local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
	if not root or not root:IsA('BasePart') or (root.Position - spot.Position).Magnitude > MAX_SPOT_DISTANCE then
		return
	end
	profile.inventory.items.worm_bait -= 1
	pushInventory(player)
	nextToken += 1
	local token = nextToken
	local tool = createRodTool(player, true)
	if not tool then
		sendState(player, 'FAILED', { message = 'Could not equip the fishing rod.' })
		return
	end
	local session: FishingSession = {
		token = token,
		state = 'CASTING',
		spot = spot,
		bobber = nil,
		rodTool = tool,
	}
	session.bobber = createBobber(player, spot, tool)
	sessions[player] = session
	sendState(player, 'CASTING', { message = 'Casting line…' })

	task.delay(CAST_TIME, function()
		if not isSessionValid(player, token) then
			finishSession(player, 'FAILED', { message = 'Fishing cancelled.' })
			return
		end
		local active = sessions[player]
		if not active then
			return
		end
		active.state = 'WAITING'
		local waitTime = math.random(MIN_WAIT * 10, MAX_WAIT * 10) / 10
		sendState(player, 'WAITING', { message = 'Watch the bobber…', waitTime = waitTime })
		task.delay(waitTime, function()
			if not isSessionValid(player, token) then
				finishSession(player, 'FAILED', { message = 'The line was pulled too far from the pier.' })
				return
			end
			local biting = sessions[player]
			if not biting then
				return
			end
			biting.state = 'BITE'
			if biting.bobber then
				biting.bobber.Color = Color3.fromRGB(255, 230, 87)
				biting.bobber.Material = Enum.Material.Neon
				biting.bobber.Position -= Vector3.new(0, 0.35, 0)
			end
			sendState(player, 'BITE', { message = 'A fish is biting! Reel now!', window = BITE_WINDOW })
			task.delay(BITE_WINDOW, function()
				local expired = sessions[player]
				if expired and expired.token == token and expired.state == 'BITE' then
					finishSession(player, 'FAILED', { message = 'The fish escaped.' })
				end
			end)
		end)
	end)
end

-- Titik mancing manual: BasePart mana pun dengan Attribute 'FishingSpot', atau
-- yang namanya diawali 'FishingSpot'. Dermaga Creator Store cukup ditandai satu
-- part kecil (boleh invisible) sebagai titik lempar kail.
local function configureFishingSpots()
	local found = 0
	for _, spot in workspace:GetDescendants() do
		if spot:IsA('BasePart') then
			local attributed = spot:GetAttribute('FishingSpot')
			local legacyMarker = spot.Name:match('^FishingSpot') ~= nil
			if (attributed or legacyMarker) and not spot:FindFirstChild('FishingPrompt') then
				-- Legacy greybox markers are meant to be invisible pads. A part the
				-- builder tagged themselves is their own model: leave it as-is.
				if legacyMarker and not attributed then
					spot.Transparency = 1
					spot.CanCollide = false
				end
				local prompt = Instance.new('ProximityPrompt')
				prompt.Name = 'FishingPrompt'
				prompt.ActionText = 'Cast line'
				prompt.ObjectText = 'Lake Suwa fishing spot'
				prompt.HoldDuration = 0.8
				prompt.MaxActivationDistance = 10
				prompt.RequiresLineOfSight = false
				prompt.Parent = spot
				prompt.Triggered:Connect(function(player)
					beginFishing(player, spot)
				end)
				found += 1
			end
		end
	end
	if found == 0 then
		warn(
			'[Fishing] No fishing spots found. Tag any part with the attribute '
				.. 'FishingSpot (boolean) to mark a casting point.'
		)
	end
end

-- Toko sekarang murni manual di Studio (model Creator Store). Tinggal beri
-- BasePart mana pun sebuah Attribute 'ShopId' (nilainya salah satu key di
-- FishingData.shops, mis. 'fishing_supply'), dan prompt beli otomatis terpasang.
local function configureManualShops()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('BasePart') then
			local shopId = descendant:GetAttribute('ShopId')
			if type(shopId) == 'string' and FishingData.shops[shopId] and not descendant:FindFirstChild('ShopPrompt') then
				local prompt = Instance.new('ProximityPrompt')
				prompt.Name = 'ShopPrompt'
				prompt.ActionText = 'Browse shop'
				prompt.ObjectText = FishingData.shops[shopId].name
				prompt.MaxActivationDistance = 11
				prompt.RequiresLineOfSight = false
				prompt.Parent = descendant
				prompt.Triggered:Connect(function(player)
					activeShops[player] = { id = shopId, expiresAt = os.clock() + 30 }
					RemoteRegistry.fireClient(player, 'OpenShop', FishingData.shops[shopId])
				end)
			end
		end
	end
end

local function buyItem(player: Player, payload: any)
	if typeof(payload) ~= 'table' or typeof(payload.shopId) ~= 'string' or typeof(payload.itemId) ~= 'string' then
		return
	end
	local access = activeShops[player]
	if not access or access.id ~= payload.shopId or access.expiresAt < os.clock() then
		RemoteRegistry.fireClient(player, 'ShopResult', false, 'Move closer to the shop counter.')
		return
	end
	local shop = FishingData.shops[payload.shopId]
	if not shop then
		return
	end
	local selected = nil
	for _, item in shop.items do
		if item.id == payload.itemId then
			selected = item
			break
		end
	end
	if not selected then
		return
	end
	local profile = ProfileService.getProfile(player.UserId)
	if not profile then
		RemoteRegistry.fireClient(player, 'ShopResult', false, 'Profile is still loading.')
		return
	end
	if profile.economy.yen < selected.price then
		RemoteRegistry.fireClient(player, 'ShopResult', false, 'Not enough yen.')
		return
	end
	profile.economy.yen -= selected.price
	InventoryService.addItem(player.UserId, selected.id, selected.amount)
	pushInventory(player)
	RemoteRegistry.fireClient(player, 'ShopResult', true, `Purchased {selected.name}.`)
end

local function inventoryAction(player: Player, payload: any)
	if typeof(payload) ~= 'table' or payload.action ~= 'equip' or typeof(payload.id) ~= 'string' then
		return
	end
	local profile = ProfileService.getProfile(player.UserId)
	if not profile then
		return
	end
	local id = payload.id
	if payload.category == 'fish' then
		if (profile.inventory.fish[id] or 0) <= 0 then
			return
		end
		local definition = FishingData.fish[id]
		if definition then
			createFishTool(player, id, definition.name, definition.color)
		end
	else
		if (profile.inventory.items[id] or 0) <= 0 then
			return
		end
		createSimpleItemTool(player, id, FishingData.itemNames[id] or id)
	end
end

function FishingGameService.init()
	configureManualShops()
	configureFishingSpots()

	RemoteRegistry.registerFunction('GetInventory', function(player: Player)
		return snapshot(player)
	end)
	RemoteRegistry.registerFunction('GetShopCatalog', function(_player: Player)
		return FishingData.shops
	end)
	RemoteRegistry.registerEvent('ShopBuy', buyItem)
	RemoteRegistry.registerEvent('InventoryAction', inventoryAction)
	RemoteRegistry.registerEvent('FishCast', function(player: Player)
		sendState(player, 'FAILED', { message = 'Use a marked fishing spot on a pier.' })
	end)
	RemoteRegistry.registerEvent('FishReel', function(player: Player)
		local session = sessions[player]
		if not session then
			return
		end
		if session.state == 'WAITING' or session.state == 'CASTING' then
			finishSession(player, 'FAILED', { message = 'Too early—the fish was scared away.' })
		elseif session.state == 'BITE' then
			session.state = 'REELING'
			sendState(player, 'REELING', { message = 'Reeling in…' })
			task.delay(0.8, function()
				if sessions[player] == session then
					completeCatch(player)
				end
			end)
		end
	end)

	ProfileService.onProfileLoaded(function(player)
		pushInventory(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local session = sessions[player]
		if session then
			removeSessionVisuals(session)
		end
		sessions[player] = nil
		activeShops[player] = nil
	end)
end

return FishingGameService
