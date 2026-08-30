--!strict

-- Shared HUD docks so every controller's buttons flow together instead of
-- guessing pixel offsets against buttons owned by *other* controllers.
--
-- Before this module, StatusController/InventoryController/LieDownController
-- each hardcoded an absolute `1, -N, 0, 16` offset for their own top-right
-- pill, and MovementController/BicycleController/CarryController hardcoded
-- absolute bottom-right offsets for each other's buttons. Any size change in
-- one file silently created overlaps or gaps in another. Two UIListLayout
-- containers replace all of that arithmetic: buttons register with a
-- LayoutOrder and the row/stack grows or shrinks to fit whatever happens to
-- be visible, on any screen size.
--
-- Top dock: horizontal row of menu-style pills (Bag, Status, Lay Down, ...),
-- anchored top-right, respecting Roblox's own top bar inset.
--
-- Bottom dock: a vertical stack anchored bottom-right. Its lower slot is a
-- horizontal row of round touch buttons (Hop, Sprint/Boost); its upper slot
-- holds a single context pill (Get Off, Release) that only one controller
-- shows at a time. Hidden (Visible = false) children are skipped by
-- UIListLayout, so the stack collapses cleanly when nothing needs it.

local Players = game:GetService('Players')

local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local UIDock = {}

local player = Players.LocalPlayer

local topRow: Frame? = nil
local bottomStack: Frame? = nil
local bottomActionRow: Frame? = nil

local function getPlayerGui(): PlayerGui
	return player:WaitForChild('PlayerGui') :: PlayerGui
end

local function ensureScreenGui(name: string): ScreenGui
	local gui = getPlayerGui():FindFirstChild(name)
	if gui and gui:IsA('ScreenGui') then
		return gui
	end
	local newGui = Instance.new('ScreenGui')
	newGui.Name = name
	newGui.ResetOnSpawn = false
	newGui.Parent = getPlayerGui()
	return newGui
end

-- Top-right row: pills flow leftward from the screen edge as more are added.
function UIDock.getTopRightRow(): Frame
	if topRow and topRow.Parent then
		return topRow
	end

	local gui = ensureScreenGui('SuwaTopDockGui')

	local row = Instance.new('Frame')
	row.Name = 'Row'
	row.AnchorPoint = Vector2.new(1, 0)
	row.Position = UDim2.new(1, -16, 0, 16)
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.new(0, 0, 0, 0)
	row.BackgroundTransparency = 1
	row.Parent = gui

	local layout = Instance.new('UIListLayout')
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = row

	topRow = row
	return row
end

-- Bottom-right stack: the context pill (if any) sits above the action row.
function UIDock.getBottomRightStack(): Frame
	if bottomStack and bottomStack.Parent then
		return bottomStack
	end

	local gui = ensureScreenGui('SuwaBottomDockGui')

	local stack = Instance.new('Frame')
	stack.Name = 'Stack'
	stack.AnchorPoint = Vector2.new(1, 1)
	stack.Position = UDim2.new(1, -20, 1, -140)
	stack.AutomaticSize = Enum.AutomaticSize.XY
	stack.Size = UDim2.new(0, 0, 0, 0)
	stack.BackgroundTransparency = 1
	stack.Parent = gui

	local layout = Instance.new('UIListLayout')
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = stack

	bottomStack = stack
	return stack
end

-- Row of round buttons (Hop, Sprint/Boost) nested inside the bottom stack.
-- Always LayoutOrder 100 so context pills (order < 100) stay above it.
function UIDock.getBottomActionRow(): Frame
	if bottomActionRow and bottomActionRow.Parent then
		return bottomActionRow
	end

	local stack = UIDock.getBottomRightStack()

	local row = Instance.new('Frame')
	row.Name = 'ActionRow'
	row.LayoutOrder = 100
	row.AutomaticSize = Enum.AutomaticSize.XY
	row.Size = UDim2.new(0, 0, 0, 0)
	row.BackgroundTransparency = 1
	row.Parent = stack

	local layout = Instance.new('UIListLayout')
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)
	layout.Parent = row

	bottomActionRow = row
	return row
end

--=============================================================================
-- Consistent button styling (one look for every dock pill/round button)
--=============================================================================

local PANEL_COLOR = Color3.fromRGB(24, 28, 38)
local STROKE_COLOR = Color3.fromRGB(130, 160, 200)

-- Rectangular pill that hugs its own text (never truncates, any language).
function UIDock.pillButton(text: string, order: number, backgroundColor: Color3?): TextButton
	local button = Instance.new('TextButton')
	button.Name = 'Pill'
	button.LayoutOrder = order
	button.AutomaticSize = Enum.AutomaticSize.X
	button.Size = UDim2.new(0, 0, 0, 38)
	button.BackgroundColor3 = backgroundColor or PANEL_COLOR
	button.BackgroundTransparency = 0.15
	button.Font = Enum.Font.GothamBold
	button.TextSize = 13
	button.TextColor3 = Color3.fromRGB(240, 245, 255)
	button.Text = text
	button.AutoButtonColor = true

	local padding = Instance.new('UIPadding')
	padding.PaddingLeft = UDim.new(0, 16)
	padding.PaddingRight = UDim.new(0, 16)
	padding.Parent = button

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	local stroke = Instance.new('UIStroke')
	stroke.Color = STROKE_COLOR
	stroke.Thickness = 1
	stroke.Transparency = 0.4
	stroke.Parent = button

	UIScaling.fit(button, 1.1)
	return button
end

-- Fixed-diameter circular touch button (Sprint/Boost, Hop).
local ROUND_DIAMETER = 66

function UIDock.roundButton(text: string, order: number, color: Color3): TextButton
	local button = Instance.new('TextButton')
	button.Name = 'Round'
	button.LayoutOrder = order
	button.Size = UDim2.new(0, ROUND_DIAMETER, 0, ROUND_DIAMETER)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.2
	button.Font = Enum.Font.GothamBold
	button.TextSize = 12
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.Text = text
	button.AutoButtonColor = false

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = button

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.55
	stroke.Parent = button

	UIScaling.fit(button, 1.15)
	return button
end

-- Context pill for the bottom stack's upper slot (Get Off, Release). Always
-- LayoutOrder 1 so it sits directly above the action row regardless of which
-- controller is showing it.
function UIDock.contextPill(text: string, color: Color3): TextButton
	local button = UIDock.pillButton(text, 1, color)
	button.Size = UDim2.new(0, 0, 0, 44)
	button.BackgroundTransparency = 0.12
	button.Parent = UIDock.getBottomRightStack()
	return button
end

return UIDock
