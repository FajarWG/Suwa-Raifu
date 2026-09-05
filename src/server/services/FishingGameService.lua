--!strict

-- Complete lakeside fishing, shops and inventory-display gameplay loop.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Debris = game:GetService('Debris')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local ProfileService = require(script.Parent:WaitForChild('ProfileService'))
local InventoryService = require(script.Parent:WaitForChild('InventoryService'))
local FishingData = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Fishing'))

local CAST_TIME = 0.7
local MIN_WAIT = 1.8
local MAX_WAIT = 3.8
local BITE_WINDOW = 3.6
local MAX_SPOT_DISTANCE = 32

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

local function terrainHeight(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 90, z), Vector3.new(0, -200, 0), parameters)
	return if result then result.Position.Y else fallback
end

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

local function addSign(part: BasePart, text: string)
	local gui = Instance.new('SurfaceGui')
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 40
	gui.Parent = part
	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.fromRGB(55, 48, 38)
	label.TextScaled = true
	label.Parent = gui
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

	-- Default holding grip
	tool.GripForward = Vector3.new(0, 0, -1)
	tool.GripPos = Vector3.new(0, -0.4, -0.1)
	tool.GripRight = Vector3.new(1, 0, 0)
	tool.GripUp = Vector3.new(0, 1, 0)

	local handle = Instance.new('Part')
	handle.Name = 'Handle'
	handle.Size = Vector3.new(1.0, 1.0, 1.0)
	handle.Color = Color3.fromRGB(145, 104, 61)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local isFood = false
	local isDrink = false

	if itemId == 'dango' then
		isFood = true
		handle.Size = Vector3.new(0.12, 1.8, 0.12)
		handle.Color = Color3.fromRGB(205, 175, 130)
		handle.Material = Enum.Material.Wood

		local colors = {
			Color3.fromRGB(165, 205, 140), -- Green (Yomogi)
			Color3.fromRGB(250, 248, 245), -- White
			Color3.fromRGB(255, 182, 193), -- Pink (Cherry Blossom)
		}
		local offsets = { -0.15, 0.35, 0.85 }
		for i = 1, 3 do
			local ball = Instance.new('Part')
			ball.Name = 'Dango' .. i
			ball.Shape = Enum.PartType.Ball
			ball.Size = Vector3.new(0.55, 0.55, 0.55)
			ball.Color = colors[i]
			ball.Material = Enum.Material.SmoothPlastic
			ball.Parent = tool
			weldTo(handle, ball, CFrame.new(0, offsets[i], 0))
		end

	elseif itemId == 'yakisoba' then
		isFood = true
		handle.Size = Vector3.new(1.4, 0.5, 1.8)
		handle.Color = Color3.fromRGB(240, 225, 200)
		handle.Material = Enum.Material.SmoothPlastic

		local noodles = Instance.new('Part')
		noodles.Name = 'Noodles'
		noodles.Size = Vector3.new(1.2, 0.4, 1.6)
		noodles.Color = Color3.fromRGB(130, 75, 40)
		noodles.Material = Enum.Material.SmoothPlastic
		noodles.Parent = tool
		weldTo(handle, noodles, CFrame.new(0, 0.2, 0))

		local ginger = Instance.new('Part')
		ginger.Name = 'Ginger'
		ginger.Size = Vector3.new(0.3, 0.15, 0.4)
		ginger.Color = Color3.fromRGB(220, 40, 40)
		ginger.Material = Enum.Material.SmoothPlastic
		ginger.Parent = tool
		weldTo(handle, ginger, CFrame.new(0.2, 0.4, 0))

	elseif itemId == 'taiyaki' then
		isFood = true
		handle.Size = Vector3.new(0.4, 1.1, 1.6)
		handle.Color = Color3.fromRGB(215, 150, 75)
		handle.Material = Enum.Material.SmoothPlastic

		local tail = Instance.new('Part')
		tail.Name = 'Tail'
		tail.Size = Vector3.new(0.3, 0.8, 0.6)
		tail.Color = Color3.fromRGB(200, 135, 65)
		tail.Material = Enum.Material.SmoothPlastic
		tail.Parent = tool
		weldTo(handle, tail, CFrame.new(0, 0, -0.9))

	elseif itemId == 'onigiri' then
		isFood = true
		handle.Size = Vector3.new(0.65, 1.0, 1.0)
		handle.Color = Color3.fromRGB(250, 250, 248)
		handle.Material = Enum.Material.SmoothPlastic

		local nori = Instance.new('Part')
		nori.Name = 'Nori'
		nori.Size = Vector3.new(0.7, 0.5, 0.55)
		nori.Color = Color3.fromRGB(30, 35, 30)
		nori.Material = Enum.Material.Fabric
		nori.Parent = tool
		weldTo(handle, nori, CFrame.new(0, -0.25, 0))

	elseif string.find(itemId, 'ice_cream') or itemId == 'apple_sorbet' then
		isFood = true
		handle.Shape = Enum.PartType.Cylinder
		handle.Size = Vector3.new(1.4, 0.8, 0.8)
		handle.Color = Color3.fromRGB(195, 145, 90)
		handle.CFrame *= CFrame.Angles(0, 0, math.rad(90))

		local scoop = Instance.new('Part')
		scoop.Name = 'Scoop'
		scoop.Shape = Enum.PartType.Ball
		scoop.Size = Vector3.new(1.25, 1.25, 1.25)
		scoop.Color = if itemId == 'matcha_ice_cream'
			then Color3.fromRGB(126, 160, 91)
			elseif itemId == 'apple_sorbet' then Color3.fromRGB(239, 170, 139)
			elseif itemId == 'strawberry_ice_cream' then Color3.fromRGB(255, 150, 180)
			elseif itemId == 'chocolate_ice_cream' then Color3.fromRGB(105, 55, 30)
			else Color3.fromRGB(244, 232, 203)
		scoop.Material = Enum.Material.SmoothPlastic
		scoop.Parent = tool
		weldTo(handle, scoop, CFrame.new(0.9, 0, 0))

	elseif itemId == 'ramune' then
		isDrink = true
		handle.Shape = Enum.PartType.Cylinder
		handle.Size = Vector3.new(1.8, 0.65, 0.65)
		handle.Color = Color3.fromRGB(100, 205, 235)
		handle.Material = Enum.Material.Glass
		handle.Transparency = 0.35

		local cap = Instance.new('Part')
		cap.Name = 'Cap'
		cap.Shape = Enum.PartType.Cylinder
		cap.Size = Vector3.new(0.3, 0.45, 0.45)
		cap.Color = Color3.fromRGB(230, 240, 245)
		cap.Material = Enum.Material.SmoothPlastic
		cap.Parent = tool
		weldTo(handle, cap, CFrame.new(0, 1.0, 0))

	elseif itemId == 'matcha_tea' or itemId == 'ice_coffee' then
		isDrink = true
		handle.Shape = Enum.PartType.Cylinder
		handle.Size = Vector3.new(1.6, 0.8, 0.8)
		handle.Color = if itemId == 'ice_coffee' then Color3.fromRGB(65, 40, 25) else Color3.fromRGB(90, 145, 60)
		handle.Material = Enum.Material.Glass
		handle.Transparency = 0.2

		local lid = Instance.new('Part')
		lid.Name = 'Lid'
		lid.Shape = Enum.PartType.Cylinder
		lid.Size = Vector3.new(0.3, 0.85, 0.85)
		lid.Color = Color3.fromRGB(245, 245, 245)
		lid.Material = Enum.Material.SmoothPlastic
		lid.Parent = tool
		weldTo(handle, lid, CFrame.new(0, 0.9, 0))

		local straw = Instance.new('Part')
		straw.Name = 'Straw'
		straw.Size = Vector3.new(0.1, 1.2, 0.1)
		straw.Color = if itemId == 'ice_coffee' then Color3.fromRGB(200, 150, 80) else Color3.fromRGB(70, 170, 90)
		straw.Material = Enum.Material.SmoothPlastic
		straw.Parent = tool
		weldTo(handle, straw, CFrame.new(0.15, 1.2, 0) * CFrame.Angles(0, 0, math.rad(-15)))

	elseif itemId == 'sparkler_pack' then
		handle.Size = Vector3.new(0.45, 2.8, 0.45)
		handle.Color = Color3.fromRGB(214, 65, 52)
		handle.Material = Enum.Material.Wood

		local tip = Instance.new('Part')
		tip.Name = 'SparklerTip'
		tip.Size = Vector3.new(0.2, 0.6, 0.2)
		tip.Color = Color3.fromRGB(255, 220, 100)
		tip.Material = Enum.Material.Neon
		tip.Parent = tool
		weldTo(handle, tip, CFrame.new(0, 1.6, 0))

		local sparkles = Instance.new('Sparkles')
		sparkles.SparkleColor = Color3.fromRGB(255, 215, 0)
		sparkles.Enabled = false
		sparkles.Parent = tip

		local lit = false
		tool.Activated:Connect(function()
			if lit then return end
			lit = true
			sparkles.Enabled = true
			RemoteRegistry.fireClient(player, 'ShopResult', true, 'Sparkler lit! Enjoy the festival fireworks!')
			task.delay(8, function()
				if tool and tool.Parent then
					local profile = ProfileService.getProfile(player.UserId)
					if profile and profile.inventory and profile.inventory.items then
						local cur = profile.inventory.items[itemId] or 0
						if cur > 1 then
							profile.inventory.items[itemId] = cur - 1
						else
							profile.inventory.items[itemId] = nil
						end
						pushInventory(player)
					end
					tool:Destroy()
				end
			end)
		end)

	elseif itemId == 'fishing_rod' or itemId == 'pro_fishing_rod' then
		local isPro = itemId == 'pro_fishing_rod'
		handle.Size = Vector3.new(0.2, 1.2, 0.2)
		handle.Color = if isPro then Color3.fromRGB(35, 38, 42) else Color3.fromRGB(160, 120, 75)
		handle.Material = if isPro then Enum.Material.Metal else Enum.Material.Wood

		local pole = Instance.new('Part')
		pole.Name = 'Pole'
		pole.Size = Vector3.new(0.12, 6.5, 0.12)
		pole.Color = if isPro then Color3.fromRGB(55, 60, 68) else Color3.fromRGB(195, 160, 110)
		pole.Material = if isPro then Enum.Material.SmoothPlastic else Enum.Material.Wood
		pole.Parent = tool
		weldTo(handle, pole, CFrame.new(0, 3.8, 0))

		local reel = Instance.new('Part')
		reel.Name = 'Reel'
		reel.Shape = Enum.PartType.Cylinder
		reel.Size = Vector3.new(0.4, 0.45, 0.45)
		reel.Color = if isPro then Color3.fromRGB(220, 180, 50) else Color3.fromRGB(180, 180, 185)
		reel.Material = Enum.Material.Metal
		reel.Parent = tool
		weldTo(handle, reel, CFrame.new(0.25, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)))

	elseif itemId == 'tackle_box' then
		handle.Size = Vector3.new(1.8, 1.1, 1.0)
		handle.Color = Color3.fromRGB(50, 105, 120)
		handle.Material = Enum.Material.SmoothPlastic

		local handlePart = Instance.new('Part')
		handlePart.Name = 'BoxHandle'
		handlePart.Size = Vector3.new(0.8, 0.35, 0.15)
		handlePart.Color = Color3.fromRGB(220, 220, 220)
		handlePart.Material = Enum.Material.Metal
		handlePart.Parent = tool
		weldTo(handle, handlePart, CFrame.new(0, 0.65, 0))

	elseif itemId == 'golden_lure' then
		handle.Shape = Enum.PartType.Ball
		handle.Size = Vector3.new(0.65, 0.65, 0.65)
		handle.Color = Color3.fromRGB(255, 215, 0)
		handle.Material = Enum.Material.Metal

		local blade = Instance.new('Part')
		blade.Name = 'SpinnerBlade'
		blade.Size = Vector3.new(0.1, 0.8, 0.4)
		blade.Color = Color3.fromRGB(255, 235, 120)
		blade.Material = Enum.Material.Neon
		blade.Parent = tool
		weldTo(handle, blade, CFrame.new(0, 0.5, 0))

	elseif itemId == 'fisherman_tea' then
		isDrink = true
		handle.Shape = Enum.PartType.Cylinder
		handle.Size = Vector3.new(1.4, 0.75, 0.75)
		handle.Color = Color3.fromRGB(45, 95, 55)
		handle.Material = Enum.Material.Metal

		local lid = Instance.new('Part')
		lid.Name = 'CanTop'
		lid.Shape = Enum.PartType.Cylinder
		lid.Size = Vector3.new(0.15, 0.72, 0.72)
		lid.Color = Color3.fromRGB(200, 205, 210)
		lid.Material = Enum.Material.Metal
		lid.Parent = tool
		weldTo(handle, lid, CFrame.new(0, 0.72, 0))

	elseif itemId == 'umeboshi_onigiri' then
		isFood = true
		handle.Size = Vector3.new(0.65, 1.0, 1.0)
		handle.Color = Color3.fromRGB(250, 250, 248)
		handle.Material = Enum.Material.SmoothPlastic

		local nori = Instance.new('Part')
		nori.Name = 'Nori'
		nori.Size = Vector3.new(0.7, 0.5, 0.55)
		nori.Color = Color3.fromRGB(25, 30, 25)
		nori.Material = Enum.Material.Fabric
		nori.Parent = tool
		weldTo(handle, nori, CFrame.new(0, -0.25, 0))

		local ume = Instance.new('Part')
		ume.Name = 'Umeboshi'
		ume.Shape = Enum.PartType.Ball
		ume.Size = Vector3.new(0.28, 0.28, 0.28)
		ume.Color = Color3.fromRGB(195, 35, 45)
		ume.Material = Enum.Material.SmoothPlastic
		ume.Parent = tool
		weldTo(handle, ume, CFrame.new(0.32, 0.15, 0))

	elseif itemId == 'shrimp_bait' then
		handle.Color = Color3.fromRGB(210, 95, 75)
		handle.Size = Vector3.new(1.4, 0.55, 1.1)
		handle.Material = Enum.Material.SmoothPlastic

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

	-- Interactivity for food & drinks
	if isFood or isDrink then
		local consuming = false
		local function consume()
			if consuming then return end
			consuming = true

			if isDrink then
				-- Tilt drink towards mouth
				tool.GripForward = Vector3.new(0, -0.759, -0.651)
				tool.GripPos = Vector3.new(1.5, -0.5, 0.3)
				tool.GripRight = Vector3.new(1, 0, 0)
				tool.GripUp = Vector3.new(0, 0.651, -0.759)

				local sound = Instance.new('Sound')
				sound.SoundId = 'http://www.roblox.com/asset/?id=10722059'
				sound.Volume = 1.0
				sound.Parent = handle
				sound:Play()

				RemoteRegistry.fireClient(player, 'ShopResult', true, `*Gulp gulp* Drank {displayName}! Refreshing!`)
				task.wait(1.2)
			else
				-- Bring food up to mouth
				tool.GripForward = Vector3.new(0.439, 0.878, 0.189)
				tool.GripPos = Vector3.new(-0.3, 1.2, -1.3)
				tool.GripRight = Vector3.new(0.0844, 0.169, -0.982)
				tool.GripUp = Vector3.new(0.894, -0.347, 0)

				local sound = Instance.new('Sound')
				sound.SoundId = 'http://www.roblox.com/asset/?id=15047813'
				sound.Volume = 1.0
				sound.Parent = handle
				sound:Play()

				RemoteRegistry.fireClient(player, 'ShopResult', true, `*Nom nom* Ate {displayName}! Delicious!`)
				task.wait(0.9)
			end

			InventoryService.removeItem(player.UserId, itemId, 1)
			local profile = ProfileService.getProfile(player.UserId)
			if profile and profile.progress then
				profile.progress.energy = math.min(100, (profile.progress.energy or 50) + (if isDrink then 15 else 20))
				profile.progress.hunger = math.max(0, (profile.progress.hunger or 0) - (if isDrink then 10 else 30))
			end
			pushInventory(player)
			tool:Destroy()
		end

		tool.Activated:Connect(consume)
		tool:SetAttribute('IsConsumable', true)

		local helper = Instance.new('LocalScript')
		helper.Name = 'ConsumeClick'
		helper.Source = [=[
			local tool = script.Parent
			local remotes = game:GetService("ReplicatedStorage"):WaitForChild("SuwaRemotes", 5)
			local action = remotes and remotes:WaitForChild("InventoryAction", 5)
			tool.Activated:Connect(function()
				if action then
					action:FireServer({ action = "consume" })
				end
			end)
		]=]
		helper.Parent = tool
	end

	tool.Parent = backpack
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass('Humanoid')
	if humanoid then
		humanoid:EquipTool(tool)
	end
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
	-- Check for fishing rod (beginner or pro). If none, provide one!
	local hasRod = (profile.inventory.items.fishing_rod or 0) > 0 or (profile.inventory.items.pro_fishing_rod or 0) > 0
	if not hasRod then
		profile.inventory.items.fishing_rod = 1
	end

	-- Check for bait (worm, shrimp, lure). If none, provide 15 worm baits!
	local hasBait = (profile.inventory.items.worm_bait or 0) > 0 or (profile.inventory.items.shrimp_bait or 0) > 0 or (profile.inventory.items.golden_lure or 0) > 0
	if not hasBait then
		profile.inventory.items.worm_bait = 15
	end

	local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
	if not root or not root:IsA('BasePart') or (root.Position - spot.Position).Magnitude > MAX_SPOT_DISTANCE then
		return
	end

	-- Deduct 1 bait if perishable (golden lure is reusable)
	if (profile.inventory.items.worm_bait or 0) > 0 then
		profile.inventory.items.worm_bait -= 1
		if profile.inventory.items.worm_bait <= 0 then
			profile.inventory.items.worm_bait = nil
		end
	elseif (profile.inventory.items.shrimp_bait or 0) > 0 then
		profile.inventory.items.shrimp_bait -= 1
		if profile.inventory.items.shrimp_bait <= 0 then
			profile.inventory.items.shrimp_bait = nil
		end
	end
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

local function configureFishingSpots()
	for _, spot in workspace:GetDescendants() do
		if spot:IsA('BasePart') and string.find(spot.Name, 'FishingSpot') then
			spot.Transparency = 1
			spot.CanCollide = false
			local old = spot:FindFirstChild('FishingPrompt')
			if old then
				old:Destroy()
			end
			local prompt = Instance.new('ProximityPrompt')
			prompt.Name = 'FishingPrompt'
			prompt.ActionText = 'Cast line'
			prompt.ObjectText = 'Lake Suwa fishing spot'
			prompt.HoldDuration = 0.2
			prompt.MaxActivationDistance = 14
			prompt.RequiresLineOfSight = false
			prompt.Parent = spot
			prompt.Triggered:Connect(function(player)
				beginFishing(player, spot)
			end)
		end
	end
end

local function buildShop(parent: Model, shopId: string, position: Vector3, color: Color3, signText: string)
	position = Vector3.new(position.X, terrainHeight(position.X, position.Z, position.Y - 0.4) + 0.35, position.Z)
	local shop = Instance.new('Model')
	shop.Name = shopId
	shop.Parent = parent
	makePart(
		shop,
		'Foundation',
		Vector3.new(30, 0.7, 18),
		CFrame.new(position),
		Color3.fromRGB(139, 137, 127),
		Enum.Material.Pavement
	)
	makePart(
		shop,
		'BackWall',
		Vector3.new(27, 10, 1),
		CFrame.new(position + Vector3.new(0, 5.3, 7.5)),
		color,
		Enum.Material.WoodPlanks
	)
	makePart(
		shop,
		'Counter',
		Vector3.new(27, 3.5, 3),
		CFrame.new(position + Vector3.new(0, 2, -6.5)),
		Color3.fromRGB(114, 79, 50),
		Enum.Material.WoodPlanks
	)
	for _, x in { -12, 12 } do
		makePart(
			shop,
			'Post',
			Vector3.new(0.8, 10, 0.8),
			CFrame.new(position + Vector3.new(x, 5.3, 0)),
			Color3.fromRGB(78, 62, 46),
			Enum.Material.Wood
		)
	end
	makePart(
		shop,
		'Roof',
		Vector3.new(33, 1, 21),
		CFrame.new(position + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.rad(-4)),
		Color3.fromRGB(66, 71, 66),
		Enum.Material.RoofShingles
	)
	local sign = makePart(
		shop,
		'ShopSign',
		Vector3.new(20, 4, 0.6),
		CFrame.new(position + Vector3.new(0, 8, -7.9)),
		Color3.fromRGB(231, 219, 188),
		Enum.Material.WoodPlanks
	)
	addSign(sign, signText)
	local promptPart = shop:FindFirstChild('Counter') :: BasePart
	local prompt = Instance.new('ProximityPrompt')
	prompt.ActionText = 'Browse shop'
	prompt.ObjectText = FishingData.shops[shopId].name
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
	prompt.Triggered:Connect(function(player)
		activeShops[player] = { id = shopId, expiresAt = os.clock() + 300 }
		local shopData = table.clone(FishingData.shops[shopId])
		shopData.shopId = shopId
		shopData.id = shopId
		shopData.title = shopData.name
		shopData.catalog = shopData.items
		local profile = ProfileService.getProfile(player.UserId)
		shopData.yen = profile and profile.economy.yen or 999999
		RemoteRegistry.fireClient(player, 'OpenShop', shopData)
	end)

	if shopId == 'fishing_supply' then
		for index = -2, 2 do
			makePart(
				shop,
				'DisplayRod',
				Vector3.new(0.16, 6.5, 0.16),
				CFrame.new(position + Vector3.new(index * 3, 5.2, 7)) * CFrame.Angles(0, 0, math.rad(-8)),
				Color3.fromRGB(48, 53, 50),
				Enum.Material.Metal
			).CanCollide =
				false
		end
	elseif shopId == 'ice_cream' then
		for index, scoopColor in
			{ Color3.fromRGB(244, 232, 203), Color3.fromRGB(126, 160, 91), Color3.fromRGB(239, 170, 139) }
		do
			local scoop = makePart(
				shop,
				'IceCreamDisplay',
				Vector3.new(1.4, 1.4, 1.4),
				CFrame.new(position + Vector3.new(-4 + index * 4, 4.4, -8.2)),
				scoopColor,
				Enum.Material.SmoothPlastic
			)
			scoop.Shape = Enum.PartType.Ball
			scoop.CanCollide = false
		end
	else
		for index, lanternColor in
			{ Color3.fromRGB(230, 64, 49), Color3.fromRGB(247, 218, 86), Color3.fromRGB(84, 148, 190) }
		do
			local lantern = makePart(
				shop,
				'FestivalLantern',
				Vector3.new(1.4, 2.1, 1.4),
				CFrame.new(position + Vector3.new(-8 + index * 4, 7.8, -8.2)),
				lanternColor,
				Enum.Material.Neon
			)
			lantern.Shape = Enum.PartType.Ball
			lantern.CanCollide = false
		end
	end
end

local function buildLakesideShops()
	local previous = workspace:FindFirstChild('LakesideShops')
	if previous then
		previous:Destroy()
	end
	local root = Instance.new('Model')
	root.Name = 'LakesideShops'
	root.Parent = workspace
	buildShop(root, 'fishing_supply', Vector3.new(345, 0.4, -73), Color3.fromRGB(77, 111, 103), '釣具店')
	buildShop(root, 'ice_cream', Vector3.new(-145, 0.4, -65), Color3.fromRGB(203, 145, 126), 'アイスクリーム')
	buildShop(root, 'island_festival', Vector3.new(50, 3.4, -610), Color3.fromRGB(164, 73, 57), '島の売店')
end

local function buyItem(player: Player, payload: any)
	local itemId = if typeof(payload) == 'string' then payload elseif typeof(payload) == 'table' and typeof(payload.itemId) == 'string' then payload.itemId else nil
	if not itemId then
		return
	end
	local shopId = if typeof(payload) == 'table' and typeof(payload.shopId) == 'string' then payload.shopId else nil
	local shop = if shopId then FishingData.shops[shopId] else nil
	local selected = nil
	if shop and shop.items then
		for _, item in shop.items do
			if item.id == itemId then
				selected = item
				break
			end
		end
	end
	if not selected then
		for _, s in pairs(FishingData.shops) do
			if s.items then
				for _, item in s.items do
					if item.id == itemId then
						selected = item
						break
					end
				end
			end
			if selected then
				break
			end
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
	local price = selected.price or 0
	if price > 0 and profile.economy.yen < price then
		RemoteRegistry.fireClient(player, 'ShopResult', false, 'Not enough yen.')
		return
	end
	if price > 0 then
		profile.economy.yen -= price
	end
	InventoryService.addItem(player.UserId, selected.id, selected.amount or 1)
	pushInventory(player)
	RemoteRegistry.fireClient(player, 'ShopResult', true, 'Added ' .. selected.name .. ' to Bag!')
end

local function inventoryAction(player: Player, payload: any)
	if typeof(payload) ~= 'table' then
		return
	end
	if payload.action == 'consume' then
		local char = player.Character
		local tool = char and char:FindFirstChildOfClass('Tool')
		if tool and tool:GetAttribute('IsConsumable') then
			tool:Activate()
		end
		return
	end
	if typeof(payload.id) ~= 'string' then
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
		if payload.action == 'sell' then
			local def = FishingData.fish and FishingData.fish[id]
			local price = def and def.price or 150
			profile.inventory.fish[id] -= 1
			if profile.inventory.fish[id] <= 0 then
				profile.inventory.fish[id] = nil
			end
			profile.economy.yen += price
			pushInventory(player)
			RemoteRegistry.fireClient(player, 'ShopResult', true, 'Sold ' .. (def and def.name or id) .. ' for ¥' .. tostring(price) .. '!')
			return
		end
		local definition = FishingData.fish and FishingData.fish[id]
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
	buildLakesideShops()
	configureFishingSpots()

	RemoteRegistry.registerFunction('GetInventory', function(player: Player)
		return snapshot(player)
	end)
	RemoteRegistry.registerFunction('GetShopCatalog', function(_player: Player)
		return FishingData.shops
	end)
	RemoteRegistry.registerEvent('ShopBuy', buyItem)
	RemoteRegistry.registerEvent('InventoryAction', inventoryAction)
	RemoteRegistry.registerEvent('FishCast', function(player: Player, spotName: any?)
		local spot = nil
		if typeof(spotName) == 'string' then
			spot = workspace:FindFirstChild(spotName, true)
		end
		if not spot then
			local root = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
			if root then
				local nearestDist = MAX_SPOT_DISTANCE
				for _, s in workspace:GetDescendants() do
					if s:IsA('BasePart') and string.find(s.Name, 'FishingSpot') then
						local dist = (root.Position - s.Position).Magnitude
						if dist <= nearestDist then
							nearestDist = dist
							spot = s
						end
					end
				end
			end
		end
		if spot then
			beginFishing(player, spot)
		else
			sendState(player, 'FAILED', { message = 'Step closer to a fishing spot on a pier.' })
		end
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
