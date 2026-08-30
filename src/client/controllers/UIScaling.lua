--!strict

-- Keeps the hand-authored desktop panels usable on phones.
--
-- Every panel in this project is laid out in absolute pixels against a roughly
-- 1180x640 desktop window. On a phone viewport (often ~900x420) those numbers
-- cover most of the screen, so each panel gets a UIScale that shrinks it to fit
-- while keeping the layout it was designed with. Scaling happens about the
-- panel's own AnchorPoint, so centred and edge-anchored panels stay put.

local UserInputService = game:GetService('UserInputService')
local Workspace = game:GetService('Workspace')

local UIScaling = {}

local REFERENCE_WIDTH = 1180
local REFERENCE_HEIGHT = 640
local MIN_SCALE = 0.5

function UIScaling.isTouch(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function viewportSize(): Vector2
	local camera = Workspace.CurrentCamera
	return if camera then camera.ViewportSize else Vector2.new(REFERENCE_WIDTH, REFERENCE_HEIGHT)
end

function UIScaling.factor(): number
	local size = viewportSize()
	if size.X <= 0 or size.Y <= 0 then
		return 1
	end
	local fit = math.min(size.X / REFERENCE_WIDTH, size.Y / REFERENCE_HEIGHT)
	return math.clamp(fit, MIN_SCALE, 1)
end

-- `boost` nudges the result back up for touch targets that must stay tappable
-- (a 88px sprint button shrunk to 57px is too small for a thumb).
function UIScaling.fit(target: GuiObject, boost: number?): UIScale
	local uiScale = target:FindFirstChildOfClass('UIScale') or Instance.new('UIScale')
	uiScale.Parent = target

	local function refresh()
		uiScale.Scale = math.min(1, UIScaling.factor() * (boost or 1))
	end

	local function watch(camera: Camera?)
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

	return uiScale
end

return UIScaling
