--!strict

-- Driver-side vehicle controls and the on-mount help card.
--
--   W A S D   steer / throttle (handled natively by VehicleSeat)
--   Space/Q   hop the front wheel over a kerb
--   Shift     boost (the touch Sprint button does the same job)
--   X         get off
--
-- Boost and hop go over remotes rather than attributes: an attribute set on the
-- client never replicates up to the server, so it cannot carry driver input.

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))

local player = Players.LocalPlayer

local VehicleControlController = {}

local currentSeat: VehicleSeat? = nil
local helpGui: ScreenGui? = nil

local function buildHelpCard(): ScreenGui
	if helpGui then
		return helpGui
	end
	local playerGui = player:WaitForChild('PlayerGui')

	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaVehicleHelp'
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local frame = Instance.new('Frame')
	frame.Name = 'Card'
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -24)
	frame.Size = UDim2.new(0, 430, 0, 92)
	frame.BackgroundColor3 = Color3.fromRGB(22, 26, 34)
	frame.BackgroundTransparency = 0.15
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 190, 120)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.35
	stroke.Parent = frame

	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.Position = UDim2.new(0, 16, 0, 10)
	title.Size = UDim2.new(1, -32, 0, 20)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(255, 214, 150)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = 'Riding'
	title.Parent = frame

	local body = Instance.new('TextLabel')
	body.Name = 'Body'
	body.Position = UDim2.new(0, 16, 0, 32)
	body.Size = UDim2.new(1, -32, 0, 50)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.Gotham
	body.TextSize = 13
	body.TextColor3 = Color3.fromRGB(228, 232, 238)
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.RichText = true
	body.Parent = frame

	if UserInputService.TouchEnabled then
		body.Text = 'Steer with the joystick  •  <b>SPRINT</b> to boost'
			.. '\n<b>HOP</b> to lift the front wheel  •  <b>GET OFF</b> to dismount'
	else
		body.Text = '<b>W A S D</b> ride and steer  •  <b>Shift</b> boost'
			.. '\n<b>Space</b> or <b>Q</b> hop  •  <b>X</b> get off'
	end

	helpGui = gui
	return gui
end

-- Touch devices need real buttons for hop and dismount.
local function buildTouchButtons(gui: ScreenGui)
	if not UserInputService.TouchEnabled or gui:FindFirstChild('TouchControls') then
		return
	end
	local holder = Instance.new('Frame')
	holder.Name = 'TouchControls'
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -30, 1, -290)
	holder.Size = UDim2.new(0, 96, 0, 210)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local function makeButton(name: string, text: string, y: number, colour: Color3): TextButton
		local button = Instance.new('TextButton')
		button.Name = name
		button.Position = UDim2.new(0, 0, 0, y)
		button.Size = UDim2.new(0, 96, 0, 96)
		button.BackgroundColor3 = colour
		button.BackgroundTransparency = 0.2
		button.Text = text
		button.Font = Enum.Font.GothamBold
		button.TextSize = 14
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.AutoButtonColor = true
		button.Parent = holder
		local round = Instance.new('UICorner')
		round.CornerRadius = UDim.new(1, 0)
		round.Parent = button
		return button
	end

	makeButton('HopButton', 'HOP', 0, Color3.fromRGB(38, 58, 46)).Activated:Connect(function()
		if currentSeat then
			RemoteController.fire('VehicleHop')
		end
	end)
	makeButton('ExitButton', 'GET OFF', 114, Color3.fromRGB(72, 34, 34)).Activated:Connect(function()
		local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
		if humanoid then
			humanoid.Sit = false
		end
	end)
end

local function showHelp(show: boolean)
	local gui = buildHelpCard()
	buildTouchButtons(gui)
	gui.Enabled = show
	local touch = gui:FindFirstChild('TouchControls')
	if touch then
		(touch :: Frame).Visible = show
	end
end

local function onSeatChanged(humanoid: Humanoid)
	local seat = humanoid.SeatPart
	if seat and seat:IsA('VehicleSeat') then
		currentSeat = seat
		showHelp(true)
	else
		if currentSeat then
			-- Always drop the boost when leaving, or the server keeps it latched.
			RemoteController.fire('VehicleBoost', false)
		end
		currentSeat = nil
		showHelp(false)
	end
end

local function hookCharacter(character: Model)
	local humanoid = character:FindFirstChildOfClass('Humanoid') or character:WaitForChild('Humanoid')
	if not (humanoid and humanoid:IsA('Humanoid')) then
		return
	end
	humanoid:GetPropertyChangedSignal('SeatPart'):Connect(function()
		onSeatChanged(humanoid)
	end)
	onSeatChanged(humanoid)
end

-- Called by MovementController so one Shift / Sprint control drives both.
function VehicleControlController.setBoost(value: boolean)
	if currentSeat then
		RemoteController.fire('VehicleBoost', value)
	end
end

function VehicleControlController.isSeated(): boolean
	return currentSeat ~= nil
end

function VehicleControlController.init()
	if player.Character then
		hookCharacter(player.Character)
	end
	player.CharacterAdded:Connect(hookCharacter)

	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed or not currentSeat then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Q then
			RemoteController.fire('VehicleHop')
		elseif input.KeyCode == Enum.KeyCode.X then
			local humanoid = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
			if humanoid then
				humanoid.Sit = false
			end
		end
	end)
end

return VehicleControlController
