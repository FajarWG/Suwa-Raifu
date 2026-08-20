--!strict

-- BoatDriveController: Client-side physics controller for lake boats.
-- Roblox transfers vehicle network ownership to the client when seated.
-- Controlling AssemblyLinearVelocity and AssemblyAngularVelocity locally ensures
-- 100% instant, butter-smooth WASD vehicle responsiveness with zero network latency.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local BoatDriveController = {}
local player = Players.LocalPlayer

local currentSeat: VehicleSeat? = nil
local currentWaterlineY: number = 1.0
local currentBaseSpeed: number = 30
local currentTurnSpeed: number = 1.5

local function onSeated(active: boolean, currentSeatPart: Instance?)
	if active and currentSeatPart and currentSeatPart:IsA("VehicleSeat") then
		local lakeCrafts = workspace:FindFirstChild("LakeCrafts")
		if lakeCrafts and currentSeatPart:IsDescendantOf(lakeCrafts) then
			currentSeat = currentSeatPart
			currentBaseSpeed = currentSeat:GetAttribute("BaseSpeed") or 30
			currentTurnSpeed = currentSeat:GetAttribute("TurnSpeed") or 1.5
			currentWaterlineY = currentSeat:GetAttribute("WaterlineY") or currentSeat.Position.Y
			return
		end
	end
	currentSeat = nil
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

	RunService.RenderStepped:Connect(function()
		if not currentSeat or not currentSeat.Parent then
			return
		end

		if currentSeat.Anchored then
			currentSeat.Anchored = false
		end

		local throttle = currentSeat.ThrottleFloat
		local steer = currentSeat.SteerFloat

		-- Direct keyboard WASD & Arrow fallback to ensure 100% reliable input
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

		local look = currentSeat.CFrame.LookVector

		-- Pure flat forward direction (zero vertical pitch)
		local flatLook = Vector3.new(look.X, 0, look.Z)
		if flatLook.Magnitude > 0.001 then
			flatLook = flatLook.Unit
		else
			flatLook = Vector3.new(0, 0, -1)
		end

		-- Buoyancy leveling to keep the boat stable on the waterline
		local yDiff = currentWaterlineY - currentSeat.Position.Y
		local buoyancyForce = math.clamp(yDiff * 12, -8, 8)

		if math.abs(throttle) > 0.05 or math.abs(steer) > 0.05 then
			local forwardSpeed = throttle * currentBaseSpeed
			local yawSpeed = -steer * currentTurnSpeed

			local targetVelocity = flatLook * forwardSpeed + Vector3.new(0, buoyancyForce, 0)
			currentSeat.AssemblyLinearVelocity = targetVelocity
			currentSeat.AssemblyAngularVelocity = Vector3.new(0, yawSpeed, 0)
		else
			-- Smooth water coasting with buoyant leveling
			local vel = currentSeat.AssemblyLinearVelocity
			currentSeat.AssemblyLinearVelocity = Vector3.new(vel.X * 0.92, buoyancyForce, vel.Z * 0.92)
			currentSeat.AssemblyAngularVelocity = Vector3.new(0, currentSeat.AssemblyAngularVelocity.Y * 0.85, 0)
		end
	end)
end

return BoatDriveController
