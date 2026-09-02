--!strict

-- Makes anything ridable actually ridable, and puts every seat behind an E
-- prompt so nobody is snapped into a seat just by brushing against it.
--
-- A vehicle is any Model that is either tagged with the attribute `Vehicle`, or
-- sits inside a folder named LakeCrafts anywhere in the Workspace. Bicycles are
-- not handled here: BicycleService rigs and drives those, and two systems
-- fighting over one seat is exactly what used to make them unridable.
-- Creator Store props ship fully anchored, so they are welded into one
-- assembly and unanchored here; otherwise they cannot move at all.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))

local VehicleInteractionService = {}

local VEHICLE_FOLDERS = { LakeCrafts = true }

local activeDrives: { [BasePart]: RBXScriptConnection } = {}
-- An abandoned boat/car is re-anchored after a grace period so it settles
-- instead of drifting off unattended; keyed by the driver seat so a new
-- rider cancels it and frees the vehicle again.
local anchorTasks: { [VehicleSeat]: thread } = {}
-- Client input arrives over remotes: attributes set on the client never
-- replicate up to the server, so they cannot carry driver input.
local boosting: { [Player]: boolean } = {}
local hopRequested: { [Player]: boolean } = {}

-- A wheel is a disc: its thinnest dimension is the axle it spins around.
local function axleAxis(part: BasePart): Vector3
	local size = part.Size
	if size.X <= size.Y and size.X <= size.Z then
		return Vector3.xAxis
	elseif size.Y <= size.X and size.Y <= size.Z then
		return Vector3.yAxis
	end
	return Vector3.zAxis
end

local function looksLikeWheel(part: BasePart): boolean
	local name = part.Name:lower()
	if name:find('wheel') or name:find('tire') or name:find('tyre') then
		return true
	end
	-- A rim is sometimes left unnamed with only a CylinderMesh on it, but so
	-- are frame tubes and bottle holders. Require an actual disc: two matching
	-- faces and a much thinner axle.
	if not part:FindFirstChildWhichIsA('CylinderMesh') then
		return false
	end
	local size = part.Size
	local dims = { size.X, size.Y, size.Z }
	table.sort(dims)
	return dims[1] < dims[2] * 0.5 and dims[3] < dims[2] * 1.35
end

local function isInsideVehicleFolder(instance: Instance): boolean
	local node = instance.Parent
	while node and node ~= workspace do
		if node:IsA('Folder') and VEHICLE_FOLDERS[node.Name] then
			return true
		end
		node = node.Parent
	end
	return false
end

--=============================================================================
-- Seat prompts
--=============================================================================

local function isActualVehicleSeat(seat: Seat | VehicleSeat): boolean
	local nameLower = seat.Name:lower()
	if nameLower:find('swing') or nameLower:find('ayun') then
		return false
	end
	if
		nameLower:find('bench')
		or nameLower:find('chair')
		or nameLower:find('armseat')
		or nameLower:find('stool')
		or nameLower:find('toilet')
		or nameLower:find('ferris')
		or nameLower:find('basket')
		or nameLower:find('merry')
		or nameLower:find('carousel')
		or nameLower:find('happy')
	then
		return false
	end

	local owner = seat:FindFirstAncestorWhichIsA('Model')
	if not owner then
		return seat:IsA('VehicleSeat')
	end

	local ownerLower = owner.Name:lower()
	if
		ownerLower:find('swing')
		or ownerLower:find('ayun')
		or ownerLower:find('bench')
		or ownerLower:find('chair')
		or ownerLower:find('arena')
		or ownerLower:find('table')
		or ownerLower:find('ferris')
		or ownerLower:find('merry')
	then
		return false
	end

	if
		owner:GetAttribute('Vehicle')
		or owner:GetAttribute('SuwaRigged')
		or owner:GetAttribute('SuwaBicycle')
		or isInsideVehicleFolder(owner)
		or owner:FindFirstAncestor('LakeCrafts')
		or owner:FindFirstAncestor('Vehicles')
	then
		-- Only the seat that actually steers the vehicle is a "Ride"; the rest
		-- of a boat's Seat instances are just passenger benches ("Sit").
		return seat:IsA('VehicleSeat')
	end

	if
		ownerLower:find('boat')
		or ownerLower:find('bike')
		or ownerLower:find('bicycle')
		or ownerLower:find('fune')
		or ownerLower:find('ship')
		or ownerLower:find('car')
		or ownerLower:find('craft')
		or ownerLower:find('kayak')
		or ownerLower:find('canoe')
		or ownerLower:find('swan')
		or ownerLower:find('duck')
		or ownerLower:find('jetski')
	then
		return seat:IsA('VehicleSeat')
	end

	return seat:IsA('VehicleSeat')
end

local function getSeatActionAndObject(seat: Seat | VehicleSeat, rawObjectText: string): (string, string)
	local nameLower = seat.Name:lower()
	local owner = seat:FindFirstAncestorWhichIsA('Model')
	local ownerLower = if owner then owner.Name:lower() else ''

	if nameLower:find('swing') or ownerLower:find('swing') or nameLower:find('ayun') or ownerLower:find('ayun') then
		return 'Swing', 'Swings'
	end

	if isActualVehicleSeat(seat) then
		local cleanName = if owner then owner.Name else 'Vehicle'
		local cleanLower = cleanName:lower()
		if cleanLower:find('fune') or cleanLower:find('boat') then
			cleanName = 'Boat'
		elseif cleanLower:find('bike') or cleanLower:find('bicycle') then
			cleanName = 'Bicycle'
		elseif cleanLower:find('swan') then
			cleanName = 'Swan Boat'
		elseif cleanLower:find('jetski') then
			cleanName = 'Jet Ski'
		end
		return 'Ride', cleanName
	end

	-- Default furniture / seating
	local cleanObj = if owner then owner.Name else 'Seat'
	local objLower = cleanObj:lower()
	if objLower:find('bench') then
		cleanObj = 'Bench'
	elseif objLower:find('chair') then
		cleanObj = 'Chair'
	elseif objLower:find('basket') or ownerLower:find('ferris') then
		cleanObj = 'Ferris Wheel'
	elseif objLower:find('happy') then
		cleanObj = 'Spring Rider'
	elseif objLower:find('fune') or objLower:find('boat') then
		cleanObj = 'Boat'
	elseif objLower:find('bike') or objLower:find('bicycle') then
		cleanObj = 'Bicycle'
	end

	return 'Sit', cleanObj
end

-- Every seat starts disabled, so touching it does nothing. The prompt is the
-- only way in, and the seat is re-disabled the moment the rider leaves.
local function setupSeat(seat: Seat | VehicleSeat, objectText: string)
	if seat:FindFirstChild('RidePrompt') or seat:FindFirstChild('SitPrompt') then
		return
	end

	seat.Disabled = true
	local actionText, cleanObject = getSeatActionAndObject(seat, objectText)

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = if actionText == 'Ride' then 'RidePrompt' else 'SitPrompt'
	prompt.ActionText = actionText
	prompt.ObjectText = cleanObject
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 9
	prompt.Parent = seat

	prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if not humanoid or humanoid.SeatPart or seat.Occupant then
			return
		end
		seat.Disabled = false
		seat:Sit(humanoid)
	end)

	seat:GetPropertyChangedSignal('Occupant'):Connect(function()
		prompt.Enabled = seat.Occupant == nil
		if not seat.Occupant then
			-- Re-arm so the seat cannot be entered by touch afterwards.
			task.defer(function()
				if not seat.Occupant then
					seat.Disabled = true
				end
			end)
		end
	end)
end

--=============================================================================
-- Driving
--=============================================================================

local function stopDriving(seat: VehicleSeat, rootPart: BasePart?, onWater: boolean?)
	local connection = activeDrives[seat]
	if connection then
		connection:Disconnect()
		activeDrives[seat] = nil
	end
	seat.Throttle = 0
	seat.Steer = 0
	if not rootPart then
		return
	end
	-- Destroy every match, not just the first: a vehicle that was rigged twice
	-- ends up with two of each, and leaving one behind keeps driving the hull.
	for _, child in rootPart:GetChildren() do
		if child.Name == 'DriveAttachment' or child.Name == 'DriveLV' or child.Name == 'DriveAV' then
			child:Destroy()
		end
	end
	rootPart.AssemblyLinearVelocity = Vector3.zero
	rootPart.AssemblyAngularVelocity = Vector3.zero

	if onWater then
		-- Park a boat the instant the driver stands up. The hull weighs less than
		-- the people on it, so the rider's body dropping onto the deck shoves the
		-- craft: any settling window at all is long enough for it to slide out
		-- from under them. Return to the parked waterline, level it, and lock.
		local parkedY = rootPart:GetAttribute('ParkedY')
		local position = rootPart.Position
		if typeof(parkedY) == 'number' then
			position = Vector3.new(position.X, parkedY, position.Z)
		end
		local _, yaw, _ = rootPart.CFrame:ToOrientation()
		rootPart.CFrame = CFrame.new(position) * CFrame.fromOrientation(0, yaw, 0)
		rootPart.AssemblyLinearVelocity = Vector3.zero
		rootPart.AssemblyAngularVelocity = Vector3.zero
		rootPart.Anchored = true
		return
	end

	-- Land vehicles keep a grace period: a bike abandoned mid-hop has to drop
	-- back onto its wheels before it is pinned, or it freezes in the air.
	local existingAnchor = anchorTasks[seat]
	if existingAnchor then
		task.cancel(existingAnchor)
	end
	anchorTasks[seat] = task.delay(1.5, function()
		anchorTasks[seat] = nil
		if not seat.Occupant then
			rootPart.Anchored = true
		end
	end)
end

local function startDriving(seat: VehicleSeat, rootPart: BasePart, onWater: boolean, wheels: { { motor: Motor6D, axis: Vector3, radius: number } })
	local attachment = Instance.new('Attachment')
	attachment.Name = 'DriveAttachment'
	attachment.CFrame = rootPart.CFrame:ToObjectSpace(seat.CFrame)
	attachment.Parent = rootPart

	local targetWaterlineY = rootPart:GetAttribute('WaterlineY') or rootPart.Position.Y
	if onWater and targetWaterlineY < 3.5 then
		targetWaterlineY = 4.8
	end

	local linear = Instance.new('LinearVelocity')
	linear.Name = 'DriveLV'
	linear.Attachment0 = attachment
	linear.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	-- On water: full 3D force for buoyancy and crisp water steering; on land: XZ drive with gravity.
	linear.MaxAxesForce = if onWater then Vector3.new(500000, 500000, 500000) else Vector3.new(500000, 0, 500000)
	linear.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	linear.VectorVelocity = Vector3.zero
	linear.Parent = rootPart

	local angular = Instance.new('AngularVelocity')
	angular.Name = 'DriveAV'
	angular.Attachment0 = attachment
	angular.MaxTorque = 500000
	angular.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	angular.AngularVelocity = Vector3.zero
	angular.Parent = rootPart

	local groundCheck = RaycastParams.new()
	groundCheck.FilterType = Enum.RaycastFilterType.Exclude
	groundCheck.FilterDescendantsInstances = { rootPart:FindFirstAncestorWhichIsA('Model') :: Instance }

	-- Boats glide fast with smooth water response; bikes respond sharply.
	local baseSpeed = if onWater then 55 else 34
	local turnSpeed = if onWater then 2.2 else 1.9
	local responsiveness = if onWater then 0.12 else 0.12

	local currentForwardSpeed = 0
	local spin = 0

	activeDrives[seat] = RunService.Heartbeat:Connect(function(delta)
		local occupant = seat.Occupant
		local rider = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
		local boost = if rider and boosting[rider] then 1.8 else 1

		-- Hop on land vehicles
		if rider and hopRequested[rider] then
			hopRequested[rider] = false
			local grounded = workspace:Raycast(
				rootPart.Position,
				Vector3.new(0, -(rootPart.Size.Y * 0.5 + 4), 0),
				groundCheck
			)
			if grounded and not onWater then
				local mass = rootPart.AssemblyMass
				local align = rootPart:FindFirstChild('StabilityOrientation')
				if align and align:IsA('AlignOrientation') then
					align.Enabled = false
					task.delay(0.65, function()
						if align.Parent then
							align.Enabled = true
						end
					end)
				end
				rootPart:ApplyImpulseAtPosition(
					Vector3.new(0, mass * 62, 0),
					rootPart.Position + rootPart.CFrame.LookVector * (rootPart.Size.Z * 0.5 + 1.2)
				)
			end
		end

		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat

		-- Roll the wheels if wheeled vehicle
		if #wheels > 0 then
			local velocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
			local direction = if rootPart.CFrame.LookVector:Dot(velocity) < 0 then -1 else 1
			spin = (spin + (velocity.Magnitude / wheels[1].radius) * delta * direction) % (math.pi * 2)
			for _, wheel in wheels do
				wheel.motor.Transform = CFrame.fromAxisAngle(wheel.axis, spin)
			end
		end

		local targetSpeed = throttle * baseSpeed * boost
		local lerp = if throttle == 0 then responsiveness * 0.5 else responsiveness
		currentForwardSpeed = currentForwardSpeed + (targetSpeed - currentForwardSpeed) * lerp

		local yVel = 0
		if onWater then
			local currentY = rootPart.Position.Y
			local bobbing = math.sin(tick() * 2.2) * 0.12
			yVel = ((targetWaterlineY + bobbing) - currentY) * 7.5
		end

		-- -Z is forward in Attachment0 space
		linear.VectorVelocity = Vector3.new(0, yVel, -currentForwardSpeed)

		local targetRotY = -steer * turnSpeed
		local bankRoll = if onWater then -steer * 0.22 else 0

		angular.AngularVelocity = Vector3.new(
			0,
			targetRotY,
			bankRoll
		)
	end)
end

--=============================================================================
-- Rigging a Creator Store prop into a drivable assembly
--=============================================================================

local function isBicycle(model: Model): boolean
	if model:GetAttribute('ParkBike') or model:GetAttribute('SuwaBicycle') then
		return true
	end
	local name = model.Name:lower()
	return name:find('bike') ~= nil or name:find('bicycle') ~= nil
end

local function isWaterVehicle(model: Model): boolean
	if model:FindFirstAncestor('LakeCrafts') or (model.Parent and model.Parent.Name == 'LakeCrafts') then
		return true
	end
	local name = model.Name:lower()
	if
		name:find('boat')
		or name:find('fune')
		or name:find('ship')
		or name:find('craft')
		or name:find('swan')
		or name:find('duck')
		or name:find('jetski')
		or name:find('kayak')
		or name:find('canoe')
	then
		return true
	end
	return false
end

local function rigVehicle(model: Model)
	if model:GetAttribute('SuwaRigged') or isBicycle(model) then
		return
	end

	local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart', true)
	if not rootPart then
		warn(`[Vehicle] No BasePart in {model:GetFullName()}`)
		return
	end

	-- Claim the model before doing any work. init() and the DescendantAdded
	-- watcher can both reach the same vehicle, and marking it only at the end
	-- let both callers past this guard: that rigged everything twice, leaving
	-- two AlignOrientations fighting over the hull and two Occupant listeners
	-- racing to start and stop the same drive.
	model:SetAttribute('SuwaRigged', true)

	local boundingCFrame, size = model:GetBoundingBox()
	local onWater = isWaterVehicle(model)

	local COLLISION_PARTS: { [string]: boolean } = {
		BoatHullRoot = true,
		DeckWalkCollision = true,
		RoofWalkCollision = true,
		SlideSlopeCollision = true,
		SlideEntryCollision = true,
		SlideExitCollision = true,
		ClimbableLadder = true,
		-- Structural furniture the rider can walk into on Fune's lounge deck; kept
		-- solid so people stop sinking into the couches/table/helm/railings, while
		-- decorative trim (logos, gauges, speakers, decals) stays non-collide so it
		-- doesn't snag movement, and the slide tube (Slide_Roof) stays untouched so
		-- riders can still pass through it.
		PortBow_Couch_Vinyl = true,
		StbdBow_Couch_Vinyl = true,
		PortStern_Couch_Vinyl_main = true,
		StbdStern_Couch_VInyl = true,
		PortBow_Couch_Baseboard = true,
		StbdBow_Couch_Baseboard = true,
		PortStern_Couch_Baseboard = true,
		StbdStern_Couch_Baseboard = true,
		Wall_Stern = true,
		Table_Board = true,
		Helm_Chair = true,
		Helm_Dash = true,
		Helm_Molding = true,
		Deck_Guards = true,
		Sink_cabinet = true,
		-- Boat_Railing, Pontoons, *_Door_Railing and SkiRail are deliberately left
		-- off this list: they're lattice/bar or curved-tube meshes, and Roblox's
		-- default collision fidelity can fill in the gaps of a lattice into a
		-- solid wall, or turn a curved pontoon tube into something a boarding
		-- player bounces off instead of climbing over.
	}

	-- Some boats (Fune) are hand-rigged with dedicated invisible collision
	-- boxes, so only those should stay solid and the detailed visual mesh can
	-- go non-collide. Boats with no such parts (e.g. Speedboat) never shipped
	-- collision boxes of their own, so blanket-disabling collision there would
	-- leave the whole hull and deck walkable-through. Only take the whitelist
	-- away from a boat that actually has it.
	local hasCollisionParts = false
	for _, part in model:GetDescendants() do
		if part:IsA('BasePart') and part ~= rootPart and COLLISION_PARTS[part.Name] then
			hasCollisionParts = true
			break
		end
	end

	-- Creator Store props hold themselves together with Anchored rather than
	-- welds, so weld everything to the root before unanchoring or the model
	-- collapses into loose parts the moment it is freed.
	--
	-- Wheels are the exception: a rigid weld locks them solid. They get a
	-- Motor6D instead, which holds them in place but can still be rotated.
	local wheels: { { motor: Motor6D, axis: Vector3, radius: number } } = {}
	for _, part in model:GetDescendants() do
		if part:IsA('BasePart') and part ~= rootPart then
			part.Anchored = false
			if onWater then
				part.Massless = true
				if hasCollisionParts then
					part.CanCollide = COLLISION_PARTS[part.Name] == true
				end
			end
			if looksLikeWheel(part) then
				-- Drop any existing joint, or the motor fights it.
				for _, joint in part:GetChildren() do
					if joint:IsA('WeldConstraint') or joint:IsA('Weld') or joint:IsA('Motor6D') then
						joint:Destroy()
					end
				end
				for _, joint in rootPart:GetChildren() do
					if joint:IsA('WeldConstraint') and (joint.Part0 == part or joint.Part1 == part) then
						joint:Destroy()
					end
				end

				local motor = Instance.new('Motor6D')
				motor.Name = `WheelMotor_{part.Name}`
				motor.Part0 = rootPart
				motor.Part1 = part
				motor.C0 = rootPart.CFrame:ToObjectSpace(part.CFrame)
				motor.C1 = CFrame.identity
				motor.Parent = rootPart

				local size = part.Size
				table.insert(wheels, {
					motor = motor,
					axis = axleAxis(part),
					-- Radius is half the widest face, never the axle thickness.
					radius = math.max(0.5, math.max(size.X, size.Y, size.Z) / 2),
				})
			else
				local weld = Instance.new('WeldConstraint')
				weld.Part0 = rootPart
				weld.Part1 = part
				weld.Parent = rootPart
			end
		end
	end
	rootPart.Anchored = false
	-- A boat has to outweigh the people aboard, or a rider stepping onto the
	-- deck shoves the whole hull out from under themselves. Still well under
	-- water's density, so it keeps floating.
	rootPart.CustomPhysicalProperties = PhysicalProperties.new(
		if onWater then 0.7 else 0.12,
		0.3,
		0.5
	)

	-- Clear anything a previous rig left behind, so a re-rig cannot stack a
	-- second set of constraints onto the same hull.
	for _, child in rootPart:GetChildren() do
		if child.Name == 'StabilityAttachment' or child.Name == 'StabilityOrientation' then
			child:Destroy()
		end
	end

	-- Keep it upright. A bike with no rider falls over instantly otherwise.
	local stability = Instance.new('Attachment')
	stability.Name = 'StabilityAttachment'
	stability.WorldAxis = Vector3.yAxis
	stability.Parent = rootPart

	local align = Instance.new('AlignOrientation')
	align.Name = 'StabilityOrientation'
	align.Attachment0 = stability
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.AlignType = Enum.AlignType.PrimaryAxisParallel
	align.PrimaryAxisOnly = true -- free to turn, locked against tipping
	align.PrimaryAxis = Vector3.yAxis
	-- Rigid for boats too. A springy upright constraint lets the hull pitch up
	-- when it rides onto the shore, and past a certain angle nothing brings it
	-- back -- that is how a boat ended up standing on its nose in the shallows.
	-- Rigid leaves yaw free but makes pitch and roll impossible.
	align.RigidityEnabled = true
	align.Parent = rootPart

	local driverSeatsFound: { VehicleSeat } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA('VehicleSeat') then
			table.insert(driverSeatsFound, descendant)
		end
	end

	if #driverSeatsFound == 0 then
		local seat = Instance.new('VehicleSeat')
		seat.Name = 'SuwaDriveSeat'
		seat.Size = Vector3.new(1.6, 0.2, 1.6)
		seat.Transparency = 1
		seat.CanCollide = false
		seat.CFrame = CFrame.new(boundingCFrame.Position + Vector3.new(0, size.Y * 0.25, 0))
			* boundingCFrame.Rotation
		seat.Parent = model

		local weld = Instance.new('WeldConstraint')
		weld.Part0 = seat
		weld.Part1 = rootPart
		weld.Parent = seat
		table.insert(driverSeatsFound, seat)
	end

	-- Nobody starts as the driver, so start parked: otherwise a vehicle that's
	-- never been driven sits fully unanchored, and a passenger merely walking
	-- into the now-solid furniture can nudge the whole thing adrift. The
	-- Occupant listener below un-anchors it the moment someone actually drives.
	--
	-- Remember where the hull floats while parked too, so a boat always returns
	-- to this exact waterline instead of freezing wherever the drive left it.
	rootPart:SetAttribute('ParkedY', rootPart.Position.Y)
	rootPart.Anchored = true

	for _, driver in driverSeatsFound do
		setupSeat(driver, model.Name)
		driver:GetPropertyChangedSignal('Occupant'):Connect(function()
			if driver.Occupant then
				local existingAnchor = anchorTasks[driver]
				if existingAnchor then
					task.cancel(existingAnchor)
					anchorTasks[driver] = nil
				end
				rootPart.Anchored = false
				local rider = Players:GetPlayerFromCharacter(driver.Occupant.Parent)
				if rider then
					pcall(function()
						rootPart:SetNetworkOwner(rider)
					end)
				end
				startDriving(driver, rootPart, onWater, wheels)
			else
				stopDriving(driver, rootPart, onWater)
				pcall(function()
					rootPart:SetNetworkOwner(nil)
				end)
			end
		end)
	end
end

--=============================================================================

local function collectVehicleModels(): { Model }
	local found: { Model } = {}
	local seen: { [Model]: boolean } = {}
	local function consider(model: Model)
		if not seen[model] then
			seen[model] = true
			table.insert(found, model)
		end
	end

	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('Model') then
			if descendant:GetAttribute('Vehicle') then
				consider(descendant)
			end
		elseif descendant:IsA('Folder') and VEHICLE_FOLDERS[descendant.Name] then
			for _, child in descendant:GetChildren() do
				if child:IsA('Model') then
					consider(child)
				end
			end
		end
	end
	return found
end

function VehicleInteractionService.init()
	local vehicles = collectVehicleModels()
	for _, model in vehicles do
		rigVehicle(model)
	end

	-- Every remaining seat in the world (benches, ferris wheel, merry-go-round,
	-- passenger seats) also goes behind a prompt.
	local plainSeats = 0
	for _, descendant in workspace:GetDescendants() do
		if (descendant:IsA('Seat') or descendant:IsA('VehicleSeat')) and not descendant:FindFirstChild('RidePrompt') then
			local owner = descendant:FindFirstAncestorWhichIsA('Model')
			setupSeat(descendant, if owner then owner.Name else 'Seat')
			plainSeats += 1
		end
	end

	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA('Seat') or descendant:IsA('VehicleSeat') then
			task.defer(function()
				if descendant.Parent and not descendant:FindFirstChild('RidePrompt') then
					local owner = descendant:FindFirstAncestorWhichIsA('Model')
					setupSeat(descendant, if owner then owner.Name else 'Seat')
				end
			end)
		elseif descendant:IsA('Model') and isInsideVehicleFolder(descendant) then
			task.delay(0.5, function()
				if descendant.Parent then
					local targetModel: Model = descendant
					while targetModel.Parent and targetModel.Parent ~= workspace do
						if targetModel.Parent:IsA('Folder') and VEHICLE_FOLDERS[targetModel.Parent.Name] then
							break
						elseif targetModel.Parent:IsA('Model') then
							targetModel = targetModel.Parent
						else
							break
						end
					end
					rigVehicle(targetModel)
				end
			end)
		end
	end)

	RemoteRegistry.registerEvent('VehicleBoost', function(player: Player, value: unknown)
		boosting[player] = value == true
	end)
	RemoteRegistry.registerEvent('VehicleHop', function(player: Player)
		hopRequested[player] = true
	end)

	Players.PlayerRemoving:Connect(function(player)
		boosting[player] = nil
		hopRequested[player] = nil
		for seat, connection in activeDrives do
			if not seat.Occupant then
				connection:Disconnect()
				activeDrives[seat] = nil
			end
		end
	end)

	print(`[Vehicle] Rigged {#vehicles} vehicles, prompted {plainSeats} further seats.`)
end

return VehicleInteractionService
