--!strict

-- Clean, Natural Lie-Down & Relaxation System (Terlentang & Tengkurap)
-- Positioned cleanly in the unified Top-Right Dock.
-- Cycles through 2 relaxation poses:
--   1. Lay on Back (Terlentang) - Lying face-up looking at sky / fireworks
--   2. Lay on Stomach (Tengkurap) - Lying face-down resting comfortably
--   3. Stand Up - Returns to standing orientation

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local UIDock = require(script.Parent:WaitForChild('UIDock'))

local player = Players.LocalPlayer

local LieDownController = {}

local IDLE_TEXT = 'Lay Down'

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
		button.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
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

	-- 1. Top-Right Dock Button
	local btn = UIDock.pillButton(
		if currentPose and POSES[currentPose] then POSES[currentPose].nextButtonText else IDLE_TEXT,
		1
	)
	btn.Name = 'LieDownButton'
	btn.ZIndex = 2
	btn.Parent = UIDock.getTopRightRow()
	button = btn

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
		button.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
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
