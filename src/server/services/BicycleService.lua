--!strict

-- Lightweight arcade bicycles for the compact map. The detailed mamachari
-- meshes stay anchored and are moved as one model, which keeps them stable on
-- mobile and avoids a fragile wheel-constraint setup during this map phase.

local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

local BICYCLE_VERSION = 11
-- Keep the mamachari compact relative to the 5.5-stud avatar.  The previous
-- 2.6-stud length made both the parked row and rideable bicycle feel oversized.
local TARGET_LENGTH = 1
local GROUND_CLEARANCE = 1.4
local TOP_SPEED = 24
local ACCELERATION = 22
local BRAKING = 30
local TURN_RATE = math.rad(72)

local BicycleService = {}
local speeds: { [Model]: number } = {}
local groundOffsets: { [Model]: number } = {}

local function isOverheadPart(part: Instance): boolean
	local lowerName = string.lower(part.Name)
	return string.find(lowerName, 'roof') ~= nil
		or string.find(lowerName, 'canopy') ~= nil
		or string.find(lowerName, 'cable') ~= nil
		or string.find(lowerName, 'wire') ~= nil
		or string.find(lowerName, 'branch') ~= nil
		or string.find(lowerName, 'crown') ~= nil
		or string.find(lowerName, 'sign') ~= nil
end

local function buildRaycastExclusions(currentBicycle: Model): { Instance }
	local exclusions: { Instance } = { currentBicycle }
	local bicyclesFolder = workspace:FindFirstChild('Bicycles')
	if bicyclesFolder then
		table.insert(exclusions, bicyclesFolder)
	end
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(exclusions, player.Character)
		end
	end
	return exclusions
end

local function surfaceHeight(model: Model, position: Vector3): number
	local exclusions = buildRaycastExclusions(model)
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = exclusions
	parameters.IgnoreWater = true
	local origin = position + Vector3.new(0, 30, 0)
	for _ = 1, 15 do
		local result = workspace:Raycast(origin, Vector3.new(0, -100, 0), parameters)
		if not result then
			return 0
		end
		local hit = result.Instance
		if isOverheadPart(hit) or (hit:IsA('BasePart') and not hit.CanCollide) then
			table.insert(exclusions, hit)
			parameters.FilterDescendantsInstances = exclusions
			origin = result.Position - Vector3.new(0, 0.05, 0)
		else
			return result.Position.Y
		end
	end
	return 0
end

local function scaleGeometryToLength(model: Model, targetLength: number)
	local _, initialSize = model:GetBoundingBox()
	local initialLength = math.max(initialSize.X, initialSize.Z)
	if initialLength <= 0.01 then
		return
	end
	local factor = targetLength / initialLength
	if math.abs(factor - 1) <= 0.01 then
		return
	end
	-- Use native Model:ScaleTo for flawless scaling
	model:ScaleTo(model:GetScale() * factor)
end

local function addSitPrompt(seat: Seat, actionText: string, objectText: string)
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'SitPrompt'
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
		if humanoid and not seat.Occupant then
			seat:Sit(humanoid)
		end
	end)
end

local function makeSeat(model: Model): VehicleSeat
	local existing = model:FindFirstChild('RideSeat')
	local seat: VehicleSeat
	if existing and existing:IsA('VehicleSeat') then
		seat = existing
	else
		seat = Instance.new('VehicleSeat')
		seat.Name = 'RideSeat'
		seat.Size = Vector3.new(0.75, 0.3, 0.8)
		seat.Color = Color3.fromRGB(38, 34, 31)
		seat.Material = Enum.Material.Leather
		seat.Transparency = 1
		seat.Anchored = true
		seat.CanCollide = false
		seat.Massless = true
		seat.CFrame = model:GetPivot() * CFrame.new(0, 0.55, 0.1)
		seat.Parent = model
	end

	local oldPrompt = seat:FindFirstChild('RidePrompt')
	if oldPrompt then
		oldPrompt:Destroy()
	end
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'RidePrompt'
	prompt.ActionText = 'Naik Sepeda'
	prompt.ObjectText = 'Mamachari (Kemudi)'
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = seat
	prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass('Humanoid')
		if humanoid then
			seat:Sit(humanoid)
		end
	end)

	return seat
end

local function makePassengerSeat(model: Model)
	local oldSeat = model:FindFirstChild('PassengerSeat')
	if oldSeat then
		oldSeat:Destroy()
	end
	local seat = Instance.new('Seat')
	seat.Name = 'PassengerSeat'
	seat.Size = Vector3.new(0.75, 0.3, 0.75)
	seat.CFrame = model:GetPivot() * CFrame.new(0, 0.55, 1.1)
	seat.Transparency = 1
	seat.Anchored = true
	seat.CanCollide = false
	seat.CanTouch = false
	seat.Parent = model
	addSitPrompt(seat, 'Bonceng Sepeda', 'Mamachari (Kursi Belakang)')
end

local function makeCollisionBody(model: Model, visualBottom: number)
	local previous = model:FindFirstChild('SolidBicycleCollider')
	if previous then
		previous:Destroy()
	end
	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local collider = Instance.new('Part')
	collider.Name = 'SolidBicycleCollider'
	collider.Size = Vector3.new(math.max(0.85, boundingSize.X * 0.8), 0.5, TARGET_LENGTH * 0.85)
	collider.CFrame = CFrame.new(boundingCFrame.X, visualBottom + 0.55, boundingCFrame.Z) * model:GetPivot().Rotation
	collider.Transparency = 1
	collider.Anchored = true
	collider.CanCollide = true
	collider.CanTouch = true
	collider.CanQuery = true
	collider.Parent = model
	model:SetAttribute('SolidVehicle', true)
end

local function configureBicycle(model: Model, parkingSlot: number?)
	local oldSeat = model:FindFirstChild('RideSeat')
	if oldSeat then
		oldSeat:Destroy()
	end

	local oldPassengerSeat = model:FindFirstChild('PassengerSeat')
	if oldPassengerSeat then
		oldPassengerSeat:Destroy()
	end
	local oldCollider = model:FindFirstChild('SolidBicycleCollider')
	if oldCollider then
		oldCollider:Destroy()
	end
	scaleGeometryToLength(model, TARGET_LENGTH)
	if parkingSlot then
		local slotX = 410 + (parkingSlot - 1) * 5.5
		local oldPivot = model:GetPivot()
		model:PivotTo(CFrame.new(slotX, oldPivot.Y, -70) * oldPivot.Rotation)
	end

	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local bottom = boundingCFrame.Y - boundingSize.Y / 2
	local currentPivot = model:GetPivot()
	local targetBottom = surfaceHeight(model, currentPivot.Position) + GROUND_CLEARANCE
	local lift = targetBottom - bottom
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position + Vector3.new(0, lift, 0)) * pivot.Rotation)
	if parkingSlot then
		model:SetAttribute('HomeFacility', 'CoveredMamachariParking')
		model:SetAttribute('ParkingSlot', parkingSlot)
	end
	local adjustedBoundingCFrame, adjustedBoundingSize = model:GetBoundingBox()
	groundOffsets[model] = model:GetPivot().Y - (adjustedBoundingCFrame.Y - adjustedBoundingSize.Y / 2)
	model:SetAttribute('BicycleVersion', BICYCLE_VERSION)
	model:SetAttribute('TargetLengthStuds', TARGET_LENGTH)
	model:SetAttribute('ActualLengthStuds', math.max(adjustedBoundingSize.X, adjustedBoundingSize.Z))
	model:SetAttribute('GroundClearanceStuds', GROUND_CLEARANCE)
	model:SetAttribute('ScaleBasis', '5.5-stud avatar')

	for _, descendant in model:GetDescendants() do
		if descendant:IsA('BasePart') then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	makeCollisionBody(model, targetBottom)
	makeSeat(model)
	makePassengerSeat(model)
	speeds[model] = 0
end

local function findRideSurface(model: Model, position: Vector3, occupant: Humanoid?): (number?, boolean)
	local exclusions = buildRaycastExclusions(model)
	if occupant and occupant.Parent then
		table.insert(exclusions, occupant.Parent)
	end
	local parameters = RaycastParams.new()
	parameters.FilterType = Enum.RaycastFilterType.Exclude
	parameters.FilterDescendantsInstances = exclusions
	parameters.IgnoreWater = true

	local origin = position + Vector3.new(0, 20, 0)
	for _ = 1, 12 do
		local result = workspace:Raycast(origin, Vector3.new(0, -80, 0), parameters)
		if not result then
			return nil, false
		end
		local hit = result.Instance
		if isOverheadPart(hit) or (hit:IsA('BasePart') and not hit.CanCollide) then
			table.insert(exclusions, hit)
			parameters.FilterDescendantsInstances = exclusions
			origin = result.Position - Vector3.new(0, 0.05, 0)
		else
			return result.Position.Y, result.Normal.Y < 0.58
		end
	end
	return nil, false
end

local function updateBicycle(model: Model, deltaTime: number)
	local seat = model:FindFirstChild('RideSeat')
	if not seat or not seat:IsA('VehicleSeat') then
		return
	end

	local speed = speeds[model] or 0
	local occupied = seat.Occupant ~= nil
	local throttle = if occupied then seat.ThrottleFloat else 0
	local steer = if occupied then seat.SteerFloat else 0

	if math.abs(throttle) > 0.05 then
		speed += throttle * ACCELERATION * deltaTime
		speed = math.clamp(speed, -TOP_SPEED * 0.35, TOP_SPEED)
	else
		local reduction = BRAKING * deltaTime
		if math.abs(speed) <= reduction then
			speed = 0
		else
			speed -= math.sign(speed) * reduction
		end
	end

	if occupied and math.abs(speed) > 0.2 then
		local turnDirection = if speed >= 0 then 1 else -1
		local yaw = -steer * TURN_RATE * turnDirection * deltaTime
		local pivot = model:GetPivot() * CFrame.Angles(0, yaw, 0)
		local displacement = pivot.LookVector * speed * deltaTime
		local horizontalPosition = pivot.Position + Vector3.new(displacement.X, 0, displacement.Z)
		local groundY, tooSteep = findRideSurface(model, horizontalPosition, seat.Occupant)
		if tooSteep then
			speed = 0
		elseif groundY then
			local nextPosition = Vector3.new(
				horizontalPosition.X,
				groundY + (groundOffsets[model] or 1) + GROUND_CLEARANCE,
				horizontalPosition.Z
			)
			model:PivotTo(CFrame.new(nextPosition) * pivot.Rotation)
		end
	end

	speeds[model] = speed
end

function BicycleService.init()
	local folder = workspace:FindFirstChild('Bicycles')
	if not folder then
		return
	end

	-- One usable mamachari per visible rack section. Clones are generated at
	-- runtime so all eight are individually rideable without bloating the place.
	for _, child in folder:GetChildren() do
		if child:IsA('Model') and child:GetAttribute('GeneratedParkingBicycle') then
			child:Destroy()
		end
	end
	local parkTemplate = folder:FindFirstChild('ParkMamachari')
	local parkingBicycles: { Model } = {}
	if parkTemplate and parkTemplate:IsA('Model') then
		table.insert(parkingBicycles, parkTemplate)
		for slot = 2, 8 do
			local clone = parkTemplate:Clone()
			clone.Name = string.format('ParkMamachari%02d', slot)
			clone:SetAttribute('GeneratedParkingBicycle', true)
			clone.Parent = folder
			table.insert(parkingBicycles, clone)
		end
	end
	for slot, bicycle in parkingBicycles do
		configureBicycle(bicycle, slot)
	end
	for _, child in folder:GetChildren() do
		if child:IsA('Model') and not table.find(parkingBicycles, child) then
			configureBicycle(child)
		end
	end

	RunService.Heartbeat:Connect(function(deltaTime)
		for model in speeds do
			if model.Parent then
				updateBicycle(model, deltaTime)
			else
				speeds[model] = nil
				groundOffsets[model] = nil
			end
		end
	end)
end

return BicycleService
