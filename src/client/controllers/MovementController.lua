--!strict

-- MovementController: hold Shift to run.

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

local WALK_SPEED = 16
local RUN_SPEED = 32

local player = Players.LocalPlayer
local currentHumanoid: Humanoid? = nil
local sprinting = false

local MovementController = {}

local function applySpeed()
	if not currentHumanoid then
		return
	end
	currentHumanoid.WalkSpeed = if sprinting then RUN_SPEED else WALK_SPEED
end

local function hookCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	if humanoid and humanoid:IsA('Humanoid') then
		currentHumanoid = humanoid
		applySpeed()
		humanoid.Died:Connect(function()
			sprinting = false
			currentHumanoid = nil
		end)
	end
end

function MovementController.init()
	if player.Character then
		hookCharacter(player.Character)
	end

	player.CharacterAdded:Connect(hookCharacter)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			sprinting = true
			applySpeed()
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			sprinting = false
			applySpeed()
		end
	end)
end

return MovementController
