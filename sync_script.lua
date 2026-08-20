
local sss = game:GetService("ServerScriptService")
local serverScript = sss:FindFirstChild("LakeActivityService", true)
if serverScript then serverScript.Source = [==[--!strict

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

local PhysicsService = game:GetService("PhysicsService")

pcall(function()
	PhysicsService:RegisterCollisionGroup("BoatDecks")
	PhysicsService:RegisterCollisionGroup("SeatedAvatars")
	PhysicsService:CollisionGroupSetCollidable("BoatDecks", "Default", true)
	PhysicsService:CollisionGroupSetCollidable("BoatDecks", "SeatedAvatars", false)
end)

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
	driveSeat.Massless = false
	driveSeat.CanCollide = false
	driveSeat.CanTouch = false
	driveSeat.MaxSpeed = 0
	driveSeat.Torque = 0
	driveSeat.HeadsUpDisplay = false

	-- Remove legacy constraint objects if any
	local existingLeveler = driveSeat:FindFirstChild("BoatLeveler")
	if existingLeveler then
		existingLeveler:Destroy()
	end
	local existingAtt = driveSeat:FindFirstChild("LevelAttachment")
	if existingAtt then
		existingAtt:Destroy()
	end

	local baseSpeed = driveSeat:GetAttribute("BaseSpeed")
	if not baseSpeed then
		if string.find(boatName, "speed") then
			baseSpeed = 42
		elseif string.find(boatName, "fune") then
			baseSpeed = 30
		else
			baseSpeed = 24
		end
		driveSeat:SetAttribute("BaseSpeed", baseSpeed)
	end

	local turnSpeed = driveSeat:GetAttribute("TurnSpeed")
	if not turnSpeed then
		if string.find(boatName, "speed") then
			turnSpeed = 1.8
		elseif string.find(boatName, "fune") then
			turnSpeed = 1.3
		else
			turnSpeed = 1.4
		end
		driveSeat:SetAttribute("TurnSpeed", turnSpeed)
	end

	local defaultWaterline = if string.find(boatName, "speed") then 2.52 elseif string.find(boatName, "fune") then 4.42 else 0.62
	local waterlineY = driveSeat:GetAttribute("WaterlineY") or defaultWaterline
	driveSeat:SetAttribute("WaterlineY", waterlineY)

	-- Setup BodyPosition for strict Y waterline holding
	local bp = driveSeat:FindFirstChild("BoatPosition") :: BodyPosition?
	if not bp then
		bp = Instance.new("BodyPosition")
		bp.Name = "BoatPosition"
		bp.Parent = driveSeat
	end
	bp.MaxForce = Vector3.new(0, 1e7, 0)
	bp.P = 15000
	bp.D = 1000
	bp.Position = Vector3.new(0, waterlineY, 0)

	-- Setup BodyGyro for level pitch/roll and smooth yaw turning
	local bg = driveSeat:FindFirstChild("BoatGyro") :: BodyGyro?
	if not bg then
		bg = Instance.new("BodyGyro")
		bg.Name = "BoatGyro"
		bg.Parent = driveSeat
	end
	bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
	bg.P = 12000
	bg.D = 800
	local _, initYaw, _ = driveSeat.CFrame:ToOrientation()
	bg.CFrame = CFrame.Angles(0, initYaw, 0)

	-- Sanitize all subparts: Massless = true for stable center of mass.
	-- Make deck, hull, pontoons, railings, and walls solid (CanCollide = true, BoatDecks group) so boat is a solid physical object.
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local pName = string.lower(p.Name)
			local isSeat = p:IsA("Seat") or p:IsA("VehicleSeat") or string.find(pName, "seat") ~= nil
			local isEffect = string.find(pName, "emmiter") ~= nil 
				or string.find(pName, "effect") ~= nil 
				or string.find(pName, "teleport") ~= nil 
				or string.find(pName, "logo") ~= nil

			if p ~= driveSeat then
				p.Anchored = false
				p.Massless = true
			end

			if isSeat or isEffect then
				p.CanCollide = false
				p.CanTouch = false
			else
				p.CanCollide = true
				p.CanTouch = true
				pcall(function()
					p.CollisionGroup = "BoatDecks"
				end)
			end
		end
	end

	-- Ensure all subparts are rigidly welded to driveSeat
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= driveSeat then
			local hasWeld = false
			for _, w in ipairs(model:GetDescendants()) do
				if w:IsA("WeldConstraint") and ((w.Part0 == p and w.Part1 == driveSeat) or (w.Part0 == driveSeat and w.Part1 == p)) then
					hasWeld = true
					break
				end
			end
			if not hasWeld then
				local wc = Instance.new("WeldConstraint")
				wc.Part0 = driveSeat
				wc.Part1 = p
				wc.Parent = driveSeat
			end
		end
	end

	-- Drive seat anchored initially while parked
	driveSeat.Anchored = true

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

		local lastOccupantChar: Model? = nil

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local occupant = seat.Occupant
			local isOccupied = (occupant ~= nil)
			prompt.Enabled = not isOccupied

			if isOccupied and occupant and occupant.Parent then
				lastOccupantChar = occupant.Parent :: Model
				for _, charPart in ipairs(lastOccupantChar:GetDescendants()) do
					if charPart:IsA("BasePart") then
						pcall(function()
							charPart.CollisionGroup = "SeatedAvatars"
							charPart.CanCollide = false
						end)
					end
				end
			elseif not isOccupied and lastOccupantChar then
				for _, charPart in ipairs(lastOccupantChar:GetDescendants()) do
					if charPart:IsA("BasePart") then
						pcall(function()
							charPart.CollisionGroup = "Default"
							charPart.CanCollide = true
						end)
					end
				end
				lastOccupantChar = nil
			end

			if seat == driveSeat then
				if isOccupied then
					local occ = driveSeat.Occupant
					if occ and occ.Parent then
						local ownerPlayer = game:GetService("Players"):GetPlayerFromCharacter(occ.Parent)
						if ownerPlayer then
							pcall(function() driveSeat:SetNetworkOwner(ownerPlayer) end)
						end
					end
					local _, y, _ = driveSeat.CFrame:ToOrientation()
					bg.CFrame = CFrame.Angles(0, y, 0)
					bp.Position = Vector3.new(0, waterlineY, 0)

					-- Anti-Fling: Wait 0.15 seconds before unanchoring.
					-- This allows the SeatWeld to be created and the physics solver to resolve any
					-- overlap between the character and the boat hull *while the boat is safely anchored*.
					task.delay(0.15, function()
						if driveSeat.Occupant ~= nil then
							driveSeat.Anchored = false
						end
					end)
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
					local _, curYaw, _ = driveSeat.CFrame:ToOrientation()
					driveSeat.CFrame = CFrame.new(driveSeat.Position.X, waterlineY, driveSeat.Position.Z) * CFrame.Angles(0, curYaw, 0)
					bg.CFrame = CFrame.Angles(0, curYaw, 0)
					bp.Position = Vector3.new(0, waterlineY, 0)
				end
			end
		end)

		prompt.Triggered:Connect(function(player)
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.SeatPart == nil and not seat.Occupant then
				-- Preemptively switch collision group before SeatWeld is created to prevent fling
				for _, charPart in ipairs(character:GetDescendants()) do
					if charPart:IsA("BasePart") then
						pcall(function()
							charPart.CollisionGroup = "SeatedAvatars"
						end)
					end
				end
				
				-- Tiny delay to let collision group replicate, then sit
				task.wait(0.05)
				if humanoid.SeatPart == nil and not seat.Occupant then
					seat:Sit(humanoid)
				end
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

			-- Strict Anti-Ghost Ride: when empty, enforce 0 velocity & anchored
			if seat.Occupant == nil then
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
				seat.Throttle = 0
				seat.Steer = 0
				seat.ThrottleFloat = 0
				seat.SteerFloat = 0
				if not seat.Anchored then
					seat.Anchored = true
				end
				if waterSound then waterSound.Volume = 0 end
				if engineSound then engineSound.Volume = 0 end
				continue
			end

			-- Driver is in seat: server handles audio and boundary watchdog
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
]==] end

local rps = game:GetService("ReplicatedStorage")
local clientScript = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("BoatDriveController", true)
if clientScript then clientScript.Source = [==[--!strict

-- BoatDriveController: Pure, smooth, responsive boat controller.
-- Uses physical BodyGyro and BodyPosition to lock height and orientation without physics explosions.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PhysicsService = game:GetService("PhysicsService")

pcall(function()
	PhysicsService:RegisterCollisionGroup("BoatDecks")
	PhysicsService:RegisterCollisionGroup("SeatedAvatars")
	PhysicsService:CollisionGroupSetCollidable("BoatDecks", "Default", true)
	PhysicsService:CollisionGroupSetCollidable("BoatDecks", "SeatedAvatars", false)
end)

local BoatDriveController = {}
local player = Players.LocalPlayer

local currentSeat: VehicleSeat? = nil
local currentWaterlineY: number = 1.0
local currentBaseSpeed: number = 30
local currentTurnSpeed: number = 1.5
local currentYaw: number = 0

local currentGyro: BodyGyro? = nil
local currentPos: BodyPosition? = nil

local function getOrCreateMovers(seat: VehicleSeat): (BodyGyro, BodyPosition)
	local bg = seat:FindFirstChild("BoatGyro") :: BodyGyro?
	if not bg then
		bg = Instance.new("BodyGyro")
		bg.Name = "BoatGyro"
		bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
		bg.P = 12000
		bg.D = 800
		local _, y, _ = seat.CFrame:ToOrientation()
		bg.CFrame = CFrame.Angles(0, y, 0)
		bg.Parent = seat
	end

	local bp = seat:FindFirstChild("BoatPosition") :: BodyPosition?
	if not bp then
		bp = Instance.new("BodyPosition")
		bp.Name = "BoatPosition"
		bp.MaxForce = Vector3.new(0, 1e7, 0)
		bp.P = 15000
		bp.D = 1000
		bp.Position = Vector3.new(0, currentWaterlineY, 0)
		bp.Parent = seat
	end

	return bg, bp
end

local function onSeated(active: boolean, currentSeatPart: Instance?)
	local char = player.Character
	if active and currentSeatPart then
		local lakeCrafts = workspace:FindFirstChild("LakeCrafts")
		if lakeCrafts and currentSeatPart:IsDescendantOf(lakeCrafts) then
			-- Assign seated avatar to SeatedAvatars collision group so seated avatar doesn't clip with the boat
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then
						pcall(function()
							p.CollisionGroup = "SeatedAvatars"
						end)
					end
				end
			end

			if currentSeatPart:IsA("VehicleSeat") then
				currentSeat = currentSeatPart
				currentBaseSpeed = currentSeat:GetAttribute("BaseSpeed") or 30
				currentTurnSpeed = currentSeat:GetAttribute("TurnSpeed") or 1.5
				currentWaterlineY = currentSeat:GetAttribute("WaterlineY") or currentSeat.Position.Y
				
				local _, yaw, _ = currentSeat.CFrame:ToOrientation()
				currentYaw = yaw

				currentGyro, currentPos = getOrCreateMovers(currentSeat)
				if currentGyro then
					currentGyro.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
					currentGyro.CFrame = CFrame.Angles(0, currentYaw, 0)
				end
				if currentPos then
					currentPos.MaxForce = Vector3.new(0, 1e7, 0)
					currentPos.Position = Vector3.new(0, currentWaterlineY, 0)
				end
				return
			end
		end
	else
		-- Restore avatar collisions to Default when standing up
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					pcall(function()
						p.CollisionGroup = "Default"
						p.CanCollide = true
					end)
				end
			end
		end
	end
	currentSeat = nil
	currentGyro = nil
	currentPos = nil
end

local function setupCharacter(char: Model)
	local humanoid = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid.Seated:Connect(onSeated)
		if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
			onSeated(true, humanoid.SeatPart)
		end
	end
end

function BoatDriveController.init()
	if player.Character then
		setupCharacter(player.Character)
	end
	player.CharacterAdded:Connect(setupCharacter)

	RunService.RenderStepped:Connect(function(dt: number)
		if not currentSeat or not currentSeat.Parent then
			return
		end

		local throttle = currentSeat.ThrottleFloat
		local steer = currentSeat.SteerFloat

		-- Direct keyboard WASD & Arrow fallback
		if math.abs(throttle) < 0.05 and math.abs(steer) < 0.05 then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
				throttle = 1
			elseif UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
				throttle = -1
			end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
				steer = -1
			elseif UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
				steer = 1
			end
		end

		-- Read current yaw and integrate steering input over delta time
		if math.abs(steer) > 0.05 then
			currentYaw = currentYaw + (-steer * currentTurnSpeed * dt)
		end

		-- Apply target orientation and height via physical movers
		if currentGyro then
			currentGyro.CFrame = CFrame.Angles(0, currentYaw, 0)
		end
		if currentPos then
			currentPos.Position = Vector3.new(0, currentWaterlineY, 0)
		end

		-- Horizontal propulsion direction derived from smooth currentYaw
		local flatLook = Vector3.new(-math.sin(currentYaw), 0, -math.cos(currentYaw))
		local targetVelocity: Vector3

		if math.abs(throttle) > 0.05 then
			local forwardSpeed = throttle * currentBaseSpeed
			targetVelocity = flatLook * forwardSpeed
		else
			-- Smooth coasting in water with fluid drag
			local vel = currentSeat.AssemblyLinearVelocity
			targetVelocity = Vector3.new(vel.X * 0.94, 0, vel.Z * 0.94)
		end

		-- Set strictly horizontal linear & angular velocity (Y = 0)
		currentSeat.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, 0, targetVelocity.Z)
		currentSeat.AssemblyAngularVelocity = Vector3.new(0, -steer * currentTurnSpeed, 0)
	end)
end

return BoatDriveController
]==] end
return "Synced both scripts!"
