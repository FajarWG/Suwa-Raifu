--!strict

-- Fishing status, bite timing and catch-result modal.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local UIScaling = require(script.Parent:WaitForChild('UIScaling'))
local FishingData = require(ReplicatedStorage.Shared:WaitForChild('data'):WaitForChild('Fishing'))

local FishingController = {}
local currentState = 'IDLE'
local gui: ScreenGui
local statusPanel: Frame
local statusLabel: TextLabel
local reelButton: TextButton
local resultModal: Frame
local viewport: ViewportFrame
local resultTitle: TextLabel
local resultDetails: TextLabel

local function corner(parent: GuiObject, radius: number)
	local uiCorner = Instance.new('UICorner')
	uiCorner.CornerRadius = UDim.new(0, radius)
	uiCorner.Parent = parent
end

local function makeText(
	parent: Instance,
	name: string,
	position: UDim2,
	size: UDim2,
	text: string,
	textSize: number
): TextLabel
	local label = Instance.new('TextLabel')
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = textSize
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function clearViewport()
	for _, child in viewport:GetChildren() do
		if not child:IsA('Camera') then
			child:Destroy()
		end
	end
end

local function renderCatch(payload: any)
	clearViewport()
	local world = Instance.new('WorldModel')
	world.Parent = viewport
	local definition = FishingData.fish[payload.id]
	if definition then
		local body = Instance.new('Part')
		body.Shape = Enum.PartType.Ball
		body.Size = if payload.id == 'eel' then Vector3.new(4.5, 0.6, 0.6) else Vector3.new(3.1, 1.0, 1.3)
		body.Color = definition.color
		body.Material = Enum.Material.SmoothPlastic
		body.Anchored = true
		body.CFrame = CFrame.Angles(0, math.rad(-18), math.rad(-5))
		body.Parent = world
		local tail = Instance.new('WedgePart')
		tail.Size = Vector3.new(1.0, 1.1, 1.0)
		tail.Color = definition.color:Lerp(Color3.new(0, 0, 0), 0.15)
		tail.Anchored = true
		tail.CFrame = CFrame.new(-2, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
		tail.Parent = world
		local eye = Instance.new('Part')
		eye.Shape = Enum.PartType.Ball
		eye.Size = Vector3.new(0.18, 0.18, 0.18)
		eye.Color = Color3.fromRGB(18, 20, 19)
		eye.Anchored = true
		eye.CFrame = CFrame.new(1.25, 0.22, -0.55)
		eye.Parent = world
	else
		local junk = Instance.new('Part')
		junk.Size = Vector3.new(1.5, 2.0, 2.6)
		junk.Color = if payload.id == 'old_boot' then Color3.fromRGB(74, 55, 42) else Color3.fromRGB(137, 148, 150)
		junk.Material = if payload.id == 'old_boot' then Enum.Material.Leather else Enum.Material.Metal
		junk.Anchored = true
		junk.CFrame = CFrame.Angles(math.rad(12), math.rad(-24), math.rad(8))
		junk.Parent = world
	end
	local camera = viewport.CurrentCamera
	if camera then
		camera.CFrame = CFrame.new(0, 1.2, 8) * CFrame.Angles(math.rad(-7), 0, 0)
	end
end

local function showStatus(text: string, showReel: boolean)
	statusPanel.Visible = true
	statusLabel.Text = text
	reelButton.Visible = showReel
end

local function showResult(payload: any)
	resultTitle.Text = if payload.isFish then `Caught: {payload.name}` else `Found: {payload.name}`
	local japanese = if payload.japaneseName then ` / {payload.japaneseName}` else ''
	local measurements = if payload.isFish
		then `\nLength: {payload.lengthCm} cm   Weight: {payload.weightKg} kg`
		else '\nNot a fish—but it was added to your bag.'
	resultDetails.Text =
		`{payload.rarity}{japanese}{measurements}\nEstimated value: ¥{payload.value}\nFishing level: {payload.fishingLevel}`
	renderCatch(payload)
	resultModal.Visible = true
end

local function buildGui()
	local playerGui = Players.LocalPlayer:WaitForChild('PlayerGui')
	gui = Instance.new('ScreenGui')
	gui.Name = 'FishingGui'
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 30
	gui.Parent = playerGui

	statusPanel = Instance.new('Frame')
	statusPanel.Name = 'FishingStatus'
	statusPanel.AnchorPoint = Vector2.new(0.5, 0)
	statusPanel.Position = UDim2.fromScale(0.5, 0.08)
	statusPanel.Size = UDim2.fromOffset(420, 104)
	statusPanel.BackgroundColor3 = Color3.fromRGB(24, 49, 59)
	statusPanel.BackgroundTransparency = 0.08
	statusPanel.Visible = false
	statusPanel.Parent = gui
	corner(statusPanel, 14)
	UIScaling.fit(statusPanel)
	statusLabel = makeText(statusPanel, 'Status', UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 42), '', 20)

	reelButton = Instance.new('TextButton')
	reelButton.Name = 'ReelButton'
	reelButton.AnchorPoint = Vector2.new(0.5, 1)
	reelButton.Position = UDim2.new(0.5, 0, 1, -10)
	reelButton.Size = UDim2.fromOffset(210, 42)
	reelButton.BackgroundColor3 = Color3.fromRGB(224, 151, 44)
	reelButton.Text = if UIScaling.isTouch() then 'REEL NOW!' else 'REEL NOW!  [SPACE]'
	reelButton.TextColor3 = Color3.fromRGB(34, 29, 23)
	reelButton.Font = Enum.Font.GothamBold
	reelButton.TextSize = 18
	reelButton.Visible = false
	reelButton.Parent = statusPanel
	corner(reelButton, 10)
	reelButton.Activated:Connect(function()
		if currentState == 'BITE' then
			RemoteController.fire('FishReel')
		end
	end)

	resultModal = Instance.new('Frame')
	resultModal.Name = 'CatchResult'
	resultModal.AnchorPoint = Vector2.new(0.5, 0.5)
	resultModal.Position = UDim2.fromScale(0.5, 0.5)
	resultModal.Size = UDim2.fromOffset(520, 430)
	resultModal.BackgroundColor3 = Color3.fromRGB(243, 237, 220)
	resultModal.Visible = false
	resultModal.Parent = gui
	corner(resultModal, 18)
	UIScaling.fit(resultModal)
	resultTitle = makeText(resultModal, 'Title', UDim2.fromOffset(18, 12), UDim2.new(1, -36, 0, 46), 'Catch', 25)
	resultTitle.TextColor3 = Color3.fromRGB(41, 65, 69)

	viewport = Instance.new('ViewportFrame')
	viewport.Name = 'CatchPreview'
	viewport.Position = UDim2.fromOffset(30, 65)
	viewport.Size = UDim2.new(1, -60, 0, 205)
	viewport.BackgroundColor3 = Color3.fromRGB(155, 205, 218)
	viewport.Ambient = Color3.fromRGB(205, 211, 204)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.Parent = resultModal
	corner(viewport, 12)
	local camera = Instance.new('Camera')
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	resultDetails = makeText(resultModal, 'Details', UDim2.fromOffset(25, 280), UDim2.new(1, -50, 0, 90), '', 17)
	resultDetails.TextColor3 = Color3.fromRGB(51, 57, 52)
	resultDetails.Font = Enum.Font.Gotham

	local close = Instance.new('TextButton')
	close.AnchorPoint = Vector2.new(0.5, 1)
	close.Position = UDim2.new(0.5, 0, 1, -16)
	close.Size = UDim2.fromOffset(160, 42)
	close.BackgroundColor3 = Color3.fromRGB(55, 103, 106)
	close.Text = 'Put in Bag'
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.Parent = resultModal
	corner(close, 10)
	close.Activated:Connect(function()
		resultModal.Visible = false
	end)
end

function FishingController.init()
	buildGui()
	RemoteController.onEvent('FishingState', function(state: string, payload: any)
		currentState = state
		if state == 'CASTING' then
			showStatus(payload.message or 'Casting line…', false)
		elseif state == 'WAITING' then
			showStatus(payload.message or 'Watch the bobber…', false)
		elseif state == 'BITE' then
			showStatus(payload.message or 'A fish is biting!', true)
		elseif state == 'REELING' then
			showStatus(payload.message or 'Reeling in…', false)
		elseif state == 'CAUGHT' then
			statusPanel.Visible = false
			showResult(payload)
		else
			showStatus(payload.message or 'Fishing ended.', false)
			task.delay(3, function()
				if currentState == state then
					statusPanel.Visible = false
				end
			end)
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Space and currentState == 'BITE' then
			RemoteController.fire('FishReel')
		end
	end)
end

return FishingController
