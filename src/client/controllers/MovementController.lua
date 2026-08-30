--!strict

-- Unified Movement & Vehicle Boost Controller
-- Handles:
--   - Sprint on foot (Shift on PC / "SPRINT" circle button on Mobile)
--   - Boost in vehicle (Shift on PC / "BOOST" circle button on Mobile)
--   - Universal Dismount when seated (X on PC / "GET OFF" on Mobile)
--   - Responsive across PC/Laptop, Mac, Mobile, and Tablets via UIDock.

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

local sprintButton: TextButton? = nil
local dismountButton: TextButton? = nil

local MovementController = {}

local IDLE_COLOR = Color3.fromRGB(24, 28, 38)
local ACTIVE_COLOR = Color3.fromRGB(226, 142, 58)
local DISMOUNT_COLOR = Color3.fromRGB(190, 50, 50)

local function pushBoost(value: boolean)
	if boostSent == value then
		return
	end
	boostSent = value
	RemoteController.fire('VehicleBoost', value)
end

local function updateButtonStates()
	local humanoid = currentHumanoid
	local isSeated = humanoid ~= nil and humanoid.SeatPart ~= nil

	if sprintButton then
		if isSeated then
			sprintButton.Text = 'BOOST'
			sprintButton.BackgroundColor3 = if sprinting then ACTIVE_COLOR else Color3.fromRGB(40, 48, 68)
		else
			sprintButton.Text = 'SPRINT'
			sprintButton.BackgroundColor3 = if sprinting then ACTIVE_COLOR else IDLE_COLOR
		end
	end

	if dismountButton then
		dismountButton.Visible = isSeated == true
		if isSeated and humanoid and humanoid.SeatPart then
			dismountButton.Text = 'GET OFF'
		end
	end
end

local function applySprint()
	local humanoid = currentHumanoid
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if humanoid.SeatPart then
		pushBoost(sprinting)
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

	-- 1. Sprint / Boost Circular Action Button — rightmost slot in the shared
	-- bottom action row, right next to BicycleController's Hop button.
	local button = UIDock.roundButton('SPRINT', 2, IDLE_COLOR)
	button.Name = 'SprintButton'
	button.Parent = UIDock.getBottomActionRow()
	sprintButton = button

	button.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setSprinting(true)
		end
	end)
	button.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			setSprinting(false)
		end
	end)

	-- 2. Universal Dismount Button — the shared bottom stack's context slot,
	-- which sits above the action row only while it's Visible.
	local exitBtn = UIDock.contextPill('GET OFF', DISMOUNT_COLOR)
	exitBtn.Name = 'DismountButton'
	exitBtn.Visible = false
	dismountButton = exitBtn

	exitBtn.MouseButton1Click:Connect(function()
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
			humanoid.UseJumpPower = true
			humanoid.JumpPower = 50
		end
		applySprint()
		updateButtonStates()
	end)

	humanoid.Died:Connect(function()
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
