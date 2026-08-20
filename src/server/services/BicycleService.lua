--!strict

-- BicycleService: 21 Driveable Japanese Mamachari Bicycles across 3 parking zones.
-- Features:
-- 1. Rock-solid parked state (Anchored = true while empty) -> NEVER falls through terrain.
-- 2. Smooth unanchoring when driver sits (Anchored = false) -> Instant driving.
-- 3. Strict Anti-Ghost Ride (Anchored = true + Velocity = 0 when driver exits) -> Stops on a dime.
-- 4. Dynamic chain & pedal audio based on speed.
-- 5. Anti-Cliff & Anti-Water Boundary: Automatically blocks and pushes back if driving towards cliffs, drop-offs, or lake water.
-- 6. Clean UI: ProximityPrompt (E) disappears while riding.

local RunService = game:GetService("RunService")

local BicycleService = {}
local activeBicycles: { [Model]: { seat: VehicleSeat, sound: Sound, rootPart: BasePart } } = {}

-- Anti-cliff, anti-drop-off, and anti-water boundary check
local function isCliffOrWaterAhead(bikePos: Vector3, lookVector: Vector3): boolean
	local forwardPos = bikePos + lookVector * 5.0

	-- 1. Hard perimeter check (lake shoreline is at Z = -215)
	if forwardPos.Z < -215 or forwardPos.X < -700 or forwardPos.X > 700 or forwardPos.Z > 450 then
		return true
	end

	-- 2. Raycast downward to check for solid ground and detect cliffs / water
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain, workspace }
	params.IgnoreWater = false

	local hit = workspace:Raycast(forwardPos + Vector3.new(0, 6, 0), Vector3.new(0, -18, 0), params)
	if not hit then
		-- No ground / void / cliff ahead!
		return true
	end

	if hit.Material == Enum.Material.Water then
		-- Water ahead!
		return true
	end

	-- Steep cliff / drop-off of more than 3.5 studs
	if (bikePos.Y - hit.Position.Y) > 3.5 then
		return true
	end

	return false
end

local function setupBike(bike: Model)
	local driveSeat = bike:FindFirstChildWhichIsA("VehicleSeat", true)
	local rootPart = bike.PrimaryPart or (driveSeat and driveSeat.Parent and driveSeat.Parent:FindFirstChild("RootPart")) or driveSeat

	if not driveSeat or not rootPart or not rootPart:IsA("BasePart") then
		return
	end

	bike.PrimaryPart = driveSeat

	-- Unanchor subparts and weld to driveSeat
	for _, p in ipairs(bike:GetDescendants()) do
		if p:IsA("BasePart") and p ~= driveSeat then
			p.Anchored = false
		end
	end

	-- Initially anchor while parked to prevent physics sinking or sliding
	driveSeat.Anchored = true
	driveSeat.HeadsUpDisplay = false
	driveSeat.CanTouch = false

	local existingPrompt = driveSeat:FindFirstChild("RidePrompt")
	if existingPrompt then
		existingPrompt:Destroy()
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "RidePrompt"
	prompt.ActionText = "Mengemudi"
	prompt.ObjectText = "Sepeda"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = driveSeat

	-- Show prompt only when empty
	prompt.Enabled = (driveSeat.Occupant == nil)

	-- Seat occupant state handler (Drive vs Parked)
	driveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local isOccupied = (driveSeat.Occupant ~= nil)
		prompt.Enabled = not isOccupied

		if isOccupied then
			-- Driver sat down -> Unanchor for driving
			driveSeat.Anchored = false
		else
			-- Driver exited -> Anti-Ghost Ride: Stop instantly and re-anchor
			driveSeat.AssemblyLinearVelocity = Vector3.zero
			driveSeat.AssemblyAngularVelocity = Vector3.zero
			driveSeat.Throttle = 0
			driveSeat.Steer = 0
			driveSeat.ThrottleFloat = 0
			driveSeat.SteerFloat = 0
			driveSeat.Anchored = true
		end
	end)

	prompt.Triggered:Connect(function(player)
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.SeatPart == nil and not driveSeat.Occupant then
			driveSeat:Sit(humanoid)
		end
	end)

	-- Audio setup
	local existingSound = driveSeat:FindFirstChild("BikeMovementSound")
	if existingSound then
		existingSound:Destroy()
	end

	local sound = Instance.new("Sound")
	sound.Name = "BikeMovementSound"
	sound.SoundId = "rbxassetid://6027581577"
	sound.Looped = true
	sound.Volume = 0
	sound.PlaybackSpeed = 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 5
	sound.RollOffMaxDistance = 50
	sound.Parent = driveSeat
	sound:Play()

	activeBicycles[bike] = { seat = driveSeat, sound = sound, rootPart = driveSeat }
end

function BicycleService.init()
	print("[BicycleService] Initializing 21 Mamachari Bicycles with anti-cliff protection...")

	local bicyclesFolder = workspace:FindFirstChild("Bicycles")
	if bicyclesFolder then
		for _, descendant in ipairs(bicyclesFolder:GetDescendants()) do
			if descendant:IsA("Model") and descendant:FindFirstChildWhichIsA("VehicleSeat", true) then
				local name = string.lower(descendant.Name)
				if string.find(name, "boat") or string.find(name, "fune") or string.find(name, "pontoon") or string.find(name, "speed") then
					continue
				end
				setupBike(descendant)
			end
		end
	end

	-- Runtime loop for audio and anti-cliff / anti-water boundary
	RunService.Heartbeat:Connect(function()
		for bike, data in pairs(activeBicycles) do
			local seat = data.seat
			local sound = data.sound

			if not seat or not seat.Parent then
				activeBicycles[bike] = nil
				continue
			end

			-- When empty, ensure anchored & silent
			if seat.Occupant == nil then
				if not seat.Anchored then
					seat.Anchored = true
				end
				seat.AssemblyLinearVelocity = Vector3.zero
				seat.AssemblyAngularVelocity = Vector3.zero
				sound.Volume = 0
				continue
			end

			-- While driving: Dynamic Audio
			local speed = seat.AssemblyLinearVelocity.Magnitude
			if speed > 1 then
				sound.Volume = math.clamp(speed / 24, 0.1, 0.6)
				sound.PlaybackSpeed = math.clamp(0.8 + (speed / 30), 0.8, 1.4)
			else
				sound.Volume = 0
			end

			-- Anti-Cliff & Anti-Water Boundary Check
			if speed > 0.5 or seat.Throttle ~= 0 then
				if isCliffOrWaterAhead(seat.Position, seat.CFrame.LookVector) then
					seat.AssemblyLinearVelocity = Vector3.zero
					seat.AssemblyAngularVelocity = Vector3.zero
					seat.Throttle = 0
					seat.ThrottleFloat = 0
					bike:PivotTo(bike:GetPivot() * CFrame.new(0, 0, 2.5))
				end
			end
		end
	end)
end

return BicycleService
