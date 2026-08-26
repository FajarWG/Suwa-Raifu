--!strict

-- One sprint control for the whole game.
--
-- On foot it raises WalkSpeed and widens the FOV. Seated in any driver seat —
-- bicycle, Fune, speedboat — the same control becomes the vehicle boost and
-- goes to the server over a remote, because an attribute set on the client
-- never replicates upwards.
--
-- Keyboard has Shift, gamepad has L2, and touch devices get a real on-screen
-- SPRINT button: they have no Shift to hold, so without it phone players had
-- no way to go fast at all.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))

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

local MovementController = {}

local IDLE_COLOR = Color3.fromRGB(38, 44, 56)
local ACTIVE_COLOR = Color3.fromRGB(226, 142, 58)

-- Only ever announce a change, so holding the button does not spend the
-- player's remote rate limit on identical messages.
local function pushBoost(value: boolean)
	if boostSent == value then
		return
	end
	boostSent = value
	RemoteController.fire('VehicleBoost', value)
end

local function applySprint()
	local humanoid = currentHumanoid
	if not humanoid or humanoid.Health <= 0 then
		return
	end

	if humanoid.SeatPart then
		pushBoost(sprinting)
		return
	end

	pushBoost(false)
	humanoid.WalkSpeed = if sprinting then SPRINT_SPEED else WALK_SPEED
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

--=============================================================================
-- Touch sprint button
--=============================================================================

local function buildSprintButton()
	if not UserInputService.TouchEnabled then
		return
	end
	local playerGui = player:WaitForChild('PlayerGui')
	if playerGui:FindFirstChild('SuwaSprintGui') then
		return
	end

	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaSprintGui'
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local button = Instance.new('TextButton')
	button.Name = 'SprintButton'
	button.AnchorPoint = Vector2.new(1, 1)
	-- Sits above and left of the default touch jump button.
	button.Position = UDim2.new(1, -34, 1, -196)
	button.Size = UDim2.new(0, 88, 0, 88)
	button.BackgroundColor3 = IDLE_COLOR
	button.BackgroundTransparency = 0.15
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = 'SPRINT'
	button.AutoButtonColor = false
	button.Parent = gui
	sprintButton = button

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 210, 160)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = button

	-- Held, not toggled: press and hold to keep going fast, the same as Shift.
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

	humanoid:GetPropertyChangedSignal('SeatPart'):Connect(function()
		if not humanoid.SeatPart then
			humanoid.UseJumpPower = true
			humanoid.JumpPower = 50
		end
		applySprint()
	end)

	humanoid.Died:Connect(function()
		setSprinting(false)
		currentHumanoid = nil
	end)
end

function MovementController.isSprinting(): boolean
	return sprinting
end

function MovementController.init()
	camera = Workspace.CurrentCamera
	buildSprintButton()

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
