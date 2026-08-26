--!strict

-- BicycleService — mamachari you can actually ride.
--
-- The Creator Store bike ships as a fully anchored prop: every part carries
-- Anchored = true and the frame is held together by WeldConstraints hanging off
-- the seat. An anchored assembly cannot move no matter what force is applied to
-- it, which is why the bikes stayed nailed to the rack. Unanchoring from the
-- client does not help either — Anchored never replicates upwards, so the
-- server keeps overwriting it a frame later.
--
-- So the whole ride lives here, on the server:
--
--   rig      once at startup: strip the legacy BodyGyros that fight every
--            rotation, weld the frame into one assembly, and hang the visible
--            wheel discs off Motor6Ds so they can roll.
--   mount    unanchor, spawn the drive constraints, run the throttle/steer loop.
--   dismount tear the constraints down and re-anchor the bike where it was
--            left, so parked bikes never drift out of the rack.
--
-- Everything is driven through constraints rather than direct velocity or
-- impulse writes: the seated rider's client owns the assembly's physics, and it
-- would simply overwrite anything the server poked at directly. Constraints
-- replicate and are honoured by whoever is simulating.
--
-- The wheels are *not* spun here. Motor6D.Transform is not a replicated
-- property, so a wheel turned on the server still draws dead straight on every
-- client. BicycleController rolls them locally instead; the rig only records
-- the radius and mounting direction each wheel needs.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))

local BicycleService = {}

local FORWARD_SPEED = 36
local REVERSE_SPEED = 13
local BOOST_MULTIPLIER = 1.75
local TURN_SPEED = 2.3
local DRIVE_FORCE = 500000
local TURN_TORQUE = 400000

-- Hop: a short upward launch plus a nose-up lean, then back to level in time
-- for the landing.
local HOP_SPEED = 34
local HOP_PITCH = math.rad(26)
local HOP_LAUNCH = 0.14
local HOP_LEVEL = 0.48
local HOP_COOLDOWN = 0.75

-- A bike refuses to ride into the lake or off a ledge. The path is probed at
-- two distances ahead; water, a missing floor, or a drop steeper than this
-- stops the wheels rather than letting momentum carry the rider over. The drop
-- is measured against the ground under the bike rather than the seat, so the
-- number means what it says whatever the bike is sitting on — park ramps and
-- kerbs stay rideable, the edge of a bridge deck does not.
local PROBE_DISTANCES = { 5, 9 }
local SAFE_DROP = 5
local WATER_LEVEL = 0
-- Last resort if a bike ends up in the water anyway (pushed, glitched, spawned
-- badly): the rider is put back on their feet and the bike goes home.
local DROWN_LEVEL = WATER_LEVEL + 2

type Wheel = {
	collider: BasePart,
	mesh: BasePart,
	motor: Motor6D,
	radius: number,
	sign: number,
}

type Bike = {
	model: Model,
	seat: VehicleSeat,
	parts: { BasePart },
	wheels: { Wheel },
	prompt: ProximityPrompt,
	attachment: Attachment,
	align: AlignOrientation,
	linear: LinearVelocity?,
	angular: AngularVelocity?,
	connection: RBXScriptConnection?,
	home: CFrame,
	hopping: boolean,
	hopVelocityY: number?,
	anchorTask: thread?,
}

local bikes: { [VehicleSeat]: Bike } = {}
local boosting: { [Player]: boolean } = {}

--=============================================================================
-- Rigging
--=============================================================================

-- The visible wheel is a massless MeshPart parented to an invisible ball
-- collider. Spin the mesh and the bike rolls; spin the collider and it fights
-- the ground.
local function findWheelMesh(collider: BasePart): BasePart?
	for _, child in collider:GetChildren() do
		if child:IsA('BasePart') and child.Transparency < 1 then
			return child
		end
	end
	return nil
end

local function looksLikeCollider(part: BasePart): boolean
	if not part.CanCollide then
		return false
	end
	local name = part.Name:lower()
	if name:find('wheel') or name:find('tire') or name:find('tyre') then
		return true
	end
	return part:IsA('Part') and part.Shape == Enum.PartType.Ball
end

local function setAnchored(bike: Bike, anchored: boolean)
	for _, part in bike.parts do
		part.Anchored = anchored
	end
end

local function rig(model: Model): Bike?
	local seat = model:FindFirstChildWhichIsA('VehicleSeat', true)
	if not seat then
		return nil
	end
	if bikes[seat] then
		return bikes[seat]
	end

	local parts: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA('BasePart') then
			table.insert(parts, descendant)
		elseif descendant:IsA('BodyGyro') or descendant:IsA('BodyVelocity') or descendant:IsA('BodyPosition') or descendant:IsA('BodyAngularVelocity') then
			-- Legacy movers left in the prop. A BodyGyro on a wheel pins it
			-- against every rotation the ride tries to apply.
			descendant:Destroy()
		elseif descendant:IsA('ProximityPrompt') then
			-- Any prompt the park builder put here is replaced below.
			descendant:Destroy()
		end
	end

	-- Rebuild the joints from scratch: the shipped welds are a mix of styles
	-- and some of them pin the wheels solid.
	for _, part in parts do
		for _, joint in part:GetChildren() do
			if joint:IsA('WeldConstraint') or joint:IsA('Weld') or joint:IsA('Motor6D') then
				joint:Destroy()
			end
		end
	end

	local wheels: { Wheel } = {}
	for _, part in parts do
		if part ~= seat and looksLikeCollider(part) then
			local mesh = findWheelMesh(part)
			if mesh then
				local motor = Instance.new('Motor6D')
				motor.Name = 'WheelMotor'
				motor.Part0 = part
				motor.Part1 = mesh
				motor.C0 = part.CFrame:ToObjectSpace(mesh.CFrame)
				motor.C1 = CFrame.identity
				motor.Parent = part

				local size = mesh.Size
				local radius = math.max(0.5, math.max(size.X, size.Y, size.Z) * 0.5)
				-- Which way round the disc is mounted decides which way it has
				-- to turn to look like it is rolling forwards.
				local sign = if mesh.CFrame.RightVector:Dot(seat.CFrame.RightVector) >= 0 then 1 else -1

				-- Handed to the client, which is where the spin actually runs.
				motor:SetAttribute('WheelRadius', radius)
				motor:SetAttribute('SpinSign', sign)

				table.insert(wheels, {
					collider = part,
					mesh = mesh,
					motor = motor,
					radius = radius,
					sign = sign,
				})
			end
		end
	end

	for _, part in parts do
		if part ~= seat and part.Parent ~= nil then
			local isWheelMesh = false
			for _, wheel in wheels do
				if wheel.mesh == part then
					isWheelMesh = true
					break
				end
			end
			if not isWheelMesh then
				local weld = Instance.new('WeldConstraint')
				weld.Part0 = seat
				weld.Part1 = part
				weld.Parent = seat
			end
		end
	end

	-- Grip, so the bike does not slide out from under itself on a slope.
	for _, wheel in wheels do
		wheel.collider.CustomPhysicalProperties = PhysicalProperties.new(0.7, 1.2, 0.2, 8, 1)
	end

	local attachment = Instance.new('Attachment')
	attachment.Name = 'StabilityAttachment'
	attachment.Axis = Vector3.yAxis
	attachment.Parent = seat

	-- Keeps the bike upright without locking the yaw: only the bike's own up
	-- axis is held parallel to world up, so it is still free to steer. Tilting
	-- that axis is also how the hop leans the nose up.
	local align = Instance.new('AlignOrientation')
	align.Name = 'StabilityOrientation'
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.AlignType = Enum.AlignType.PrimaryAxisParallel
	align.PrimaryAxis = Vector3.yAxis
	align.MaxTorque = math.huge
	align.Responsiveness = 45
	align.Parent = seat

	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'RidePrompt'
	prompt.ActionText = 'Ride'
	prompt.ObjectText = 'Mamachari ・ ママチャリ'
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 8
	prompt.ClickablePrompt = true
	prompt.Parent = seat

	-- Nobody gets snapped onto a bike just by brushing past it: the seat only
	-- opens for the moment the prompt puts a rider on it.
	seat.Disabled = true

	local bike: Bike = {
		model = model,
		seat = seat,
		parts = parts,
		wheels = wheels,
		prompt = prompt,
		attachment = attachment,
		align = align,
		linear = nil,
		angular = nil,
		connection = nil,
		home = (model:GetAttribute('ParkingCFrame') :: CFrame?) or model:GetPivot(),
		hopping = false,
		hopVelocityY = nil,
		anchorTask = nil,
	}

	model:SetAttribute('SuwaBicycle', true)
	seat:SetAttribute('SuwaBicycle', true)
	bikes[seat] = bike
	return bike
end

--=============================================================================
-- Riding
--=============================================================================

-- The bike itself and every player have to be filtered out, or the probe just
-- hits the rider's own legs. IgnoreWater stays false: the lake surface is
-- exactly what the path guard is looking for.
local function probeParams(bike: Bike): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = false
	local exclude: { Instance } = { bike.model }
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclude, player.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	return params
end

-- Is there solid, dry, roughly level ground this way? Anything else — open
-- water, a hole, a cliff edge — counts as blocked and the wheels stop.
local function pathBlocked(bike: Bike, direction: Vector3): boolean
	local params = probeParams(bike)
	local from = bike.seat.Position

	local under = workspace:Raycast(from + Vector3.new(0, 3, 0), Vector3.new(0, -30, 0), params)
	local groundY = if under then under.Position.Y else from.Y - 2.5

	for _, distance in PROBE_DISTANCES do
		local origin = from + direction * distance + Vector3.new(0, 5, 0)
		local hit = workspace:Raycast(origin, Vector3.new(0, -26, 0), params)
		if not hit then
			return true
		end
		if hit.Material == Enum.Material.Water or hit.Position.Y <= WATER_LEVEL + 0.5 then
			return true
		end
		if hit.Position.Y < groundY - SAFE_DROP then
			return true
		end
	end
	return false
end

local function isGrounded(bike: Bike): boolean
	local params = probeParams(bike)

	for _, wheel in bike.wheels do
		local reach = wheel.radius + 1.2
		if workspace:Raycast(wheel.collider.Position, Vector3.new(0, -reach, 0), params) then
			return true
		end
	end
	return false
end

local function hop(bike: Bike)
	if bike.hopping or not bike.seat.Occupant then
		return
	end
	local linear, angular = bike.linear, bike.angular
	if not (linear and angular) or not isGrounded(bike) then
		return
	end
	bike.hopping = true

	-- Lean the bike's up axis backwards and the upright constraint answers by
	-- pitching the nose up — which lifts the front wheel, not the rear.
	bike.attachment.Axis = Vector3.new(0, math.cos(HOP_PITCH), -math.sin(HOP_PITCH))
	-- The steering constraint pins all three rotation axes, so it has to let go
	-- for the length of the hop or the lean never happens.
	angular.MaxTorque = 0
	-- Y force is normally zero so gravity owns the vertical. Take it back just
	-- long enough to launch.
	linear.MaxAxesForce = Vector3.new(DRIVE_FORCE, DRIVE_FORCE, DRIVE_FORCE)
	bike.hopVelocityY = HOP_SPEED

	task.delay(HOP_LAUNCH, function()
		bike.hopVelocityY = nil
		if linear.Parent then
			linear.MaxAxesForce = Vector3.new(DRIVE_FORCE, 0, DRIVE_FORCE)
		end
	end)
	task.delay(HOP_LEVEL, function()
		if bike.attachment.Parent then
			bike.attachment.Axis = Vector3.yAxis
		end
		if angular.Parent then
			angular.MaxTorque = TURN_TORQUE
		end
	end)
	task.delay(HOP_COOLDOWN, function()
		bike.hopping = false
	end)
end

local function stopRiding(bike: Bike)
	if bike.connection then
		bike.connection:Disconnect()
		bike.connection = nil
	end
	bike.seat.Throttle = 0
	bike.seat.Steer = 0
	bike.hopping = false
	bike.hopVelocityY = nil
	bike.attachment.Axis = Vector3.yAxis

	for _, name in { 'DriveAttachment', 'DriveLV', 'DriveAV' } do
		local existing = bike.seat:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end
	bike.linear = nil
	bike.angular = nil

	bike.seat.AssemblyLinearVelocity = Vector3.zero
	bike.seat.AssemblyAngularVelocity = Vector3.zero

	-- Let it drop onto its wheels before pinning it again, so a bike abandoned
	-- mid-hop does not freeze in the air.
	if bike.anchorTask then
		task.cancel(bike.anchorTask)
	end
	bike.anchorTask = task.delay(1.5, function()
		bike.anchorTask = nil
		if not bike.seat.Occupant then
			setAnchored(bike, true)
		end
	end)
end

-- The bike went in the lake. Put the rider back on their feet by the rack and
-- send the bike home, rather than leaving a mamachari bobbing in Suwako.
local function returnHome(bike: Bike)
	local occupant = bike.seat.Occupant
	if occupant then
		occupant.Sit = false
		local character = occupant.Parent
		if character and character:IsA('Model') then
			character:PivotTo(bike.home * CFrame.new(4, 3.5, 0))
		end
	end

	-- Deferred so it lands after the Occupant signal has torn the ride down.
	task.defer(function()
		if bike.anchorTask then
			task.cancel(bike.anchorTask)
			bike.anchorTask = nil
		end
		setAnchored(bike, true)
		bike.model:PivotTo(bike.home)
	end)
end

local function startRiding(bike: Bike)
	if bike.anchorTask then
		task.cancel(bike.anchorTask)
		bike.anchorTask = nil
	end
	setAnchored(bike, false)

	local seat = bike.seat

	local attachment = Instance.new('Attachment')
	attachment.Name = 'DriveAttachment'
	attachment.Parent = seat

	local linear = Instance.new('LinearVelocity')
	linear.Name = 'DriveLV'
	linear.Attachment0 = attachment
	linear.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linear.RelativeTo = Enum.ActuatorRelativeTo.World
	-- No force on Y: gravity keeps the bike on the ground between hops.
	linear.MaxAxesForce = Vector3.new(DRIVE_FORCE, 0, DRIVE_FORCE)
	linear.VectorVelocity = Vector3.zero
	linear.Parent = seat

	local angular = Instance.new('AngularVelocity')
	angular.Name = 'DriveAV'
	angular.Attachment0 = attachment
	angular.RelativeTo = Enum.ActuatorRelativeTo.World
	angular.MaxTorque = TURN_TORQUE
	angular.AngularVelocity = Vector3.zero
	angular.Parent = seat

	bike.linear = linear
	bike.angular = angular

	bike.connection = RunService.Heartbeat:Connect(function(delta)
		local occupant = seat.Occupant
		if not occupant then
			return
		end
		local rider = Players:GetPlayerFromCharacter(occupant.Parent)
		local boost = if rider and boosting[rider] then BOOST_MULTIPLIER else 1

		-- Anything below the water line means the bike is in the lake already.
		if seat.Position.Y < DROWN_LEVEL then
			returnHome(bike)
			return
		end

		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat

		local forward = seat.CFrame.LookVector * Vector3.new(1, 0, 1)
		if forward.Magnitude > 0.01 then
			forward = forward.Unit
		end

		-- Refuse to pedal into the lake or over a ledge. The rider keeps
		-- steering and can always back out the way they came.
		local blocked = false
		if math.abs(throttle) > 0.05 then
			blocked = pathBlocked(bike, if throttle > 0 then forward else -forward)
		end

		local top = if throttle >= 0 then FORWARD_SPEED * boost else REVERSE_SPEED
		local target = if blocked then Vector3.zero else forward * (throttle * top)

		-- Framerate independent easing, so the bike pulls away the same on a
		-- 30fps phone as on a 240Hz desktop. Braking at an edge is much
		-- sharper, so momentum cannot carry the rider over it.
		local rate = if blocked then 22 elseif math.abs(throttle) > 0.05 then 7 else 3.5
		local alpha = 1 - math.exp(-rate * delta)
		local current = linear.VectorVelocity
		linear.VectorVelocity = Vector3.new(
			current.X + (target.X - current.X) * alpha,
			bike.hopVelocityY or 0,
			current.Z + (target.Z - current.Z) * alpha
		)

		-- Steering only bites once the bike is actually rolling — a parked bike
		-- should not spin on the spot.
		local velocity = seat.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
		local grip = math.clamp(velocity.Magnitude / 9, 0, 1)
		local targetYaw = -steer * TURN_SPEED * grip
		local currentYaw = angular.AngularVelocity.Y
		angular.AngularVelocity =
			Vector3.new(0, currentYaw + (targetYaw - currentYaw) * math.min(1, delta * 9), 0)
	end)
end

local function setupSeat(bike: Bike)
	local seat = bike.seat
	local prompt = bike.prompt

	prompt.Triggered:Connect(function(player)
		if seat.Occupant then
			return
		end
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then
			return
		end

		-- Unanchor before sitting: a seat welded into an anchored assembly
		-- drags the rider's character to a dead stop.
		if bike.anchorTask then
			task.cancel(bike.anchorTask)
			bike.anchorTask = nil
		end
		setAnchored(bike, false)

		prompt.Enabled = false
		seat.Disabled = false
		seat:Sit(humanoid)

		-- If the sit did not take (dead, already seated, ragdolled), close the
		-- seat again rather than leaving it open to anyone who walks into it.
		task.delay(0.3, function()
			if seat.Parent and not seat.Occupant then
				seat.Disabled = true
				prompt.Enabled = true
				setAnchored(bike, true)
			end
		end)
	end)

	seat:GetPropertyChangedSignal('Occupant'):Connect(function()
		if seat.Occupant then
			prompt.Enabled = false
			startRiding(bike)
		else
			seat.Disabled = true
			prompt.Enabled = true
			stopRiding(bike)
		end
	end)
end

--=============================================================================

local function collect(): { Model }
	local found: { Model } = {}
	local seen: { [Model]: boolean } = {}

	for _, descendant in workspace:GetDescendants() do
		local model: Model? = nil
		if descendant:IsA('Model') and descendant:GetAttribute('ParkBike') then
			model = descendant
		elseif descendant:IsA('Folder') and descendant.Name == 'Bicycles' then
			for _, child in descendant:GetChildren() do
				if child:IsA('Model') and not seen[child] then
					seen[child] = true
					table.insert(found, child)
				end
			end
		end
		if model and not seen[model] then
			seen[model] = true
			table.insert(found, model)
		end
	end
	return found
end

function BicycleService.init()
	local rigged = 0
	for _, model in collect() do
		local bike = rig(model)
		if bike then
			setupSeat(bike)
			rigged += 1
		end
	end

	-- Bikes the park builder drops in later still get rigged.
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA('Model') and descendant:GetAttribute('ParkBike') then
			task.delay(0.5, function()
				if descendant.Parent then
					local bike = rig(descendant)
					if bike then
						setupSeat(bike)
					end
				end
			end)
		end
	end)

	-- Boost and hop arrive over remotes. An attribute set on the client never
	-- replicates up to the server, so it cannot carry rider input.
	RemoteRegistry.registerEvent('VehicleBoost', function(player: Player, value: unknown)
		boosting[player] = value == true
	end)

	RemoteRegistry.registerEvent('VehicleHop', function(player: Player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		local seat = humanoid and humanoid.SeatPart
		local bike = seat and bikes[seat :: VehicleSeat]
		if bike then
			hop(bike)
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		boosting[player] = nil
	end)

	print(`[BicycleService] Rigged {rigged} mamachari.`)
end

return BicycleService
