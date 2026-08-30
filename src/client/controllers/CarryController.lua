--!strict

-- Client side of piggyback carry: hides a player's own "Carry" prompt (so
-- nobody sees a carry prompt floating on themselves), binds X to let go while
-- carrying someone, and shows an on-screen mobile release button on touch devices.

local ContextActionService = game:GetService('ContextActionService')
local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local player = Players.LocalPlayer

local CarryController = {}

local RELEASE_ACTION = 'SuwaCarryRelease'
local PROMPT_NAME = 'CarryPrompt'

local hintGui: ScreenGui? = nil

local function isTouchDevice(): boolean
	return UserInputService.TouchEnabled or UserInputService:GetLastInputType() == Enum.UserInputType.Touch
end

local function releaseCarry()
	RemoteController.fire('CarryRelease')
end

local function setHintVisible(visible: boolean)
	if visible and not hintGui then
		local playerGui = player:WaitForChild('PlayerGui')
		local gui = Instance.new('ScreenGui')
		gui.Name = 'SuwaCarryHint'
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
		hintGui = gui

		if isTouchDevice() then
			-- Mobile Touch Button to drop/release carried player
			local dropBtn = Instance.new('TextButton')
			dropBtn.Name = 'DropButton'
			dropBtn.AnchorPoint = Vector2.new(1, 1)
			dropBtn.Position = UDim2.new(1, -24, 1, -290)
			dropBtn.Size = UDim2.new(0, 100, 0, 52)
			dropBtn.BackgroundColor3 = Color3.fromRGB(195, 55, 55)
			dropBtn.BackgroundTransparency = 0.12
			dropBtn.TextColor3 = Color3.new(1, 1, 1)
			dropBtn.Font = Enum.Font.GothamBold
			dropBtn.TextSize = 13
			dropBtn.Text = 'RELEASE 🤝'
			dropBtn.AutoButtonColor = true
			dropBtn.Parent = gui

			local corner = Instance.new('UICorner')
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = dropBtn

			local stroke = Instance.new('UIStroke')
			stroke.Color = Color3.fromRGB(255, 150, 150)
			stroke.Thickness = 1.5
			stroke.Transparency = 0.3
			stroke.Parent = dropBtn

			UIScaling.fit(dropBtn, 1.2)

			dropBtn.MouseButton1Click:Connect(function()
				releaseCarry()
			end)
		else
			-- Desktop Hint
			local label = Instance.new('TextLabel')
			label.AnchorPoint = Vector2.new(0.5, 1)
			label.Position = UDim2.new(0.5, 0, 1, -150)
			label.Size = UDim2.new(0, 260, 0, 32)
			label.BackgroundColor3 = Color3.fromRGB(25, 42, 49)
			label.BackgroundTransparency = 0.18
			label.TextColor3 = Color3.new(1, 1, 1)
			label.Font = Enum.Font.GothamBold
			label.TextScaled = true
			label.Text = 'Press X to let go  ・  降ろす'
			label.Parent = gui

			local corner = Instance.new('UICorner')
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = label
		end
	elseif not visible and hintGui then
		hintGui:Destroy()
		hintGui = nil
	end
end

local function releaseHandler(_, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		releaseCarry()
	end
	return Enum.ContextActionResult.Pass
end

local function hideOwnPrompt(character: Model)
	local root = character:WaitForChild('HumanoidRootPart', 5)
	local prompt = root and (root:FindFirstChild(PROMPT_NAME) or root:WaitForChild(PROMPT_NAME, 5))
	if prompt and prompt:IsA('ProximityPrompt') then
		prompt.Enabled = false
	end
end

local function watchForCarryWeld(character: Model)
	local root = character:WaitForChild('HumanoidRootPart', 5)
	if not root then
		return
	end
	local anchor = character:FindFirstChild('UpperTorso') or character:FindFirstChild('Torso') or root

	anchor.ChildAdded:Connect(function(child)
		if child.Name == 'CarryWeld' then
			setHintVisible(true)
			child.AncestryChanged:Connect(function(_, parent)
				if not parent then
					setHintVisible(false)
				end
			end)
		end
	end)
end

function CarryController.init()
	ContextActionService:BindAction(RELEASE_ACTION, releaseHandler, false, Enum.KeyCode.X)

	local function onCharacter(character: Model)
		setHintVisible(false)
		hideOwnPrompt(character)
		watchForCarryWeld(character)
	end

	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return CarryController
