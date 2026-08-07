--!strict

-- Hatsushima-inspired islet, lake craft and simple fishing interactions.

local RunService = game:GetService('RunService')

local LakeActivityService = {}
local craftSpeeds: { [Model]: number } = {}
local craftHeights: { [Model]: number } = {}
local craftHalfLengths: { [Model]: number } = {}
local WATERLINE_CLEARANCE = 1.15
local DUCK_BOAT_LENGTH = 6.2
local LEISURE_BOAT_LENGTH = 8.5
local ISLAND_CENTER = Vector3.new(0, 0, -610)

local function terrainHeight(x: number, z: number, fallback: number): number
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -180, 0), parameters)
	return if result then result.Position.Y else fallback
end

local function part(
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

local function ball(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = part(parent, name, size, cframe, color, material)
	object.Shape = Enum.PartType.Ball
	return object
end

local function cylinder(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material
): Part
	local object = part(parent, name, size, cframe, color, material)
	object.Shape = Enum.PartType.Cylinder
	return object
end

local function makeTree(parent: Instance, position: Vector3, scale: number)
	local tree = Instance.new('Model')
	tree.Name = 'GroundedBroadleafTree'
	tree:SetAttribute('TerrainGrounded', true)
	tree.Parent = parent
	local groundPosition = Vector3.new(position.X, terrainHeight(position.X, position.Z, position.Y), position.Z)
	local phase = math.rad(math.abs(math.floor(position.X * 3 + position.Z)) % 360)
	cylinder(
		tree,
		'LowerTrunk',
		Vector3.new(7 * scale, 2.4 * scale, 2.4 * scale),
		CFrame.new(groundPosition + Vector3.new(0, 3.35 * scale - 0.15, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color3.fromRGB(83, 57, 39),
		Enum.Material.Wood
	)
	cylinder(
		tree,
		'UpperTrunk',
		Vector3.new(5.5 * scale, 1.75 * scale, 1.75 * scale),
		CFrame.new(groundPosition + Vector3.new(0, 8.2 * scale, 0)) * CFrame.Angles(0, phase, math.rad(86)),
		Color3.fromRGB(91, 64, 42),
		Enum.Material.Wood
	)
	for branchIndex = 1, 4 do
		local angle = phase + (branchIndex / 4) * math.pi * 2
		local startPosition = groundPosition + Vector3.new(0, 8.2 * scale, 0)
		local endPosition = startPosition
			+ Vector3.new(math.cos(angle) * 4.1 * scale, 3.1 * scale, math.sin(angle) * 4.1 * scale)
		local branchVector = endPosition - startPosition
		cylinder(
			tree,
			'Branch',
			Vector3.new(branchVector.Magnitude, 0.75 * scale, 0.75 * scale),
			CFrame.lookAt((startPosition + endPosition) / 2, endPosition) * CFrame.Angles(0, math.pi / 2, 0),
			Color3.fromRGB(91, 64, 42),
			Enum.Material.Wood
		).CanCollide =
			false
	end
	local leafColors = {
		Color3.fromRGB(48, 105, 56),
		Color3.fromRGB(62, 121, 64),
		Color3.fromRGB(76, 133, 69),
	}
	for crownIndex, crownSpec in
		{
			{ Vector3.new(0, 12.2, 0), Vector3.new(10.5, 8.2, 9.8) },
			{ Vector3.new(4.0, 11.6, 0.7), Vector3.new(8.4, 7.1, 8.0) },
			{ Vector3.new(-3.4, 12.0, -1.4), Vector3.new(8.2, 7.4, 8.5) },
			{ Vector3.new(0.8, 14.9, -2.2), Vector3.new(7.8, 6.4, 7.6) },
		}
	do
		local rawOffset = crownSpec[1] :: Vector3
		local rotatedOffset = CFrame.Angles(0, phase, 0):VectorToWorldSpace(rawOffset * scale)
		local foliage = ball(
			tree,
			`LeafCluster{crownIndex}`,
			(crownSpec[2] :: Vector3) * scale,
			CFrame.new(groundPosition + rotatedOffset),
			leafColors[((crownIndex + math.floor(scale * 10)) % #leafColors) + 1],
			Enum.Material.LeafyGrass
		)
		foliage.CanCollide = false
		foliage.CanTouch = false
	end
end

local function buildIslandDetails(root: Model)
	local island = Instance.new('Model')
	island.Name = 'HatsushimaInspiredIsland'
	island:SetAttribute('PreserveAsCentralLakeIsland', true)
	island:SetAttribute('ApproximateDiameterStuds', 180)
	island:SetAttribute('FestivalCapacity', 20)
	island:SetAttribute('Center', ISLAND_CENTER)
	island.Parent = root

	-- Keep the middle open as a festival lawn. Trees frame the beach instead of
	-- occupying the crowd/fireworks circulation zone.
	for _, tree in
		{
			{ Vector3.new(-66, 2, -607), 1.2 },
			{ Vector3.new(-49, 2.5, -570), 1.0 },
			{ Vector3.new(-48, 2.5, -652), 1.15 },
			{ Vector3.new(65, 2, -635), 1.05 },
			{ Vector3.new(50, 2.5, -568), 0.9 },
			{ Vector3.new(15, 2.5, -669), 1.0 },
		}
	do
		makeTree(island, tree[1] :: Vector3, tree[2] :: number)
	end

	local red = Color3.fromRGB(176, 40, 35)
	local toriiGround = terrainHeight(0, -568, 2.6)
	part(
		island,
		'ToriiLeftPost',
		Vector3.new(2, 13, 2),
		CFrame.new(-5, toriiGround + 6.5, -568),
		red,
		Enum.Material.Wood
	)
	part(
		island,
		'ToriiRightPost',
		Vector3.new(2, 13, 2),
		CFrame.new(5, toriiGround + 6.5, -568),
		red,
		Enum.Material.Wood
	)
	part(island, 'ToriiTop', Vector3.new(17, 1.8, 2.4), CFrame.new(0, toriiGround + 13, -568), red, Enum.Material.Wood)
	part(
		island,
		'ToriiBeam',
		Vector3.new(13, 1.2, 1.8),
		CFrame.new(0, toriiGround + 10.5, -568),
		red,
		Enum.Material.Wood
	)
	part(
		island,
		'WaterLevelJetty',
		Vector3.new(8, 1, 22),
		CFrame.new(0, 0.7, -522),
		Color3.fromRGB(112, 83, 55),
		Enum.Material.WoodPlanks
	)
	part(
		island,
		'IslandLandingRamp',
		Vector3.new(8, 1, 30),
		CFrame.new(0, 2.0, -546) * CFrame.Angles(math.rad(-5), 0, 0),
		Color3.fromRGB(112, 83, 55),
		Enum.Material.WoodPlanks
	)

	local shrineCenter = Vector3.new(-52, terrainHeight(-52, -630, 2.6) + 0.4, -630)
	part(
		island,
		'ShrineFoundation',
		Vector3.new(12, 0.8, 10),
		CFrame.new(shrineCenter),
		Color3.fromRGB(126, 121, 108),
		Enum.Material.Slate
	)
	part(
		island,
		'SmallIslandShrine',
		Vector3.new(8, 6.5, 7),
		CFrame.new(shrineCenter + Vector3.new(0, 3.6, 0)),
		Color3.fromRGB(132, 76, 48),
		Enum.Material.WoodPlanks
	)
	part(
		island,
		'ShrineRoof',
		Vector3.new(12, 1.1, 10),
		CFrame.new(shrineCenter + Vector3.new(0, 7.2, 0)),
		Color3.fromRGB(54, 61, 57),
		Enum.Material.RoofShingles
	)
	part(
		island,
		'ShrineDoor',
		Vector3.new(3.6, 5, 0.35),
		CFrame.new(shrineCenter + Vector3.new(0, 3.3, 3.7)),
		Color3.fromRGB(178, 42, 35),
		Enum.Material.Wood
	)

	for index = 1, 7 do
		local stoneZ = -573 - index * 3.2
		part(
			island,
			'StoneApproach',
			Vector3.new(4.5, 0.35, 2.5),
			CFrame.new(0, terrainHeight(0, stoneZ, 2.6) + 0.18, stoneZ),
			Color3.fromRGB(139, 139, 130),
			Enum.Material.Slate
		)
	end

	local deckGround = terrainHeight(12, -657, 2.6)
	local deckY = deckGround + 0.65
	local deckTop = deckY + 0.5
	part(
		island,
		'FireworksSafetyDeck',
		Vector3.new(62, 1, 20),
		CFrame.new(12, deckY, -657),
		Color3.fromRGB(115, 88, 61),
		Enum.Material.WoodPlanks
	)
	local launcherIndex = 0
	for row = 0, 2 do
		for column = 0, 3 do
			launcherIndex += 1
			local launcherX = -12 + column * 16
			local launcherZ = -650 - row * 7
			part(
				island,
				`LauncherCradle{launcherIndex}`,
				Vector3.new(3.2, 0.5, 3.2),
				CFrame.new(launcherX, deckTop + 0.25, launcherZ),
				Color3.fromRGB(47, 49, 52),
				Enum.Material.Metal
			)
			local launcher = cylinder(
				island,
				`FireworkLauncher{launcherIndex}`,
				Vector3.new(3.6, 1.25, 1.25),
				CFrame.new(launcherX, deckTop + 0.5 + 1.8, launcherZ) * CFrame.Angles(0, 0, math.rad(90)),
				Color3.fromRGB(70, 72, 78),
				Enum.Material.Metal
			)
			launcher.CanCollide = false
			launcher:SetAttribute('FireworksLaunchPoint', true)
		end
	end
end

local function makeSeat(model: Model, cframe: CFrame, objectText: string): VehicleSeat
	local oldSeat = model:FindFirstChild('DriveSeat')
	if oldSeat then
		oldSeat:Destroy()
	end
	local seat = Instance.new('VehicleSeat')
	seat.Name = 'DriveSeat'
	seat.Size = Vector3.new(2, 0.6, 2)
	seat.CFrame = cframe
	seat.Color = Color3.fromRGB(72, 78, 82)
	seat.Material = Enum.Material.Leather
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.Parent = model

	local prompt = Instance.new('ProximityPrompt')
	prompt.ActionText = 'Board'
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
		if humanoid then
			seat:Sit(humanoid)
		end
	end)

	return seat
end

local function makePassengerSeat(model: Model, name: string, cframe: CFrame, objectText: string): Seat
	local previous = model:FindFirstChild(name)
	if previous then
		previous:Destroy()
	end
	local seat = Instance.new('Seat')
	seat.Name = name
	seat.Size = Vector3.new(0.9, 0.35, 0.9)
	seat.CFrame = cframe
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanTouch = false
	seat.Parent = model

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'PassengerPrompt'
	prompt.ActionText = 'Ride passenger'
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
		if humanoid and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end)
	return seat
end

local function makeMovementSound(model: Model, parent: BasePart, isDuckBoat: boolean)
	local previous = model:FindFirstChild('WaterMovementSound', true)
	if previous then
		previous:Destroy()
	end
	local sound = Instance.new('Sound')
	sound.Name = 'WaterMovementSound'
	sound.SoundId = 'rbxasset://sounds/action_swim.mp3'
	sound.Looped = true
	sound.Volume = if isDuckBoat then 0.28 else 0.34
	sound.PlaybackSpeed = if isDuckBoat then 0.82 else 0.72
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 8
	sound.RollOffMaxDistance = 75
	sound.Parent = parent
end

local function configureCraft(model: Model)
	local isDuckBoat = string.find(model.Name, 'DuckPedalBoat') ~= nil
	local targetLength = if isDuckBoat then DUCK_BOAT_LENGTH else LEISURE_BOAT_LENGTH
	local oldSeat = model:FindFirstChild('DriveSeat')
	if oldSeat then
		oldSeat:Destroy()
	end
	for _, name in { 'PassengerSeat01', 'PassengerSeat02', 'PassengerSeat03', 'WalkableDeckCollider' } do
		local previous = model:FindFirstChild(name)
		if previous then
			previous:Destroy()
		end
	end

	local _, initialSize = model:GetBoundingBox()
	if math.abs(initialSize.Z - targetLength) > 0.05 then
		model:ScaleTo(model:GetScale() * targetLength / initialSize.Z)
	end

	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local bottom = boundingCFrame.Y - boundingSize.Y / 2
	local lift = WATERLINE_CLEARANCE - bottom
	local oldPivot = model:GetPivot()
	model:PivotTo(CFrame.new(oldPivot.Position + Vector3.new(0, lift, 0)) * oldPivot.Rotation)
	boundingCFrame, boundingSize = model:GetBoundingBox()
	craftHeights[model] = model:GetPivot().Y

	local floor = model:FindFirstChild('WaterproofCockpitFloor')
	if not floor or not floor:IsA('Part') then
		floor = part(
			model,
			'WaterproofCockpitFloor',
			Vector3.new(1, 0.25, 1),
			CFrame.identity,
			Color3.new(1, 1, 1),
			Enum.Material.SmoothPlastic
		)
	end
	floor.Size = if isDuckBoat then Vector3.new(2.1, 0.25, 3) else Vector3.new(2.8, 0.25, 4.8)
	floor.Color = if isDuckBoat then Color3.fromRGB(235, 221, 181) else Color3.fromRGB(222, 234, 239)
	floor.CanCollide = true
	floor.CanTouch = true
	floor.CanQuery = true
	floor.Transparency = 0.08
	local floorOffset = if isDuckBoat then 0.55 else -0.4
	floor.CFrame = CFrame.new(boundingCFrame.X, WATERLINE_CLEARANCE + 0.55, boundingCFrame.Z + floorOffset)
		* oldPivot.Rotation

	local base = CFrame.new(boundingCFrame.Position) * oldPivot.Rotation
	local deck = part(
		model,
		'WalkableDeckCollider',
		if isDuckBoat then Vector3.new(2.9, 0.35, 5.1) else Vector3.new(3.8, 0.35, 7.1),
		base * CFrame.new(0, WATERLINE_CLEARANCE + 0.68 - boundingCFrame.Y, 0),
		Color3.fromRGB(230, 230, 220),
		Enum.Material.SmoothPlastic
	)
	deck.Transparency = 1
	deck.CanCollide = true
	deck.CanTouch = true
	deck.CanQuery = true

	local driverSeat = makeSeat(
		model,
		base * CFrame.new(0, WATERLINE_CLEARANCE + 1.45 - boundingCFrame.Y, if isDuckBoat then -0.9 else -1.55),
		if isDuckBoat then 'Duck pedal boat' else 'Lake boat'
	)
	if isDuckBoat then
		makePassengerSeat(
			model,
			'PassengerSeat01',
			base * CFrame.new(-0.72, WATERLINE_CLEARANCE + 1.38 - boundingCFrame.Y, 0.9),
			'Duck boat passenger'
		)
		makePassengerSeat(
			model,
			'PassengerSeat02',
			base * CFrame.new(0.72, WATERLINE_CLEARANCE + 1.38 - boundingCFrame.Y, 0.9),
			'Duck boat passenger'
		)
	else
		for index, offset in
			{
				Vector3.new(-1, WATERLINE_CLEARANCE + 1.5 - boundingCFrame.Y, 0.2),
				Vector3.new(1, WATERLINE_CLEARANCE + 1.5 - boundingCFrame.Y, 0.2),
				Vector3.new(0, WATERLINE_CLEARANCE + 1.5 - boundingCFrame.Y, 1.85),
			}
		do
			makePassengerSeat(model, `PassengerSeat0{index}`, base * CFrame.new(offset), 'Lake boat passenger')
		end
	end
	makeMovementSound(model, driverSeat, isDuckBoat)
	model:SetAttribute('WalkableSolidDeck', true)
	model:SetAttribute('PassengerCapacity', if isDuckBoat then 2 else 3)
	model:SetAttribute('TargetLengthStuds', targetLength)
	model:SetAttribute('ScaleBasis', '5.5-stud avatar')
	craftSpeeds[model] = 0
	craftHalfLengths[model] = targetLength * 0.58
end

local function terrainIsLand(position: Vector3): boolean
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Include
	parameters.FilterDescendantsInstances = { workspace.Terrain }
	parameters.IgnoreWater = true
	local result = workspace:Raycast(position + Vector3.new(0, 18, 0), Vector3.new(0, -45, 0), parameters)
	return result ~= nil and result.Position.Y > 0.15
end

local function craftWouldHitLand(model: Model, nextPivot: CFrame): boolean
	local halfLength = craftHalfLengths[model] or 4
	local forward = nextPivot.LookVector
	local right = nextPivot.RightVector
	for _, offset in
		{
			Vector3.zero,
			forward * halfLength,
			forward * halfLength * 0.75 + right * halfLength * 0.42,
			forward * halfLength * 0.75 - right * halfLength * 0.42,
			-forward * halfLength * 0.72,
		}
	do
		if terrainIsLand(nextPivot.Position + offset) then
			return true
		end
	end
	return false
end

local function updateCraft(model: Model, deltaTime: number)
	local seat = model:FindFirstChild('DriveSeat')
	if not seat or not seat:IsA('VehicleSeat') then
		return
	end
	local speed = craftSpeeds[model] or 0
	local throttle = if seat.Occupant then seat.ThrottleFloat else 0
	local steer = if seat.Occupant then seat.SteerFloat else 0
	if math.abs(throttle) > 0.05 then
		speed = math.clamp(speed + throttle * 12 * deltaTime, -4, 16)
	else
		speed *= math.max(0, 1 - 2.8 * deltaTime)
	end
	if seat.Occupant then
		local pivot = model:GetPivot() * CFrame.Angles(0, -steer * math.rad(48) * deltaTime, 0)
		local move = pivot.LookVector * speed * deltaTime
		local floatHeight = craftHeights[model] or pivot.Y
		local nextPivot = CFrame.new(pivot.X + move.X, floatHeight, pivot.Z + move.Z) * pivot.Rotation
		if craftWouldHitLand(model, nextPivot) then
			speed = -speed * 0.12
		else
			model:PivotTo(nextPivot)
		end
	end
	local movementSound = model:FindFirstChild('WaterMovementSound', true)
	if movementSound and movementSound:IsA('Sound') then
		movementSound.PlaybackSpeed = 0.72 + math.clamp(math.abs(speed) / 16, 0, 1) * 0.42
		if math.abs(speed) > 0.35 and seat.Occupant then
			if not movementSound.IsPlaying then
				movementSound:Play()
			end
		elseif movementSound.IsPlaying then
			movementSound:Stop()
		end
	end
	craftSpeeds[model] = speed
end

local function buildLakeFeatures()
	local previous = workspace:FindFirstChild('LakeActivitySet')
	if previous then
		previous:Destroy()
	end
	local root = Instance.new('Model')
	root.Name = 'LakeActivitySet'
	root.Parent = workspace
	buildIslandDetails(root)

	local crafts = workspace:FindFirstChild('LakeCrafts')
	if crafts then
		for _, child in crafts:GetChildren() do
			if child:IsA('Model') then
				configureCraft(child)
			end
		end
	end

	local oldBarge = workspace:FindFirstChild('LakesideActivities')
		and workspace.LakesideActivities:FindFirstChild('FireworksLaunchBarge')
	if oldBarge then
		oldBarge:Destroy()
	end
end

function LakeActivityService.init()
	buildLakeFeatures()
	RunService.Heartbeat:Connect(function(deltaTime)
		for model in craftSpeeds do
			if model.Parent then
				updateCraft(model, deltaTime)
			else
				craftSpeeds[model] = nil
				craftHeights[model] = nil
				craftHalfLengths[model] = nil
			end
		end
	end)
end

return LakeActivityService
