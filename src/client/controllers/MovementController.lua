--!strict

-- Unified Mobile Controls & Movement Controller (English & Japanese)
-- Handles:
--   - Sprint on foot (Shift on PC / "SPRINT 🏃" on Mobile)
--   - Boost in vehicle (Shift on PC / "BOOST ⚡" on Mobile)
--   - Universal Dismount when seated (X on PC / "GET OFF 🚪" on Mobile)

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

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
local mobileGui: ScreenGui? = nil

local MovementController = {}

local IDLE_COLOR = Color3.fromRGB(38, 44, 56)
local ACTIVE_COLOR = Color3.fromRGB(226, 142, 58)
local DISMOUNT_COLOR = Color3.fromRGB(190, 50, 50)

local function isTouchDevice(): boolean
	return UserInputService.TouchEnabled or UserInputService:GetLastInputType() == Enum.UserInputType.Touch
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
	local isSeated = humanoid ~= nil and humanoid.SeatPart ~= nil

	if sprintButton then
		if isSeated then
			sprintButton.Text = 'BOOST ⚡'
			sprintButton.BackgroundColor3 = if sprinting then ACTIVE_COLOR else Color3.fromRGB(48, 54, 72)
		else
			sprintButton.Text = 'SPRINT 🏃'
			sprintButton.BackgroundColor3 = if sprinting then ACTIVE_COLOR else IDLE_COLOR
		end
	end

	if dismountButton then
		dismountButton.Visible = isSeated == true
		if isSeated and humanoid and humanoid.SeatPart then
			local isBike = humanoid.SeatPart:GetAttribute('SuwaBicycle') or humanoid.SeatPart.Name:lower():find('bike') ~= nil
			dismountButton.Text = if isBike then 'GET OFF 🚲' else 'GET OFF 🚪'
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
-- Mobile UI Builder
--=============================================================================

local function buildMobileUI()
	local playerGui = player:WaitForChild('PlayerGui')
	if playerGui:FindFirstChild('SuwaMobileMovementGui') then
		return
	end

	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaMobileMovementGui'
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	mobileGui = gui

	-- 1. Sprint / Boost Button
	local button = Instance.new('TextButton')
	button.Name = 'SprintButton'
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.new(1, -24, 1, -190)
	button.Size = UDim2.new(0, 84, 0, 84)
	button.BackgroundColor3 = IDLE_COLOR
	button.BackgroundTransparency = 0.15
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = 'SPRINT 🏃'
	button.AutoButtonColor = false
	button.Parent = gui
	sprintButton = button

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 210, 160)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = button

	UIScaling.fit(button, 1.2)

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

	-- 2. Universal Dismount Button (visible when seated)
	local exitBtn = Instance.new('TextButton')
	exitBtn.Name = 'DismountButton'
	exitBtn.AnchorPoint = Vector2.new(1, 1)
	exitBtn.Position = UDim2.new(1, -24, 1, -290)
	exitBtn.Size = UDim2.new(0, 94, 0, 48)
	exitBtn.BackgroundColor3 = DISMOUNT_COLOR
	exitBtn.BackgroundTransparency = 0.12
	exitBtn.Font = Enum.Font.GothamBold
	exitBtn.TextSize = 12
	exitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	exitBtn.Text = 'GET OFF 🚪'
	exitBtn.Visible = false
	exitBtn.AutoButtonColor = true
	exitBtn.Parent = gui
	dismountButton = exitBtn

	local exitCorner = Instance.new('UICorner')
	exitCorner.CornerRadius = UDim.new(0, 10)
	exitCorner.Parent = exitBtn

	local exitStroke = Instance.new('UIStroke')
	exitStroke.Color = Color3.fromRGB(255, 140, 140)
	exitStroke.Thickness = 1.5
	exitStroke.Transparency = 0.3
	exitStroke.Parent = exitBtn

	UIScaling.fit(exitBtn, 1.1)

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

	if isTouchDevice() then
		buildMobileUI()
	end

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		if lastInputType == Enum.UserInputType.Touch and not mobileGui then
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
