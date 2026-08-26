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

-- Every seat starts disabled, so touching it does nothing. The prompt is the
-- only way in, and the seat is re-disabled the moment the rider leaves.
local function setupSeat(seat: Seat | VehicleSeat, objectText: string)
	if seat:FindFirstChild('RidePrompt') or seat:FindFirstChild('SitPrompt') then
		return
	end

	seat.Disabled = true
	local isDriver = seat:IsA('VehicleSeat')

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'RidePrompt'
	prompt.ActionText = if isDriver then 'Ride' else 'Sit'
	prompt.ObjectText = objectText
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

local function stopDriving(seat: VehicleSeat, rootPart: BasePart?)
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
	for _, name in { 'DriveAttachment', 'DriveLV', 'DriveAV' } do
		local existing = rootPart:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
	rootPart.AssemblyLinearVelocity = Vector3.new(0, rootPart.AssemblyLinearVelocity.Y, 0)
	rootPart.AssemblyAngularVelocity = Vector3.zero
end

local function startDriving(seat: VehicleSeat, rootPart: BasePart, onWater: boolean, wheels: { { motor: Motor6D, axis: Vector3, radius: number } })
	local attachment = Instance.new('Attachment')
	attachment.Name = 'DriveAttachment'
	attachment.Parent = rootPart

	local linear = Instance.new('LinearVelocity')
	linear.Name = 'DriveLV'
	linear.Attachment0 = attachment
	linear.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	-- No force on Y: buoyancy holds boats up, gravity holds bikes down.
	linear.MaxAxesForce = Vector3.new(500000, 0, 500000)
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	linear.VectorVelocity = Vector3.zero
	linear.Parent = rootPart

	local angular = Instance.new('AngularVelocity')
	angular.Name = 'DriveAV'
	angular.Attachment0 = attachment
	angular.MaxTorque = 500000
	angular.RelativeTo = Enum.ActuatorRelativeTo.World
	angular.AngularVelocity = Vector3.zero
	angular.Parent = rootPart

	local groundCheck = RaycastParams.new()
	groundCheck.FilterType = Enum.RaycastFilterType.Exclude
	groundCheck.FilterDescendantsInstances = { rootPart:FindFirstAncestorWhichIsA('Model') :: Instance }

	-- Boats glide and take a while to answer the helm; bikes respond sharply.
	local baseSpeed = if onWater then 40 else 34
	local turnSpeed = if onWater then 1.0 else 1.9
	local responsiveness = if onWater then 0.03 else 0.12

	local spin = 0
	activeDrives[seat] = RunService.Heartbeat:Connect(function(delta)
		local occupant = seat.Occupant
		local rider = occupant and Players:GetPlayerFromCharacter(occupant.Parent)
		local boost = if rider and boosting[rider] then 1.7 else 1

		-- Hop: kick the front up first, the way a rider lifts over a kerb. The
		-- upright constraint has to release for a moment or the pitch is locked.
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

		-- Roll the wheels at the speed the vehicle is actually travelling, so
		-- they never spin while stationary or skid while moving.
		if #wheels > 0 then
			local velocity = rootPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
			local direction = if rootPart.CFrame.LookVector:Dot(velocity) < 0 then -1 else 1
			spin = (spin + (velocity.Magnitude / wheels[1].radius) * delta * direction) % (math.pi * 2)
			for _, wheel in wheels do
				wheel.motor.Transform = CFrame.fromAxisAngle(wheel.axis, spin)
			end
		end

		local target = seat.CFrame.LookVector * (throttle * baseSpeed * boost)
		local lerp = if throttle == 0 then responsiveness * 0.5 else responsiveness
		local current = linear.VectorVelocity
		linear.VectorVelocity = Vector3.new(
			current.X + (target.X - current.X) * lerp,
			0,
			current.Z + (target.Z - current.Z) * lerp
		)

		local currentRot = angular.AngularVelocity
		local targetRotY = -steer * turnSpeed
		angular.AngularVelocity = Vector3.new(0, currentRot.Y + (targetRotY - currentRot.Y) * 0.1, 0)
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

local function rigVehicle(model: Model)
	if model:GetAttribute('SuwaRigged') or isBicycle(model) then
		return
	end

	local rootPart = model.PrimaryPart or model:FindFirstChildWhichIsA('BasePart', true)
	if not rootPart then
		warn(`[Vehicle] No BasePart in {model:GetFullName()}`)
		return
	end

	local boundingCFrame, size = model:GetBoundingBox()
	-- Water craft float; anything sitting on land is treated as a land vehicle.
	local onWater = boundingCFrame.Position.Y < 6

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
	rootPart.CustomPhysicalProperties = PhysicalProperties.new(0.15, 0.3, 0.5)

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
	align.RigidityEnabled = true
	align.Parent = rootPart

	local existingDriver: VehicleSeat? = nil
	for _, descendant in model:GetDescendants() do
		if descendant:IsA('VehicleSeat') then
			existingDriver = descendant
			break
		end
	end

	if not existingDriver then
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
		existingDriver = seat
	end

	model:SetAttribute('SuwaRigged', true)

	local driver = existingDriver :: VehicleSeat
	setupSeat(driver, model.Name)
	driver:GetPropertyChangedSignal('Occupant'):Connect(function()
		if driver.Occupant then
			startDriving(driver, rootPart, onWater, wheels)
		else
			stopDriving(driver, rootPart)
		end
	end)
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
					-- Creator Store packs often nest the real vehicle one level
					-- deeper inside a wrapper model.
					local inner = nil
					for _, grandchild in child:GetChildren() do
						if grandchild:IsA('Model') then
							inner = grandchild
							break
						end
					end
					consider(inner or child)
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
					rigVehicle(descendant)
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
