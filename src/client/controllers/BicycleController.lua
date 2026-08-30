--!strict

-- Rider-side bicycle controls, the on-mount help card, and the wheel spin.
--
--   W A S D   ride and steer (VehicleSeat handles this natively)
--   Shift     sprint boost (MovementController owns this control)
--   Space/Q   bunny hop — lifts the front wheel
--   E / X     get off (MovementController manages the universal dismount button)
--
-- On mobile (touch devices), HOP appears cleanly beside Sprint in the action zone.

local ContextActionService = game:GetService('ContextActionService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))
local UIDock = require(script.Parent:WaitForChild('UIDock'))

local player = Players.LocalPlayer

local BicycleController = {}

local HOP_ACTION = 'SuwaBikeHop'
local DISMOUNT_ACTION = 'SuwaBikeDismount'
local CARD_SECONDS = 5

local currentSeat: VehicleSeat? = nil
local currentHumanoid: Humanoid? = nil
local mountedAt = 0
local screenGui: ScreenGui? = nil
local dismissThread: thread? = nil
local hopButton: TextButton? = nil

type WheelState = {
	collider: BasePart,
	seat: BasePart,
	radius: number,
	sign: number,
	angle: number,
	last: Vector3,
}

local wheels: { [Motor6D]: WheelState } = {}

local KEY_ROWS = {
	{ key = 'W A S D', desc = 'Ride & steer  ・  走る・曲がる' },
	{ key = 'Shift', desc = 'Sprint boost  ・  ダッシュ' },
	{ key = 'Space / Q', desc = 'Bunny hop  ・  ジャンプ' },
	{ key = 'E  /  X', desc = 'Get off  ・  降りる' },
}

local TOUCH_ROWS = {
	{ key = 'Joystick', desc = 'Ride & steer  ・  走る・曲がる' },
	{ key = 'BOOST', desc = 'Pedal fast  ・  ダッシュ' },
	{ key = 'HOP', desc = 'Bunny hop  ・  ジャンプ' },
	{ key = 'GET OFF', desc = 'Get off  ・  降りる' },
}

--=============================================================================
-- Help card
--=============================================================================

local function hideCard()
	if dismissThread then
		pcall(task.cancel, dismissThread)
		dismissThread = nil
	end
	local gui = screenGui
	if not gui then
		return
	end
	screenGui = nil

	local card = gui:FindFirstChild('Card')
	if card and card:IsA('Frame') then
		local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(card, info, { BackgroundTransparency = 1 }):Play()
		for _, child in card:GetDescendants() do
			if child:IsA('TextLabel') then
				TweenService:Create(child, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif child:IsA('UIStroke') then
				TweenService:Create(child, info, { Transparency = 1 }):Play()
			end
		end
	end
	task.delay(0.35, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

local function showCard()
	hideCard()
	local playerGui = player:WaitForChild('PlayerGui')
	local rows = if UIScaling.isTouch() then TOUCH_ROWS else KEY_ROWS

	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaBicycleHelp'
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.Parent = playerGui
	screenGui = gui

	local card = Instance.new('Frame')
	card.Name = 'Card'
	card.AnchorPoint = Vector2.new(0.5, 1)
	card.Position = if UIScaling.isTouch() then UDim2.new(0.5, 0, 1, -118) else UDim2.new(0.5, 0, 1, -28)
	card.Size = UDim2.new(0, 400, 0, 44 + #rows * 24)
	card.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.Parent = gui

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = card

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 190, 120)
	stroke.Thickness = 1.2
	stroke.Transparency = 1
	stroke.Parent = card
	UIScaling.fit(card)

	local labels: { TextLabel } = {}

	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Position = UDim2.new(0, 16, 0, 8)
	title.Size = UDim2.new(1, -32, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 13
	title.TextColor3 = Color3.fromRGB(255, 214, 150)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTransparency = 1
	title.Text = 'MAMACHARI BICYCLE  ・  ママチャリ'
	title.Parent = card
	table.insert(labels, title)

	for index, row in rows do
		local y = 32 + (index - 1) * 24

		local key = Instance.new('TextLabel')
		key.Position = UDim2.new(0, 16, 0, y)
		key.Size = UDim2.new(0, 106, 0, 18)
		key.BackgroundColor3 = Color3.fromRGB(36, 40, 48)
		key.BackgroundTransparency = 1
		key.Font = Enum.Font.GothamBold
		key.TextSize = 10
		key.TextColor3 = Color3.fromRGB(240, 210, 170)
		key.Text = row.key
		key.Parent = card
		table.insert(labels, key)

		local keyCorner = Instance.new('UICorner')
		keyCorner.CornerRadius = UDim.new(0, 4)
		keyCorner.Parent = key

		local desc = Instance.new('TextLabel')
		desc.Position = UDim2.new(0, 130, 0, y)
		desc.Size = UDim2.new(1, -146, 0, 18)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 11
		desc.TextColor3 = Color3.fromRGB(226, 232, 240)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextTransparency = 1
		desc.Text = row.desc
		desc.Parent = card
		table.insert(labels, desc)
	end

	local info = TweenInfo.new(0.3)
	TweenService:Create(card, info, { BackgroundTransparency = 0.15 }):Play()
	TweenService:Create(stroke, info, { Transparency = 0.3 }):Play()
	for _, label in labels do
		TweenService:Create(label, info, {
			TextTransparency = 0,
			BackgroundTransparency = if label.BackgroundTransparency < 1 then 0.35 else 1,
		}):Play()
	end

	dismissThread = task.delay(CARD_SECONDS, hideCard)
end

--=============================================================================
-- Wheel spin
--=============================================================================

local function registerWheel(motor: Motor6D)
	if wheels[motor] or motor.Name ~= 'WheelMotor' then
		return
	end
	local collider = motor.Part0
	if not collider then
		return
	end
	local model = motor:FindFirstAncestorOfClass('Model')
	local seat = model and model:FindFirstChildWhichIsA('VehicleSeat', true)
	if not seat then
		return
	end

	wheels[motor] = {
		collider = collider,
		seat = seat,
		radius = motor:GetAttribute('WheelRadius') :: number? or 1.4,
		sign = motor:GetAttribute('SpinSign') :: number? or 1,
		angle = 0,
		last = collider.Position,
	}
end

local MAX_ROLL_SPEED = 200

local function rollWheels(delta: number)
	for motor, state in wheels do
		if not motor.Parent or not state.collider.Parent or not state.seat.Parent then
			wheels[motor] = nil
			continue
		end

		local position = state.collider.Position
		local travel = (position - state.last) * Vector3.new(1, 0, 1)
		state.last = position

		local speed = travel.Magnitude / math.max(delta, 1 / 240)
		if speed < 0.2 or speed > MAX_ROLL_SPEED then
			continue
		end

		local heading = if state.seat.CFrame.LookVector:Dot(travel) < 0 then -1 else 1
		state.angle = (state.angle + (speed / state.radius) * delta * heading) % (math.pi * 2)
		motor.Transform = CFrame.Angles(-state.angle * state.sign, 0, 0)
	end
end

--=============================================================================
-- Actions & Mobile Touch Buttons (Hop Only - Dismount managed by MovementController)
--=============================================================================

local function triggerHop()
	RemoteController.fire('VehicleHop')
end

local function dismount()
	local humanoid = currentHumanoid
	if not humanoid or not currentSeat then
		return
	end
	if os.clock() - mountedAt < 0.35 then
		return
	end
	humanoid.Sit = false
end

local function buildMobileBikeButtons()
	if not UIScaling.isTouch() then
		return
	end
	if hopButton then
		hopButton.Visible = true
		return
	end

	-- Hop Button — leftmost slot in the shared bottom action row, so it sits
	-- neatly beside MovementController's Sprint/Boost button.
	local hopBtn = UIDock.roundButton('HOP', 1, Color3.fromRGB(32, 100, 175))
	hopBtn.Name = 'HopButton'
	hopBtn.Parent = UIDock.getBottomActionRow()
	hopButton = hopBtn

	hopBtn.MouseButton1Click:Connect(function()
		triggerHop()
	end)
end

local function removeMobileBikeButtons()
	if hopButton then
		hopButton.Visible = false
	end
end

local function bindControls()
	ContextActionService:BindAction(HOP_ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			triggerHop()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.Space, Enum.KeyCode.Q, Enum.KeyCode.ButtonA, Enum.PlayerActions.CharacterJump)

	ContextActionService:BindAction(DISMOUNT_ACTION, function(_, state: Enum.UserInputState)
		if state == Enum.UserInputState.Begin then
			dismount()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.E, Enum.KeyCode.X, Enum.KeyCode.ButtonB)

	buildMobileBikeButtons()
end

local function unbindControls()
	ContextActionService:UnbindAction(HOP_ACTION)
	ContextActionService:UnbindAction(DISMOUNT_ACTION)
	removeMobileBikeButtons()
end

--=============================================================================

local function isBicycleSeat(seat: BasePart?): boolean
	if not seat or not seat:IsA('VehicleSeat') then
		return false
	end
	if seat:GetAttribute('SuwaBicycle') then
		return true
	end
	local model = seat:FindFirstAncestorOfClass('Model')
	while model do
		local name = model.Name:lower()
		if model:GetAttribute('ParkBike') or name:find('bike') or name:find('bicycle') then
			return true
		end
		model = model:FindFirstAncestorOfClass('Model')
	end
	return false
end

local function onSeatChanged(humanoid: Humanoid)
	local seat = humanoid.SeatPart

	if isBicycleSeat(seat) then
		currentSeat = seat :: VehicleSeat
		mountedAt = os.clock()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		bindControls()
		showCard()
		return
	end

	if currentSeat then
		unbindControls()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		hideCard()
	end
	currentSeat = nil
end

local function hookCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	if not (humanoid and humanoid:IsA('Humanoid')) then
		return
	end
	currentHumanoid = humanoid
	currentSeat = nil

	humanoid:GetPropertyChangedSignal('SeatPart'):Connect(function()
		onSeatChanged(humanoid)
	end)
	humanoid.Died:Connect(function()
		currentSeat = nil
		unbindControls()
		hideCard()
	end)
	onSeatChanged(humanoid)
end

function BicycleController.isRiding(): boolean
	return currentSeat ~= nil
end

function BicycleController.init()
	for _, descendant in workspace:GetDescendants() do
		if descendant:IsA('Motor6D') then
			registerWheel(descendant)
		end
	end
	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA('Motor6D') then
			task.defer(registerWheel, descendant)
		end
	end)
	RunService.RenderStepped:Connect(rollWheels)

	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)
end

return BicycleController
