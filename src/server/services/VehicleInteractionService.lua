--!strict

-- Makes anything ridable actually ridable, and puts every seat behind an E
-- prompt so nobody is snapped into a seat just by brushing against it.
--
-- A vehicle is any Model that is either tagged with the attribute `Vehicle`, or
-- sits inside a folder named Bicycles / LakeCrafts anywhere in the Workspace.
-- Creator Store props ship fully anchored, so they are welded into one
-- assembly and unanchored here; otherwise they cannot move at all.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

local VehicleInteractionService = {}

local VEHICLE_FOLDERS = { Bicycles = true, LakeCrafts = true }
local BOOST_ATTRIBUTE = 'SuwaBoost'

local activeDrives: { [BasePart]: RBXScriptConnection } = {}

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

local function startDriving(seat: VehicleSeat, rootPart: BasePart, onWater: boolean)
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

	-- Boats glide and take a while to answer the helm; bikes respond sharply.
	local baseSpeed = if onWater then 40 else 34
	local turnSpeed = if onWater then 1.0 else 1.9
	local responsiveness = if onWater then 0.03 else 0.12

	activeDrives[seat] = RunService.Heartbeat:Connect(function()
		local boost = if seat:GetAttribute(BOOST_ATTRIBUTE) then 1.7 else 1
		local throttle = seat.ThrottleFloat
		local steer = seat.SteerFloat

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

local function rigVehicle(model: Model)
	if model:GetAttribute('SuwaRigged') then
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
	for _, part in model:GetDescendants() do
		if part:IsA('BasePart') and part ~= rootPart then
			local weld = Instance.new('WeldConstraint')
			weld.Part0 = rootPart
			weld.Part1 = part
			weld.Parent = rootPart
			part.Anchored = false
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
			startDriving(driver, rootPart, onWater)
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

	Players.PlayerRemoving:Connect(function()
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
