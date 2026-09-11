-- AutoResize for EmoteSystemGui with responsive height clamping
local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local screenGui = script.Parent

local REFERENCE_WIDTH = 1180
local REFERENCE_HEIGHT = 640
local MIN_SCALE = 0.5

local function scaleFactor()
	local camera = Workspace.CurrentCamera
	local size = if camera
		then camera.ViewportSize
		else Vector2.new(REFERENCE_WIDTH, REFERENCE_HEIGHT)
	if size.X <= 0 or size.Y <= 0 then
		return 1
	end
	local fit = math.min(size.X / REFERENCE_WIDTH, size.Y / REFERENCE_HEIGHT)
	return math.clamp(fit, MIN_SCALE, 1)
end

local uiScale = screenGui:FindFirstChildOfClass('UIScale') or Instance.new('UIScale')
uiScale.Parent = screenGui

local mainFrame = screenGui:WaitForChild('MainFrame')

local function refresh()
	local factor = scaleFactor()
	uiScale.Scale = factor

	-- Responsive height for MainFrame on mobile / small viewports:
	local camera = Workspace.CurrentCamera
	local vHeight = if camera and camera.ViewportSize.Y > 0 then camera.ViewportSize.Y else REFERENCE_HEIGHT
	local availableY = (vHeight / factor) - 58 - 20
	local targetHeight = math.clamp(math.floor(availableY), 180, 320)
	mainFrame.Size = UDim2.new(0, 250, 0, targetHeight)
	mainFrame.AnchorPoint = Vector2.new(1, 0)
	mainFrame.Position = UDim2.new(1, -16, 0, 58)
end

local function watch(camera)
	if camera then
		camera:GetPropertyChangedSignal('ViewportSize'):Connect(refresh)
	end
end

refresh()
watch(Workspace.CurrentCamera)
Workspace:GetPropertyChangedSignal('CurrentCamera'):Connect(function()
	watch(Workspace.CurrentCamera)
	refresh()
end)
