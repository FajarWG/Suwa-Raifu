--!strict

-- Clean, Natural Lie-Down & Relaxation System (Terlentang & Tengkurap)
-- Cycles through 2 relaxation poses:
--   1. Lay on Back (Terlentang) - Lying face-up looking at sky / fireworks
--   2. Lay on Stomach (Tengkurap) - Lying face-down resting comfortably
--   3. Stand Up - Returns to standing orientation

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local player = Players.LocalPlayer

local LieDownController = {}

local IDLE_TEXT = '✨ Lay Down'

type PoseInfo = {
	pitch: number,
	groundOffset: number,
	nextButtonText: string,
}

local POSES: { [string]: PoseInfo } = {
	Terlentang = {
		pitch = 90, -- Face up (looking at sky/fireworks)
		groundOffset = 0.55,
		nextButtonText = 'On Stomach',
	},
	Tengkurap = {
		pitch = -90, -- Face down (resting on stomach)
		groundOffset = 0.55,
		nextButtonText = 'Stand Up',
	},
}

local POSE_ORDER = { 'Terlentang', 'Tengkurap' }

local currentHumanoid: Humanoid? = nil
local currentRoot: BasePart? = nil
local currentPose: string? = nil
local standingCFrame: CFrame? = nil
local chillFacing: CFrame? = nil
local button: TextButton? = nil

local function isTouchDevice(): boolean
	return UserInputService.TouchEnabled or UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

local MOVE_KEYS = {
	[Enum.KeyCode.W] = true,
	[Enum.KeyCode.A] = true,
	[Enum.KeyCode.S] = true,
	[Enum.KeyCode.D] = true,
	[Enum.KeyCode.Space] = true,
	[Enum.KeyCode.Q] = true,
}

local function groundRaycastParams(character: Model): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	return params
end

local function standUp()
	if not currentPose then
		return
	end
	currentPose = nil
	local humanoid = currentHumanoid
	local root = currentRoot
	if humanoid and humanoid.Parent and root then
		if standingCFrame then
			root.CFrame = standingCFrame
		end
		root.Anchored = false
		humanoid.PlatformStand = false
	end
	standingCFrame = nil
	chillFacing = nil
	if button then
		button.Text = IDLE_TEXT
		button.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
	end
end

local function enterPose(poseName: string)
	local humanoid = currentHumanoid
	local root = currentRoot
	if not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart then
		return
	end

	local character = humanoid.Parent :: Model
	local pose = POSES[poseName]
	if not pose then
		return
	end

	if not currentPose then
		standingCFrame = root.CFrame
		local lookFlat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if lookFlat.Magnitude < 0.001 then
			lookFlat = Vector3.new(0, 0, -1)
		end
		chillFacing = CFrame.lookAt(Vector3.zero, lookFlat.Unit)
		humanoid.PlatformStand = true
	end

	local lieRotation = (chillFacing :: CFrame) * CFrame.Angles(math.rad(pose.pitch), 0, 0)

	local result = Workspace:Raycast(root.Position, Vector3.new(0, -8, 0), groundRaycastParams(character))
	local groundY = if result then result.Position.Y else (root.Position.Y - root.Size.Y / 2)

	currentPose = poseName
	root.CFrame = CFrame.new(root.Position.X, groundY + pose.groundOffset, root.Position.Z) * lieRotation
	root.Anchored = true

	if button then
		button.Text = pose.nextButtonText
		button.BackgroundColor3 = Color3.fromRGB(48, 70, 100)
	end
end

local function toggle()
	if not currentPose then
		enterPose(POSE_ORDER[1])
		return
	end
	local nextIndex = table.find(POSE_ORDER, currentPose) + 1
	local nextPose = POSE_ORDER[nextIndex]
	if nextPose then
		enterPose(nextPose)
	else
		standUp()
	end
end

local function buildButton()
	local playerGui = player:WaitForChild('PlayerGui')
	local existing = playerGui:FindFirstChild('SuwaLieDownGui')
	if existing then
		existing:Destroy()
	end

	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaLieDownGui'
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local touch = isTouchDevice()

	local btn = Instance.new('TextButton')
	btn.Name = 'LieDownButton'
	if touch then
		btn.AnchorPoint = Vector2.new(1, 0)
		btn.Position = UDim2.new(1, -14, 0, 110)
		btn.Size = UDim2.new(0, 94, 0, 36)
	else
		btn.AnchorPoint = Vector2.new(0, 0)
		btn.Position = UDim2.new(0, 120, 0, 64)
		btn.Size = UDim2.new(0, 96, 0, 36)
	end
	btn.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
	btn.BackgroundTransparency = 0.2
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(240, 244, 255)
	btn.Text = if currentPose and POSES[currentPose] then POSES[currentPose].nextButtonText else IDLE_TEXT
	btn.AutoButtonColor = true
	btn.ZIndex = 2
	btn.Parent = gui
	button = btn

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = btn

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(120, 150, 190)
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = btn

	UIScaling.fit(btn, 1.1)

	btn.MouseButton1Click:Connect(toggle)
end

local function hookCharacter(character: Model)
	currentPose = nil
	standingCFrame = nil
	chillFacing = nil
	currentHumanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	currentRoot = character:FindFirstChild('HumanoidRootPart') :: BasePart?
	if button then
		button.Text = IDLE_TEXT
		button.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
	end

	if currentHumanoid then
		(currentHumanoid :: Humanoid).Died:Connect(function()
			currentPose = nil
			standingCFrame = nil
			chillFacing = nil
			currentHumanoid = nil
		end)
	end
end

function LieDownController.init()
	buildButton()

	UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
		if lastInputType == Enum.UserInputType.Touch then
			buildButton()
		end
	end)

	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not currentPose then
			return
		end
		if MOVE_KEYS[input.KeyCode] then
			standUp()
		end
	end)
end

return LieDownController
