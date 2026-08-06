--!strict

-- Lightweight arcade bicycles for the compact map. The detailed mamachari
-- meshes stay anchored and are moved as one model, which keeps them stable on
-- mobile and avoids a fragile wheel-constraint setup during this map phase.

local RunService = game:GetService('RunService')

local BICYCLE_VERSION = 2
local TARGET_LENGTH = 5
local GROUND_CLEARANCE = 0.25
local TOP_SPEED = 24
local ACCELERATION = 22
local BRAKING = 30
local TURN_RATE = math.rad(72)

local BicycleService = {}
local speeds: { [Model]: number } = {}

local function makeSeat(model: Model): VehicleSeat
	local existing = model:FindFirstChild('RideSeat')
	local seat: VehicleSeat
	if existing and existing:IsA('VehicleSeat') then
		seat = existing
	else
		seat = Instance.new('VehicleSeat')
		seat.Name = 'RideSeat'
		seat.Size = Vector3.new(1.25, 0.5, 1.4)
		seat.Color = Color3.fromRGB(38, 34, 31)
		seat.Material = Enum.Material.Leather
		seat.Transparency = 1
		seat.Anchored = true
		seat.CanCollide = false
		seat.Massless = true
		seat.CFrame = model:GetPivot() * CFrame.new(0, 0.9, 0.37)
		seat.Parent = model
	end

	local oldPrompt = seat:FindFirstChild('RidePrompt')
	if oldPrompt then
		oldPrompt:Destroy()
	end
	local prompt = Instance.new('ProximityPrompt')
	prompt.Name = 'RidePrompt'
	prompt.ActionText = 'Ride bicycle'
	prompt.ObjectText = 'Mamachari'
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

local function configureBicycle(model: Model)
	local oldSeat = model:FindFirstChild('RideSeat')
	if oldSeat then
		oldSeat:Destroy()
	end

	local _, initialSize = model:GetBoundingBox()
	if math.abs(initialSize.Z - TARGET_LENGTH) > 0.05 then
		model:ScaleTo(model:GetScale() * TARGET_LENGTH / initialSize.Z)
	end

	local boundingCFrame, boundingSize = model:GetBoundingBox()
	local bottom = boundingCFrame.Y - boundingSize.Y / 2
	local lift = GROUND_CLEARANCE - bottom
	local pivot = model:GetPivot()
	model:PivotTo(CFrame.new(pivot.Position + Vector3.new(0, lift, 0)) * pivot.Rotation)
	model:SetAttribute('BicycleVersion', BICYCLE_VERSION)

	for _, descendant in model:GetDescendants() do
		if descendant:IsA('BasePart') then
			descendant.Anchored = true
			descendant.CanCollide = false
		end
	end

	makeSeat(model)
	speeds[model] = 0
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
		local nextPosition = pivot.Position + Vector3.new(displacement.X, 0, displacement.Z)
		model:PivotTo(CFrame.new(nextPosition) * pivot.Rotation)
	end

	speeds[model] = speed
end

function BicycleService.init()
	local folder = workspace:FindFirstChild('Bicycles')
	if not folder then
		return
	end

	for _, child in folder:GetChildren() do
		if child:IsA('Model') then
			configureBicycle(child)
		end
	end

	RunService.Heartbeat:Connect(function(deltaTime)
		for model in speeds do
			if model.Parent then
				updateBicycle(model, deltaTime)
			else
				speeds[model] = nil
			end
		end
	end)
end

return BicycleService
