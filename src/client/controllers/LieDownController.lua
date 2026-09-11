--!strict

-- Clean, Natural Lie-Down & Relaxation System (Terlentang & Tengkurap)
-- Positioned cleanly in the unified Top-Right Dock.
-- Cycles through 2 relaxation poses:
--   1. Lay on Back (Terlentang) - Lying face-up looking at sky / fireworks
--   2. Lay on Stomach (Tengkurap) - Lying face-down resting comfortably
--   3. Stand Up - Returns to standing orientation

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
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
	if standUpPill then
		standUpPill.Visible = false
	end
end

local function isPlayerBusy(humanoid: Humanoid, character: Model): boolean
	if humanoid.Health <= 0 then
		return true
	end

	-- 1. Sitting or in any seat / vehicle
	local isSeated = humanoid.Sit
		or (humanoid.SeatPart ~= nil)
		or (character:FindFirstChild("SeatWeld") ~= nil)
		or (character:FindFirstChild("SitWeld") ~= nil)
	if isSeated then
		return true
	end

	-- 2. Humanoid state (Swimming, Climbing, Dead)
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Dead then
		return true
	end

	-- 3. Swimming in water material
	if humanoid.FloorMaterial == Enum.Material.Water then
		return true
	end

	-- 4. Sleeping in bed or riding vehicle attributes
	if character:GetAttribute("Sleeping") == true
		or character:GetAttribute("Riding") == true
		or character:GetAttribute("Driving") == true then
		return true
	end

	return false
end

local function enterPose(poseName: string)
	local humanoid = currentHumanoid
	local root = currentRoot
	if not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart then
		return
	end

	local character = humanoid.Parent :: Model
	if isPlayerBusy(humanoid, character) then
		return
	end

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

	local pill = getOrCreateStandUpPill()
	pill.Visible = true
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

local TextChatService = game:GetService('TextChatService')

local standUpPill: TextButton? = nil

local function getOrCreateStandUpPill(): TextButton
	if standUpPill and standUpPill.Parent then
		return standUpPill
	end
	local pill = UIDock.contextPill('Stand Up', Color3.fromRGB(48, 70, 100))
	pill.Name = 'LieDownStandUpPill'
	pill.Visible = false
	pill.Activated:Connect(function()
		standUp()
	end)
	standUpPill = pill
	return pill
end

local function setupChatCommands()
	local function onChatMessage(messageText: string)
		local clean = string.lower(string.gsub(messageText, "^%s+", ""):gsub("%s+$", ""))
		if clean == '/lay' or clean == '/sleep' or clean == '/rebahan' or clean == '/tidur' or clean == '/laydown' then
			toggle()
		elseif clean == '/stand' or clean == '/bangun' or clean == '/wake' then
			standUp()
		end
	end

	player.Chatted:Connect(onChatMessage)

	task.spawn(function()
		pcall(function()
			if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				local textChannels = TextChatService:WaitForChild('TextChannels', 5)
				if textChannels then
					local rbxGeneral = textChannels:WaitForChild('RBXGeneral', 5)
					if rbxGeneral and rbxGeneral:IsA('TextChannel') then
						rbxGeneral.MessageReceived:Connect(function(textChatMessage)
							if textChatMessage.TextSource and textChatMessage.TextSource.UserId == player.UserId then
								onChatMessage(textChatMessage.Text)
							end
						end)
					end
				end
			end
		end)
	end)
end

local function updateVisibility()
	local humanoid = currentHumanoid
	local character = if humanoid then humanoid.Parent :: Model? else nil

	if not humanoid or not character or humanoid.Health <= 0 then
		if currentPose then
			standUp()
		end
		return
	end

	local busy = isPlayerBusy(humanoid, character)
	if busy then
		if currentPose then
			standUp()
		end
	end
end

local function hookCharacter(character: Model)
	currentPose = nil
	standingCFrame = nil
	chillFacing = nil
	currentHumanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	currentRoot = character:FindFirstChild('HumanoidRootPart') :: BasePart?
	if standUpPill then
		standUpPill.Visible = false
	end

	local hum = currentHumanoid
	if hum then
		hum.Died:Connect(function()
			currentPose = nil
			standingCFrame = nil
			chillFacing = nil
			currentHumanoid = nil
			updateVisibility()
		end)

		hum.Seated:Connect(function()
			updateVisibility()
		end)

		hum.StateChanged:Connect(function()
			updateVisibility()
		end)

		hum:GetPropertyChangedSignal('Sit'):Connect(updateVisibility)
		hum:GetPropertyChangedSignal('SeatPart'):Connect(updateVisibility)
		hum:GetPropertyChangedSignal('FloorMaterial'):Connect(updateVisibility)
	end

	character:GetAttributeChangedSignal('Sleeping'):Connect(updateVisibility)
	character:GetAttributeChangedSignal('Riding'):Connect(updateVisibility)
	character:GetAttributeChangedSignal('Driving'):Connect(updateVisibility)

	character.ChildAdded:Connect(function(child)
		if child.Name:find('Seat') or child.Name:find('Weld') then
			updateVisibility()
		end
	end)

	character.ChildRemoved:Connect(function(child)
		if child.Name:find('Seat') or child.Name:find('Weld') then
			updateVisibility()
		end
	end)

	updateVisibility()
end

function LieDownController.toggle()
	toggle()
end

function LieDownController.standUp()
	standUp()
end

function LieDownController.enterPose(poseName: string)
	enterPose(poseName)
end

function LieDownController.init()
	setupChatCommands()

	-- Export globally so other controllers/UI (like Emote System) can trigger it
	_G.SuwaLieDown = {
		toggle = toggle,
		standUp = standUp,
		enterPose = enterPose,
		isLyingDown = function() return currentPose ~= nil end,
	}

	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	-- Periodic watcher to guarantee state changes are always caught (e.g. entering water without state trigger)
	task.spawn(function()
		while true do
			task.wait(0.3)
			updateVisibility()
		end
	end)

	-- Auto stand-up when player moves (virtual joystick on mobile or keyboard on PC)
	RunService.Heartbeat:Connect(function()
		if currentPose and currentHumanoid and currentHumanoid.MoveDirection.Magnitude > 0.05 then
			standUp()
		end
	end)

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
