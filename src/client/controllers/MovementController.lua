--!strict

-- MovementController: hold Shift to run on desktop, or hold the on-screen
-- Sprint button on touch devices. While seated in a vehicle the same control
-- becomes a speed boost, since phones have no Shift key either way.

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local ProximityPromptService = game:GetService('ProximityPromptService')

local WALK_SPEED = 16
local RUN_SPEED = 32

local player = Players.LocalPlayer
local currentHumanoid: Humanoid? = nil
local sprinting = false

local MovementController = {}

local function vehicleControl()
	-- Resolved lazily: both controllers are loaded by the same runner pass.
	local module = script.Parent:FindFirstChild('VehicleControlController')
	return if module then require(module) :: any else nil
end

local function applySpeed()
	local humanoid = currentHumanoid
	if not humanoid then
		return
	end

	if humanoid.SeatPart then
		-- Seated: the same control becomes the vehicle boost. This has to go
		-- over a remote; a client-set attribute never reaches the server.
		local control = vehicleControl()
		if control then
			control.setBoost(sprinting)
		end
		return
	end
	humanoid.WalkSpeed = if sprinting then RUN_SPEED else WALK_SPEED
end

local function setSprinting(value: boolean)
	if sprinting == value then
		return
	end
	sprinting = value
	applySpeed()
end

-- Touch devices get a real button; there is no Shift to hold.
local function buildTouchButton()
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
	-- Clear of the jump button, which sits at the bottom-right on touch.
	button.Position = UDim2.new(1, -30, 1, -180)
	button.Size = UDim2.new(0, 96, 0, 96)
	button.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
	button.BackgroundTransparency = 0.25
	button.Text = 'SPRINT'
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.AutoButtonColor = false
	button.Parent = gui

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 190, 120)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = button

	local function press()
		setSprinting(true)
		button.BackgroundColor3 = Color3.fromRGB(80, 62, 34)
		stroke.Transparency = 0
	end
	local function release()
		setSprinting(false)
		button.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
		stroke.Transparency = 0.3
	end

	button.MouseButton1Down:Connect(press)
	button.MouseButton1Up:Connect(release)
	button.MouseLeave:Connect(release)
	button.TouchLongPress:Connect(press)
end

local function hookCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	if not (humanoid and humanoid:IsA('Humanoid')) then
		return
	end
	currentHumanoid = humanoid
	applySpeed()

	-- Hide prompts while seated so they do not overlap the ride.
	local function syncPrompts()
		ProximityPromptService.Enabled = humanoid.SeatPart == nil
		-- Re-apply, since seated and walking use the control differently.
		applySpeed()
	end
	humanoid:GetPropertyChangedSignal('SeatPart'):Connect(syncPrompts)
	syncPrompts()

	humanoid.Died:Connect(function()
		sprinting = false
		currentHumanoid = nil
		ProximityPromptService.Enabled = true
	end)
end

function MovementController.init()
	buildTouchButton()

	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			setSprinting(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			setSprinting(false)
		end
	end)
end

return MovementController
