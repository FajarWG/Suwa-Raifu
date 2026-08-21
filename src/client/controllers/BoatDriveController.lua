--!strict

-- BoatDriveController: Pure, smooth, responsive boat controller.
-- Uses physical BodyGyro and BodyPosition to lock height and orientation without physics explosions.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local PhysicsService = game:GetService("PhysicsService")

local function safeRegisterCollisionGroup(name: string)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

safeRegisterCollisionGroup("BoatDecks")
safeRegisterCollisionGroup("SeatedAvatars")

pcall(function()
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
local currentInitPitch: number = 0
local currentInitRoll: number = 0

local currentGyro: BodyGyro? = nil
local currentPos: BodyPosition? = nil

local ISLAND_CENTER = Vector3.new(0, 0, -610)

local function getTerrainHeight(x: number, z: number): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Terrain}
	params.IgnoreWater = true
	local res = workspace:Raycast(Vector3.new(x, 80, z), Vector3.new(0, -180, 0), params)
	return if res then res.Position.Y else -10
end

local function getOrCreateMovers(seat: VehicleSeat): (BodyGyro, BodyPosition)
	local bg = seat:FindFirstChild("BoatGyro") :: BodyGyro?
	if not bg then
		bg = Instance.new("BodyGyro")
		bg.Name = "BoatGyro"
		bg.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
		bg.P = 12000
		bg.D = 800
		local initPitch, y, initRoll = seat.CFrame:ToOrientation()
		bg.CFrame = CFrame.fromOrientation(initPitch, y, initRoll)
		bg.Parent = seat
	end

	local bp = seat:FindFirstChild("BoatPosition") :: BodyPosition?
	if not bp then
		bp = Instance.new("BodyPosition")
		bp.Name = "BoatPosition"
		bp.MaxForce = Vector3.new(0, 1e7, 0)
		bp.P = 15000
		bp.D = 1000
		bp.Position = Vector3.new(seat.Position.X, currentWaterlineY, seat.Position.Z)
		bp.Parent = seat
	end

	return bg, bp
end

local function onSeated(active: boolean, currentSeatPart: Instance?)
	local char = player.Character
	if active and currentSeatPart then
		local lakeCrafts = workspace:FindFirstChild("LakeCrafts")
		if lakeCrafts and currentSeatPart:IsDescendantOf(lakeCrafts) then
			-- Immediately disable avatar collisions before SeatWeld is created
			-- to prevent fling/rejection from boat hull or water surface.
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then
						pcall(function()
							p.CollisionGroup = "SeatedAvatars"
							p.CanCollide = false
							-- Disable fluid forces on character to prevent buoyancy
							-- from flinging the boat assembly upward
							p.EnableFluidForces = false
						end)
					end
				end
			end

			if currentSeatPart:IsA("VehicleSeat") then
				currentSeat = currentSeatPart
				currentBaseSpeed = currentSeat:GetAttribute("BaseSpeed") or 30
				currentTurnSpeed = currentSeat:GetAttribute("TurnSpeed") or 1.5
				currentWaterlineY = currentSeat:GetAttribute("WaterlineY") or currentSeat.Position.Y
				
				local pitch, yaw, roll = currentSeat.CFrame:ToOrientation()
				currentYaw = yaw
				currentInitPitch = currentSeat:GetAttribute("InitPitch") or pitch
				currentInitRoll = currentSeat:GetAttribute("InitRoll") or roll

				currentGyro, currentPos = getOrCreateMovers(currentSeat)
				if currentGyro then
					currentGyro.MaxTorque = Vector3.new(1e7, 1e7, 1e7)
					currentGyro.CFrame = CFrame.fromOrientation(currentInitPitch, currentYaw, currentInitRoll)
				end
				if currentPos then
					currentPos.MaxForce = Vector3.new(0, 1e7, 0)
					currentPos.Position = Vector3.new(currentSeat.Position.X, currentWaterlineY, currentSeat.Position.Z)
				end
				return
			end
		end
	else
		-- Player berdiri dari perahu.
		-- JANGAN set CanCollide = true dari client! Server (LakeActivityService) yang
		-- restore collision group ke "Default" via Occupant changed signal.
		-- Kalau client juga set CanCollide=true, bisa race condition / fling saat
		-- player langsung naik perahu lagi sebelum server selesai reset.
		if char then
			for _, p in ipairs(char:GetDescendants()) do
				if p:IsA("BasePart") then
					pcall(function()
						p.CollisionGroup = "Default"
						-- Note: CanCollide sengaja TIDAK di-set di sini.
						-- Server yang handle via LakeActivityService Occupant changed.
						-- Restore fluid forces when exiting boat
						p.EnableFluidForces = true
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
			currentGyro.CFrame = CFrame.fromOrientation(currentInitPitch, currentYaw, currentInitRoll)
		end
		if currentPos then
			currentPos.Position = Vector3.new(currentSeat.Position.X, currentWaterlineY, currentSeat.Position.Z)
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

		-- Boundary Check (Lookahead)
		-- if targetVelocity.Magnitude > 0.1 then
		-- 	local lookAhead = targetVelocity.Unit * math.max(3, targetVelocity.Magnitude * 0.25)
		-- 	local pos = currentSeat.Position
		-- 	local nextPos = pos + lookAhead
		-- 	local nextTHeight = getTerrainHeight(nextPos.X, nextPos.Z)
		-- 	local nextDist = (Vector3.new(nextPos.X, 0, nextPos.Z) - Vector3.new(ISLAND_CENTER.X, 0, ISLAND_CENTER.Z)).Magnitude
		-- 	
		-- 	if nextDist > 750 or nextTHeight > -1.5 then
		-- 		targetVelocity = Vector3.zero
		-- 	end
		-- end

		-- Preserve Y linear velocity (for BodyPosition)
		local currentVel = currentSeat.AssemblyLinearVelocity
		currentSeat.AssemblyLinearVelocity = Vector3.new(targetVelocity.X, currentVel.Y, targetVelocity.Z)
	end)
end

return BoatDriveController
