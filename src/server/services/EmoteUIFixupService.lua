--!strict

-- The "Emote Dance & Sync" toolbox asset (StarterGui.EmoteSystemGui, not part
-- of this Rojo project) ships its own emote button and panel at hardcoded
-- positions that were hand-tuned to sit next to whatever the custom top-right
-- HUD dock looked like at the time. That dock is now dynamically sized, so
-- the emote button drifted out of alignment and overlapped it, and the panel
-- opened nowhere near the button that opens it.
--
-- This patches both instances' *default* Position/AnchorPoint directly on the
-- StarterGui template, once, before any player joins. That matters because
-- the asset's own LocalScript does
--   local lastFramePosition = mainFrame.Position
-- once at startup with no yield in between: if we patched the button/panel
-- from a client-side script instead, we'd be racing that line, and losing the
-- race would silently leave the panel opening at the old broken position.
-- Patching the server-side template means every player's PlayerGui clones in
-- with the corrected values already in place, before their local scripts run.

local StarterGui = game:GetService('StarterGui')

local EmoteUIFixupService = {}

local BUTTON_POSITION = UDim2.new(0, 16, 0, 70)
-- Square, because the icon inside it is square. Also a comfortable tap target.
local BUTTON_SIZE = 44
local PANEL_GAP = 8

function EmoteUIFixupService.init()
	local emoteGui = StarterGui:FindFirstChild('EmoteSystemGui')
	if not emoteGui then
		return
	end

	local button = emoteGui:FindFirstChild('EmoteButton')
	if button and button:IsA('GuiObject') then
		button.AnchorPoint = Vector2.new(0, 0)
		button.Position = BUTTON_POSITION
		-- The asset ships an 80x34 button around a square dancer icon, and its
		-- ScaleType is Stretch, so the icon was squashed flat to fill that
		-- letterbox. A square button plus Fit keeps whatever aspect ratio the
		-- artwork actually has, instead of forcing it into the frame's.
		button.Size = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE)
		if button:IsA('ImageButton') then
			button.ScaleType = Enum.ScaleType.Fit
		end
	end

	local mainFrame = emoteGui:FindFirstChild('MainFrame')
	if mainFrame and mainFrame:IsA('GuiObject') then
		-- AbsoluteSize is a client-only computed value and is meaningless on a
		-- server-held StarterGui template, so the gap is measured off the
		-- button's serialized Size instead.
		local buttonHeight = if button and button:IsA('GuiObject') then button.Size.Y.Offset else 34
		mainFrame.AnchorPoint = Vector2.new(0, 0)
		mainFrame.Position = UDim2.new(
			BUTTON_POSITION.X.Scale,
			BUTTON_POSITION.X.Offset,
			BUTTON_POSITION.Y.Scale,
			BUTTON_POSITION.Y.Offset + buttonHeight + PANEL_GAP
		)
	end
end

return EmoteUIFixupService
