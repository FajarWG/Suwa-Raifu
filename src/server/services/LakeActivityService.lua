--!strict

-- Hatsushima-inspired islet, lake craft, active water propulsion, world boundary & anti-ghost ride.

local RunService = game:GetService('RunService')

local LakeActivityService = {}
local activeBoats: { [Model]: { seat: VehicleSeat, engineSound: Sound?, waterSound: Sound?, rootPart: BasePart, baseSpeed: number, turnSpeed: number, waterlineY: number } } = {}
local ISLAND_CENTER = Vector3.new(0, 0, -610)

local ENGINE_SOUND_ID = 'rbxassetid://1843521450'
local WATER_SPLASH_ID = 'rbxasset://sounds/action_swim.mp3'

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

-- Comprehensive Water/Land boundary check for boats
local function isPositionNonWater(pos: Vector3): boolean
	if pos.X < -730 or pos.X > 730 or pos.Z > -215 or pos.Z < -1350 then
		return true
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	params.IgnoreWater = false

	local hit = workspace:Raycast(pos + Vector3.new(0, 10, 0), Vector3.new(0, -25, 0), params)
	if hit and hit.Material ~= Enum.Material.Water then
		return true
	end

	if hit and hit.Position.Y > -0.2 and hit.Material ~= Enum.Material.Water then
		return true
	end

	return false
end

local function isBoatTouchingLandOrEdge(seat: VehicleSeat, model: Model): boolean
	local forward = seat.CFrame.LookVector
	local right = seat.CFrame.RightVector
	local cf, size = model:GetBoundingBox()
	local halfLength = size.Z / 2
	local halfWidth = size.X / 2

	local testPoints = {
		seat.Position,
		seat.Position + forward * (halfLength + 5),
		seat.Position + forward * halfLength + right * halfWidth,
		seat.Position + forward * halfLength - right * halfWidth,
		seat.Position - forward * (halfLength + 4),
	}

	for _, pt in ipairs(testPoints) do
		if isPositionNonWater(pt) then
			return true
		end
	end

	return false
end

local function configureCreatorStoreBoat(model: Model)
	local boatName = string.lower(model.Name)
	local isMotorized = string.find(boatName, "fune") ~= nil
		or string.find(boatName, "pontoon") ~= nil
		or string.find(boatName, "speedboat") ~= nil

	local driveSeat: VehicleSeat? = model:FindFirstChildWhichIsA("VehicleSeat", true)
	if not driveSeat then
		return
	end

	model.PrimaryPart = driveSeat
	driveSeat.RootPriority = 127

	local baseSpeed = driveSeat:GetAttribute("BaseSpeed") or (if string.find(boatName, "speed") then 36 else 26)
	local turnSpeed = driveSeat:GetAttribute("TurnSpeed") or (if string.find(boatName, "speed") then 1.8 else 1.3)
	local waterlineY = driveSeat:GetAttribute("WaterlineY") or driveSeat.Position.Y

	local physProps = PhysicalProperties.new(0.01, 0, 0, 0, 0)

	-- Ensure ALL cosmetic parts are unanchored, massless, and frictionless
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = true
			p.CanTouch = true
			if p ~= driveSeat then
				p.Massless = true
			end
			p.CustomPhysicalProperties = physProps
		end
	end

	-- Drive seat anchored initially until driven
	driveSeat.Anchored = true
	driveSeat.HeadsUpDisplay = false
	driveSeat.CanTouch = false

	for _, seat in ipairs(model:GetDescendants()) do
		local existingPrompt = seat:FindFirstChild("RidePrompt")
		if existingPrompt then
			existingPrompt:Destroy()
		end

		if not seat:IsA("Seat") and not seat:IsA("VehicleSeat") then
			continue
		end

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "RidePrompt"
		if seat:IsA("VehicleSeat") then
			prompt.ActionText = "Mengemudi"
			prompt.ObjectText = model.Name .. " (Kemudi)"
		else
			prompt.ActionText = "Menumpang"
			prompt.ObjectText = model.Name .. " (Kursi Penumpang)"
		end
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.MaxActivationDistance = 15
		prompt.RequiresLineOfSight = false
		prompt.Parent = seat

		-- Hide prompt when occupied
		prompt.Enabled = (seat.Occupant == nil)

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local isOccupied = (seat.Occupant ~= nil)
			prompt.Enabled = not isOccupied

			if seat == driveSeat then
				if isOccupied then
					driveSeat.Anchored = false
					local occupant = driveSeat.Occupant
					if occupant and occupant.Parent then
						local ownerPlayer = game:GetService("Players"):GetPlayerFromCharacter(occupant.Parent)
						if ownerPlayer then
							pcall(function() driveSeat:SetNetworkOwner(ownerPlayer) end)
						end
					end
				else
					-- Driver exited -> Anti-Ghost Ride: Zero velocity and re-anchor in place
					driveSeat.AssemblyLinearVelocity = Vector3.zero
					driveSeat.AssemblyAngularVelocity = Vector3.zero
					driveSeat.Throttle = 0
					driveSeat.Steer = 0
					driveSeat.ThrottleFloat = 0
					driveSeat.SteerFloat = 0
					driveSeat.Anchored = true
					pcall(function() driveSeat:SetNetworkOwnershipAuto() end)
				end
			end
		end)

		prompt.Triggered:Connect(function(player)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.SeatPart == nil and not seat.Occupant then
				seat:Sit(humanoid)
			end
		end)
	end

	local previousWater = model:FindFirstChild("WaterMovementSound", true)
	if previousWater then
		previousWater:Destroy()
	end
	local previousEngine = model:FindFirstChild("EngineMovementSound", true)
	if previousEngine then
		previousEngine:Destroy()
	end

	local waterSound = Instance.new("Sound")
	waterSound.Name = "WaterMovementSound"
	waterSound.SoundId = WATER_SPLASH_ID
	waterSound.Looped = true
	waterSound.Volume = 0
	waterSound.PlaybackSpeed = 0.85
	waterSound.RollOffMode = Enum.RollOffMode.InverseTapered
	waterSound.RollOffMinDistance = 10
	waterSound.RollOffMaxDistance = 90
	waterSound.Parent = driveSeat
	waterSound:Play()

	local engineSound: Sound? = nil
	if isMotorized then
		engineSound = Instance.new("Sound")
		engineSound.Name = "EngineMovementSound"
		engineSound.SoundId = ENGINE_SOUND_ID
		engineSound.Looped = true
		engineSound.Volume = 0
		engineSound.PlaybackSpeed = 0.8
		engineSound.RollOffMode = Enum.RollOffMode.InverseTapered
		engineSound.RollOffMinDistance = 15
		engineSound.RollOffMaxDistance = 120
		engineSound.Parent = driveSeat
		engineSound:Play()
	end

	activeBoats[model] = { seat = driveSeat, engineSound = engineSound, waterSound = waterSound, rootPart = driveSeat, baseSpeed = baseSpeed, turnSpeed = turnSpeed, waterlineY = waterlineY }
end

local function buildLakeFeatures()
	local previous = workspace:FindFirstChild("LakeActivitySet")
	if previous then
		previous:Destroy()
	end
	local root = Instance.new("Model")
	root.Name = "LakeActivitySet"
	root.Parent = workspace
	buildIslandDetails(root)

	local crafts = workspace:FindFirstChild("LakeCrafts")
	if crafts then
		for _, child in ipairs(crafts:GetChildren()) do
			if child:IsA("Model") then
				configureCreatorStoreBoat(child)
			end
		end
	end
end

function LakeActivityService.init()
	buildLakeFeatures()

	-- Runtime loop for active water propulsion, strict land blocking, audio, and anti-ghost ride
	RunService.Heartbeat:Connect(function()
		for boat, data in pairs(activeBoats) do
			local seat = data.seat
			local engineSound = data.engineSound
			local waterSound = data.waterSound

			if not seat or not seat.Parent then
				activeBoats[boat] = nil
				continue
			end

			-- Strict Anti-Ghost Ride: when empty, enforce 0 velocity
			if seat.Occupant == nil then
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
				seat.Throttle = 0
				seat.Steer = 0
				seat.ThrottleFloat = 0
				seat.SteerFloat = 0
				if waterSound then waterSound.Volume = 0 end
				if engineSound then engineSound.Volume = 0 end
				continue
			end

			-- Driver is in seat: server only handles audio and boundary.
			-- Movement is driven entirely by BoatDriveController on the client
			-- (client has network ownership of all boat parts).
			local speed = seat.AssemblyLinearVelocity.Magnitude

			-- Dynamic Audio
			if speed > 1 then
				if waterSound then
					waterSound.Volume = math.clamp(speed / 25, 0.2, 0.6)
					waterSound.PlaybackSpeed = math.clamp(0.7 + (speed / 40), 0.7, 1.2)
				end
				if engineSound then
					engineSound.Volume = math.clamp(0.3 + (speed / 15) * 0.5, 0.3, 0.85)
					engineSound.PlaybackSpeed = math.clamp(0.75 + (speed / 30) * 0.5, 0.75, 1.35)
				end
			else
				if waterSound then waterSound.Volume = 0 end
				if engineSound then
					engineSound.Volume = 0.2
					engineSound.PlaybackSpeed = 0.75
				end
			end
		end
	end)
end

return LakeActivityService
