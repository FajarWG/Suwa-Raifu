-- The emote GUI is a toolbox asset and arrived with its own scaling curve:
-- base 1366x768, with multipliers that go *above* 1 on a large monitor and
-- follow a different ramp on phones. That made it the one piece of HUD that
-- grew on desktop and shrank on its own schedule on mobile, out of step with
-- every other panel. It now defers to the project's shared UIScaling, so the
-- emote button and panel track the rest of the HUD on every screen.
--
-- One exception: the shared curve bottoms out at 0.5, which would leave the
-- emote button around 22px on a phone -- below a usable tap target. On touch
-- devices the button gets that shrink handed back to it, capped so it never
-- grows past the size it was authored at.

-- The numbers below are copied from Client/controllers/UIScaling rather than
-- required from it: this GUI is a toolbox asset and runs sandboxed, so a
-- require reaching outside the sandbox is rejected outright ('the calling
-- thread is sandboxed'). Keep the three constants in step with that module.

local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local screenGui = script.Parent

local REFERENCE_WIDTH = 1180
local REFERENCE_HEIGHT = 640
local MIN_SCALE = 0.5
local TOUCH_MAX_BOOST = 1.8

local function isTouch()
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

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

local button = screenGui:WaitForChild('EmoteButton')
local buttonScale = button:FindFirstChildOfClass('UIScale') or Instance.new('UIScale')
buttonScale.Parent = button

local function refresh()
	local factor = scaleFactor()
	uiScale.Scale = factor
	-- Nested UIScales multiply, so this cancels the panel-wide shrink for the
	-- button alone rather than adding to it.
	buttonScale.Scale = if isTouch()
		then math.clamp(1 / factor, 1, TOUCH_MAX_BOOST)
		else 1
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