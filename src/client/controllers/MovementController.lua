--!strict

-- Unified Movement, Vehicle Boost & Playground Swing Controller
-- Handles:
--   - Sprint on foot (Shift on PC / "SPRINT" circle button on Mobile)
--   - Boost ONLY in actual vehicles (Shift on PC / "BOOST" circle button on Mobile)
--   - Interactive Swing pumping on Mobile ("SWING" circle button) and PC (W/S/Space)
--   - Hides action buttons when sitting on standard benches and chairs
--   - Universal Dismount when seated (X on PC / "GET OFF" or "STAND UP" on Mobile)
--   - Fully responsive across PC/Laptop, Mac, Mobile, and Tablets via UIDock.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))
local UIDock = require(script.Parent:WaitForChild('UIDock'))

local WALK_SPEED = 16
local SPRINT_SPEED = 28
local DEFAULT_FOV = 70
local SPRINT_FOV = 78

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local currentHumanoid: Humanoid? = nil
local sprinting = false
local boostSent = false

local isSwingingMobile = false
local swingPumpConnection: RBXScriptConnection? = nil

local sprintButton: TextButton? = nil
local dismountButton: TextButton? = nil

local MovementController = {}

local IDLE_COLOR = Color3.fromRGB(24, 28, 38)
local ACTIVE_COLOR = Color3.fromRGB(226, 142, 58)
local SWING_COLOR = Color3.fromRGB(48, 140, 96)
local DISMOUNT_COLOR = Color3.fromRGB(190, 50, 50)

local function isSwing(seat: (Seat | VehicleSeat)?): boolean
	if not seat then
		return false
	end
	local nameLower = seat.Name:lower()
	if nameLower:find('swing') or nameLower:find('ayun') then
		return true
	end
	local owner = seat:FindFirstAncestorWhichIsA('Model')
	if owner then
		local ownerLower = owner.Name:lower()
		if ownerLower:find('swing') or ownerLower:find('ayun') then
			return true
		end
	end
	return false
end

-- Checks if a seat belongs to a legitimate drivable vehicle (Bike, Boat, Car, etc.)
local function isActualVehicle(seat: (Seat | VehicleSeat)?): boolean
	if not seat then
		return false
	end
	if seat:IsA('Seat') or isSwing(seat) then
		return false
	end

	local seatName = seat.Name:lower()
	if seatName:find('happy') then
		return false
	end

	local owner = seat:FindFirstAncestorWhichIsA('Model')
	if not owner then
		return false
	end

	local ownerName = owner.Name:lower()
	if
		ownerName:find('bench')
		or ownerName:find('chair')
		or ownerName:find('ferris')
		or ownerName:find('merry')
		or ownerName:find('arena')
		or ownerName:find('table')
	then
		return false
	end

	if
		owner:GetAttribute('Vehicle')
		or owner:GetAttribute('SuwaRigged')
		or owner:GetAttribute('SuwaBicycle')
		or owner:FindFirstAncestor('LakeCrafts')
		or owner:FindFirstAncestor('Vehicles')
	then
		return true
	end

	if
		ownerName:find('boat')
		or ownerName:find('bike')
		or ownerName:find('bicycle')
		or ownerName:find('fune')
		or ownerName:find('car')
		or ownerName:find('craft')
		or ownerName:find('swan')
		or ownerName:find('duck')
		or ownerName:find('jetski')
		or ownerName:find('ship')
	then
		return true
	end

	return false
end

local function pushBoost(value: boolean)
	if boostSent == value then
		return
	end
	boostSent = value
	RemoteController.fire('VehicleBoost', value)
end

local function updateButtonStates()
	local humanoid = currentHumanoid
	local seatPart = humanoid and humanoid.SeatPart
	local isSeated = humanoid ~= nil and seatPart ~= nil
	local onVehicle = isSeated and isActualVehicle(seatPart)
	local onSwing = isSeated and isSwing(seatPart)

	if sprintButton then
		if onVehicle then
			-- Sitting in an actual vehicle: Show BOOST button
			sprintButton.Visible = true
			sprintButton.Text = 'BOOST'
			sprintButton.BackgroundColor3 = if sprinting then ACTIVE_COLOR else Color3.fromRGB(40, 48, 68)
		elseif onSwing then
			-- Sitting on a swing: Show SWING button for mobile pumping
			sprintButton.Visible = true
			sprintButton.Text = 'SWING'
			sprintButton.BackgroundColor3 = if isSwingingMobile then ACTIVE_COLOR else SWING_COLOR
		elseif isSeated then
			-- Sitting on a regular bench or chair: Hide button
			sprintButton.Visible = false
		else
			-- On foot: Show SPRINT button
			sprintButton.Visible = true
			sprintButton.Text = 'SPRINT'
			sprintButton.BackgroundColor3 = if sprinting then ACTIVE_COLOR else IDLE_COLOR
		end
	end

	if dismountButton then
		dismountButton.Visible = isSeated == true
		if isSeated then
			dismountButton.Text = if onVehicle then 'GET OFF' else 'STAND UP'
		end
	end
end

local function startSwingPump()
	isSwingingMobile = true
	updateButtonStates()

	local humanoid = currentHumanoid
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:IsA('VehicleSeat') then
		local pumpDir = 1
		local lastSwitch = tick()
		if swingPumpConnection then
			swingPumpConnection:Disconnect()
		end
		swingPumpConnection = RunService.Heartbeat:Connect(function()
			if not isSwingingMobile or not currentHumanoid or currentHumanoid.SeatPart ~= seat then
				if swingPumpConnection then
					swingPumpConnection:Disconnect()
					swingPumpConnection = nil
				end
				return
			end
			if tick() - lastSwitch > 0.75 then
				pumpDir = -pumpDir
				lastSwitch = tick()
			end
			pcall(function()
				seat.ThrottleFloat = pumpDir
			end)
		end)
	end
end

local function stopSwingPump()
	isSwingingMobile = false
	if swingPumpConnection then
		swingPumpConnection:Disconnect()
		swingPumpConnection = nil
	end
	local humanoid = currentHumanoid
	local seat = humanoid and humanoid.SeatPart
	if seat and seat:IsA('VehicleSeat') then
		pcall(function()
			seat.ThrottleFloat = 0
		end)
	end
	updateButtonStates()
end

local function applySprint()
	local humanoid = currentHumanoid
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	local seatPart = humanoid.SeatPart
	if seatPart then
		if isActualVehicle(seatPart) then
			pushBoost(sprinting)
		else
			pushBoost(false)
		end
		updateButtonStates()
		return
	end

	pushBoost(false)
	humanoid.WalkSpeed = if sprinting then SPRINT_SPEED else WALK_SPEED
	updateButtonStates()
end

local function setSprinting(value: boolean)
	if sprinting == value then
		return
	end
	sprinting = value
	if sprintButton then
		sprintButton.BackgroundColor3 = if value then ACTIVE_COLOR else IDLE_COLOR
	end
	applySprint()
end

local function dismountCurrentSeat()
	stopSwingPump()
	local humanoid = currentHumanoid
	if humanoid and humanoid.SeatPart then
		humanoid.Sit = false
	end
end

--=============================================================================
-- Mobile UI Builder (Touch Devices Only)
--=============================================================================

local function buildMobileUI()
	if not UIScaling.isTouch() then
		return
	end

	if sprintButton then
		return
	end

	-- 1. Sprint / Boost / Swing Circular Action Button
	local button = UIDock.roundButton('SPRINT', 2, IDLE_COLOR)
	button.Name = 'SprintButton'
	button.Parent = UIDock.getBottomActionRow()
	sprintButton = button

	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			local humanoid = currentHumanoid
			local seatPart = humanoid and humanoid.SeatPart
			if seatPart and isSwing(seatPart) then
				startSwingPump()
			else
				setSprinting(true)
			end
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if isSwingingMobile then
				stopSwingPump()
			else
				setSprinting(false)
			end
		end
	end)

	-- 2. Universal Dismount Button
	local exitBtn = UIDock.contextPill('STAND UP', DISMOUNT_COLOR)
	exitBtn.Name = 'DismountButton'
	exitBtn.Visible = false
	dismountButton = exitBtn

	exitBtn.Activated:Connect(function()
		dismountCurrentSeat()
	end)

	updateButtonStates()
end

--=============================================================================

local function executeJump()
	local humanoid = currentHumanoid
	if not humanoid or humanoid.SeatPart or humanoid.Health <= 0 then
		return
	end
	humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end

local function hookCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	if not (humanoid and humanoid:IsA('Humanoid')) then
		return
	end
	currentHumanoid = humanoid
	boostSent = false
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 50
	applySprint()
	updateButtonStates()

	humanoid:GetPropertyChangedSignal('SeatPart'):Connect(function()
		if not humanoid.SeatPart then
			stopSwingPump()
			humanoid.UseJumpPower = true
			humanoid.JumpPower = 50
		end
		applySprint()
		updateButtonStates()
	end)

	local lastTrampolineBounce = 0
	local trampolineCombo = 1
	local trampolineConnection: RBXScriptConnection? = nil

	trampolineConnection = RunService.Heartbeat:Connect(function()
		local root = character:FindFirstChild('HumanoidRootPart') :: BasePart?
		if not root or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then
			return
		end

		-- Trampolines in playground
		local pg = Workspace:FindFirstChild('SuwaLakesidePark')
			and Workspace.SuwaLakesidePark:FindFirstChild('SuwaLakesidePlayground')
		if not pg then
			return
		end

		local playerPos = root.Position
		for _, model in ipairs(pg:GetChildren()) do
			if model.Name:find('Trampoline') then
				local mat = model:FindFirstChild('JumpMat') :: BasePart?
				if mat then
					local matPos = mat.Position
					local distXZ = Vector2.new(playerPos.X - matPos.X, playerPos.Z - matPos.Z).Magnitude
					local distY = playerPos.Y - matPos.Y

					-- Inside trampoline radius and on/near top of mat
					if distXZ < 8.2 and distY >= 0.5 and distY <= 4.8 and root.AssemblyLinearVelocity.Y <= 15 then
						local now = tick()
						if now - lastTrampolineBounce > 0.20 then
							if now - lastTrampolineBounce < 2.5 then
								trampolineCombo = math.min(trampolineCombo + 1, 4)
							else
								trampolineCombo = 1
							end
							lastTrampolineBounce = now

							local bouncePower = 95 + (trampolineCombo - 1) * 20
							humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
							root.AssemblyLinearVelocity = Vector3.new(
								root.AssemblyLinearVelocity.X * 0.5,
								bouncePower,
								root.AssemblyLinearVelocity.Z * 0.5
							)

							-- Sound & Visual effect
							local snd = mat:FindFirstChild('BoingSound') :: Sound?
							if snd then
								snd.PlaybackSpeed = 0.88 + trampolineCombo * 0.08
								snd:Play()
							end
							local particles = mat:FindFirstChild('BounceParticles') :: ParticleEmitter?
							if particles then
								particles:Emit(15 + trampolineCombo * 5)
							end
						end
					end
				end
			end
		end
	end)

	humanoid.Died:Connect(function()
		if trampolineConnection then
			trampolineConnection:Disconnect()
			trampolineConnection = nil
		end
		stopSwingPump()
		setSprinting(false)
		currentHumanoid = nil
		updateButtonStates()
	end)
end

function MovementController.isSprinting(): boolean
	return sprinting
end

function MovementController.init()
	camera = Workspace.CurrentCamera

	if UIScaling.isTouch() then
		buildMobileUI()
	end

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		if lastInputType == Enum.UserInputType.Touch and not sprintButton then
			buildMobileUI()
		end
	end)

	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if
			input.KeyCode == Enum.KeyCode.LeftShift
			or input.KeyCode == Enum.KeyCode.RightShift
			or input.KeyCode == Enum.KeyCode.ButtonL2
		then
			setSprinting(true)
		elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Q then
			executeJump()
		elseif input.KeyCode == Enum.KeyCode.X then
			dismountCurrentSeat()
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if
			input.KeyCode == Enum.KeyCode.LeftShift
			or input.KeyCode == Enum.KeyCode.RightShift
			or input.KeyCode == Enum.KeyCode.ButtonL2
		then
			setSprinting(false)
		end
	end)

	RunService.RenderStepped:Connect(function()
		local humanoid = currentHumanoid
		if not humanoid or humanoid.SeatPart or not camera then
			return
		end
		local moving = humanoid.MoveDirection.Magnitude > 0.1
		local target = if sprinting and moving then SPRINT_FOV else DEFAULT_FOV
		if math.abs(camera.FieldOfView - target) > 0.1 then
			camera.FieldOfView += (target - camera.FieldOfView) * 0.15
		end
	end)
end

return MovementController
