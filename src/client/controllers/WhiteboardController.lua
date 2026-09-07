--!strict

-- WhiteboardController.lua
-- Interactive Classroom Whiteboard Controller:
-- 1. [E] at Whiteboard opens the Editor (Draw, Eraser, Text with custom sizes, Color palette, Apply, Clear, Undo).
-- 2. Closes ONLY when clicking the red [X] button (never accidentally when drawing on canvas).
-- 3. Student Seated Mode: sitting at a school desk shows [Focus Whiteboard / 黒板を見る] button.
--    Clicking it shows the live whiteboard in Read-Only mode right in front of their eyes.
-- 4. English / Japanese bilingual UI.

local Players = game:GetService('Players')
local ProximityPromptService = game:GetService('ProximityPromptService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')

local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild('PlayerGui')

local WhiteboardController = {}

type LinePoint = {
	x1: number,
	y1: number,
	x2: number,
	y2: number,
	color: string,
	thickness: number,
}

type TextEntry = {
	text: string,
	x: number,
	y: number,
	color: string,
	size: number,
}

-- State
local currentBoardId: string? = nil
local currentRoomName = 'Classroom'
local isReadOnlyMode = false

local isDrawing = false
local lastCanvasPos: Vector2? = nil
local currentMode = 'draw' -- 'draw', 'eraser', 'text'
local currentColor = '#212121'
local currentThickness = 6
local currentFontSize = 32

local localLines: { LinePoint } = {}
local localTexts: { TextEntry } = {}
local historyStrokes: { { LinePoint } } = {}
local currentStroke: { LinePoint } = {}

-- UI Elements
local screenGui: ScreenGui?
local mainWindow: Frame?
local canvasFrame: Frame?
local drawContainer: Frame?
local textContainer: Frame?
local toolbarFrame: Frame?
local textInputModal: Frame?
local textInputBox: TextBox?

-- Student Seat Focus Button
local studentFocusGui: ScreenGui?
local seatedDeskRoomId: string? = nil
local seatedDeskRoomName: string? = nil

local CANVAS_VIRTUAL_W = 1200
local CANVAS_VIRTUAL_H = 400

local PALETTE = {
	{ name = 'Black / 黒', hex = '#212121', color = Color3.fromRGB(33, 33, 33) },
	{ name = 'Red / 赤', hex = '#E53935', color = Color3.fromRGB(229, 57, 53) },
	{ name = 'Blue / 青', hex = '#1E88E5', color = Color3.fromRGB(30, 136, 229) },
	{ name = 'Green / 緑', hex = '#43A047', color = Color3.fromRGB(67, 160, 71) },
	{ name = 'Yellow / 黄', hex = '#FBC02D', color = Color3.fromRGB(251, 192, 45) },
	{ name = 'Purple / 紫', hex = '#8E24AA', color = Color3.fromRGB(142, 36, 170) },
}

local function hexToColor3(hex: string): Color3
	local cleanHex = hex:gsub('#', '')
	if #cleanHex == 6 then
		local r = tonumber(cleanHex:sub(1, 2), 16) or 33
		local g = tonumber(cleanHex:sub(3, 4), 16) or 33
		local b = tonumber(cleanHex:sub(5, 6), 16) or 33
		return Color3.fromRGB(r, g, b)
	end
	return Color3.fromRGB(33, 33, 33)
end

local function getRemotes()
	local folder = ReplicatedStorage:WaitForChild('SuwaRemotes', 5) :: Folder?
	if not folder then return nil, nil, nil end
	local updateEvent = folder:FindFirstChild('WhiteboardUpdate') :: RemoteEvent?
	local clearEvent = folder:FindFirstChild('WhiteboardClear') :: RemoteEvent?
	local getDataFn = folder:FindFirstChild('WhiteboardGetData') :: RemoteFunction?
	return updateEvent, clearEvent, getDataFn
end

local function renderLocalLine(line: LinePoint)
	if not drawContainer then return end

	local p1 = Vector2.new(line.x1, line.y1)
	local p2 = Vector2.new(line.x2, line.y2)
	local diff = p2 - p1
	local dist = diff.Magnitude

	local uiScale = mainWindow and mainWindow:FindFirstChildOfClass('UIScale')
	local scaleMultiplier = if uiScale then uiScale.Scale else 1
	local localCanvasW = if canvasFrame then canvasFrame.AbsoluteSize.X / scaleMultiplier else 940
	local localCanvasH = if canvasFrame then canvasFrame.AbsoluteSize.Y / scaleMultiplier else 310
	local scaleX = localCanvasW / CANVAS_VIRTUAL_W
	local scaleY = localCanvasH / CANVAS_VIRTUAL_H
	local avgScale = (scaleX + scaleY) / 2

	if dist <= 0.5 then
		local dot = Instance.new('Frame')
		dot.Name = 'Dot'
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.new(p1.X / CANVAS_VIRTUAL_W, 0, p1.Y / CANVAS_VIRTUAL_H, 0)
		dot.Size = UDim2.fromOffset(math.max(2, line.thickness * avgScale), math.max(2, line.thickness * avgScale))
		dot.BackgroundColor3 = hexToColor3(line.color)
		dot.BorderSizePixel = 0
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
		dot.Parent = drawContainer
		return
	end

	local mid = (p1 + p2) / 2
	local angle = math.atan2(diff.Y, diff.X)

	local seg = Instance.new('Frame')
	seg.Name = 'Seg'
	seg.AnchorPoint = Vector2.new(0.5, 0.5)
	seg.Position = UDim2.new(mid.X / CANVAS_VIRTUAL_W, 0, mid.Y / CANVAS_VIRTUAL_H, 0)
	seg.Size = UDim2.fromOffset(dist * avgScale, math.max(1.5, line.thickness * avgScale))
	seg.Rotation = math.deg(angle)
	seg.BackgroundColor3 = hexToColor3(line.color)
	seg.BorderSizePixel = 0

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = seg

	seg.Parent = drawContainer
end

local function renderLocalText(entry: TextEntry, index: number)
	if not textContainer then return end

	local box = Instance.new('Frame')
	box.Name = `TextEntry_{index}`
	box.BackgroundTransparency = 1
	box.Position = UDim2.new(entry.x / CANVAS_VIRTUAL_W, 0, entry.y / CANVAS_VIRTUAL_H, 0)
	box.Size = UDim2.new(0, 550, 0, 80)

	local lbl = Instance.new('TextLabel')
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = entry.size or 24
	lbl.TextColor3 = hexToColor3(entry.color or '#212121')
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextYAlignment = Enum.TextYAlignment.Top
	lbl.TextWrapped = true
	lbl.Text = entry.text
	lbl.Parent = box

	-- Only show delete button in Editor mode (not in Read-Only mode)
	if not isReadOnlyMode then
		local delBtn = Instance.new('TextButton')
		delBtn.Name = 'DelBtn'
		delBtn.Size = UDim2.fromOffset(20, 20)
		delBtn.Position = UDim2.new(0, -26, 0, 2)
		delBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
		delBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		delBtn.Text = '✕'
		delBtn.TextSize = 13
		delBtn.Font = Enum.Font.FredokaOne
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = delBtn
		delBtn.Parent = box

		delBtn.MouseButton1Click:Connect(function()
			table.remove(localTexts, index)
			WhiteboardController.refreshView()
		end)
	end

	box.Parent = textContainer
end

function WhiteboardController.refreshView()
	if drawContainer then
		drawContainer:ClearAllChildren()
		for _, line in ipairs(localLines) do
			renderLocalLine(line)
		end
	end

	if textContainer then
		textContainer:ClearAllChildren()
		for idx, entry in ipairs(localTexts) do
			renderLocalText(entry, idx)
		end
	end
end

local function screenToCanvasCoords(screenPos: Vector2): Vector2?
	if not canvasFrame then return nil end
	local absPos = canvasFrame.AbsolutePosition
	local absSize = canvasFrame.AbsoluteSize
	local relX = screenPos.X - absPos.X
	local relY = screenPos.Y - absPos.Y

	if relX < 0 or relX > absSize.X or relY < 0 or relY > absSize.Y then
		return nil
	end

	local virtX = (relX / absSize.X) * CANVAS_VIRTUAL_W
	local virtY = (relY / absSize.Y) * CANVAS_VIRTUAL_H
	return Vector2.new(virtX, virtY)
end

local function applyEraserAt(virtPos: Vector2)
	local radius = 32
	local remaining: { LinePoint } = {}
	local removedAny = false
	for _, l in ipairs(localLines) do
		local d1 = (Vector2.new(l.x1, l.y1) - virtPos).Magnitude
		local d2 = (Vector2.new(l.x2, l.y2) - virtPos).Magnitude
		if d1 < radius or d2 < radius then
			removedAny = true
		else
			table.insert(remaining, l)
		end
	end
	if removedAny then
		localLines = remaining
		WhiteboardController.refreshView()
	end
end

local function createUI()
	for _, g in ipairs(playerGui:GetChildren()) do
		if g.Name == 'WhiteboardScreenGui' then
			g:Destroy()
		end
	end

	screenGui = Instance.new('ScreenGui')
	screenGui.Name = 'WhiteboardScreenGui'
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Dim background overlay (Frame only - NOT a button so clicking canvas NEVER closes the window)
	local overlay = Instance.new('Frame')
	overlay.Name = 'Overlay'
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.55
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 1
	overlay.Parent = screenGui

	-- Main Window
	mainWindow = Instance.new('Frame')
	mainWindow.Name = 'MainWindow'
	mainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	mainWindow.Position = UDim2.fromScale(0.5, 0.5)
	mainWindow.Size = UDim2.fromOffset(980, 560)
	mainWindow.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
	mainWindow.BorderSizePixel = 0
	mainWindow.ZIndex = 2
	mainWindow.Active = true
	local mainCorner = Instance.new('UICorner')
	mainCorner.CornerRadius = UDim.new(0, 14)
	mainCorner.Parent = mainWindow

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(55, 60, 75)
	stroke.Thickness = 1.5
	stroke.Parent = mainWindow
	mainWindow.Parent = screenGui

	-- Mobile responsive scaling
	UIScaling.fit(mainWindow)

	-- Header
	local header = Instance.new('Frame')
	header.Name = 'Header'
	header.Size = UDim2.new(1, 0, 0, 48)
	header.BackgroundTransparency = 1
	header.ZIndex = 3
	header.Parent = mainWindow

	local title = Instance.new('TextLabel')
	title.Name = 'Title'
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 20, 0, 0)
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextSize = 19
	title.TextColor3 = Color3.fromRGB(240, 245, 255)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = '🏫 Classroom Whiteboard / 教室ホワイトボード'
	title.ZIndex = 3
	title.Parent = header

	-- Prominent Red Close Button (The ONLY way to close the window)
	local closeBtn = Instance.new('TextButton')
	closeBtn.Name = 'CloseBtn'
	closeBtn.AnchorPoint = Vector2.new(1, 0.5)
	closeBtn.Position = UDim2.new(1, -14, 0.5, 0)
	closeBtn.Size = UDim2.fromOffset(40, 40)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 53, 69)
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Text = '✕'
	closeBtn.TextSize = 20
	closeBtn.Font = Enum.Font.FredokaOne
	closeBtn.ZIndex = 4
	local closeCorner = Instance.new('UICorner')
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn
	closeBtn.Parent = header

	closeBtn.MouseButton1Click:Connect(function()
		WhiteboardController.close()
	end)

	-- Canvas Container
	local canvasWrapper = Instance.new('Frame')
	canvasWrapper.Name = 'CanvasWrapper'
	canvasWrapper.Position = UDim2.new(0, 20, 0, 52)
	canvasWrapper.Size = UDim2.new(1, -40, 0, 310)
	canvasWrapper.BackgroundColor3 = Color3.fromRGB(250, 250, 252)
	canvasWrapper.BorderSizePixel = 0
	canvasWrapper.ZIndex = 3
	canvasWrapper.Active = true
	local canvasCorner = Instance.new('UICorner')
	canvasCorner.CornerRadius = UDim.new(0, 8)
	canvasCorner.Parent = canvasWrapper

	local canvasStroke = Instance.new('UIStroke')
	canvasStroke.Color = Color3.fromRGB(200, 205, 215)
	canvasStroke.Thickness = 1.5
	canvasStroke.Parent = canvasWrapper
	canvasWrapper.Parent = mainWindow

	canvasFrame = canvasWrapper

	local gridWatermark = Instance.new('TextLabel')
	gridWatermark.BackgroundTransparency = 1
	gridWatermark.Size = UDim2.new(1, -20, 0, 20)
	gridWatermark.Position = UDim2.new(0, 12, 0, 6)
	gridWatermark.Font = Enum.Font.FredokaOne
	gridWatermark.TextSize = 12
	gridWatermark.TextColor3 = Color3.fromRGB(180, 190, 200)
	gridWatermark.TextXAlignment = Enum.TextXAlignment.Left
	gridWatermark.Text = '諏訪学園教室 (Suwa Academy) • Whiteboard'
	gridWatermark.ZIndex = 3
	gridWatermark.Parent = canvasWrapper

	drawContainer = Instance.new('Frame')
	drawContainer.Name = 'DrawContainer'
	drawContainer.BackgroundTransparency = 1
	drawContainer.Size = UDim2.fromScale(1, 1)
	drawContainer.ZIndex = 4
	drawContainer.Parent = canvasWrapper

	textContainer = Instance.new('Frame')
	textContainer.Name = 'TextContainer'
	textContainer.BackgroundTransparency = 1
	textContainer.Size = UDim2.fromScale(1, 1)
	textContainer.ZIndex = 5
	textContainer.Parent = canvasWrapper

	-- Toolbar (Bawah Canvas) - Hidden in Read-Only Student Mode
	toolbarFrame = Instance.new('Frame')
	toolbarFrame.Name = 'Toolbar'
	toolbarFrame.Position = UDim2.new(0, 20, 0, 375)
	toolbarFrame.Size = UDim2.new(1, -40, 0, 165)
	toolbarFrame.BackgroundTransparency = 1
	toolbarFrame.ZIndex = 3
	toolbarFrame.Parent = mainWindow

	-- Row 1: Tools & Colors
	local row1 = Instance.new('Frame')
	row1.Name = 'Row1'
	row1.Size = UDim2.new(1, 0, 0, 42)
	row1.BackgroundTransparency = 1
	row1.ZIndex = 3
	row1.Parent = toolbarFrame

	local row1Layout = Instance.new('UIListLayout')
	row1Layout.FillDirection = Enum.FillDirection.Horizontal
	row1Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	row1Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	row1Layout.Padding = UDim.new(0, 10)
	row1Layout.Parent = row1

	-- Tool Buttons: Draw, Eraser, Text
	local function makeToolButton(label: string, modeName: string, icon: string)
		local btn = Instance.new('TextButton')
		btn.Name = `Tool_{modeName}`
		btn.Size = UDim2.fromOffset(115, 38)
		btn.BackgroundColor3 = (currentMode == modeName) and Color3.fromRGB(60, 120, 230) or Color3.fromRGB(40, 44, 56)
		btn.TextColor3 = Color3.fromRGB(240, 245, 255)
		btn.Text = `{icon} {label}`
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = 13
		btn.ZIndex = 4
		local bCorner = Instance.new('UICorner')
		bCorner.CornerRadius = UDim.new(0, 8)
		bCorner.Parent = btn
		btn.Parent = row1

		btn.MouseButton1Click:Connect(function()
			currentMode = modeName
			for _, sibling in ipairs(row1:GetChildren()) do
				if sibling:IsA('TextButton') and sibling.Name:find('Tool_') then
					sibling.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
				end
			end
			btn.BackgroundColor3 = Color3.fromRGB(60, 120, 230)
			if modeName == 'text' then
				WhiteboardController.openTextInput()
			end
		end)
		return btn
	end

	makeToolButton('Draw / 描く', 'draw', '✏️')
	makeToolButton('Eraser / 消す', 'eraser', '🧹')
	makeToolButton('Text / 文字', 'text', '🔤')

	-- Separator
	local sep = Instance.new('Frame')
	sep.Size = UDim2.fromOffset(2, 28)
	sep.BackgroundColor3 = Color3.fromRGB(50, 55, 70)
	sep.BorderSizePixel = 0
	sep.ZIndex = 3
	sep.Parent = row1

	-- Palette
	for _, p in ipairs(PALETTE) do
		local pBtn = Instance.new('TextButton')
		pBtn.Name = `Color_{p.hex}`
		pBtn.Size = UDim2.fromOffset(32, 32)
		pBtn.BackgroundColor3 = p.color
		pBtn.Text = ''
		pBtn.ZIndex = 4
		local pCorner = Instance.new('UICorner')
		pCorner.CornerRadius = UDim.new(1, 0)
		pCorner.Parent = pBtn

		local pStroke = Instance.new('UIStroke')
		pStroke.Color = (currentColor == p.hex) and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(60, 65, 80)
		pStroke.Thickness = (currentColor == p.hex) and 2.5 or 1
		pStroke.Parent = pBtn
		pBtn.Parent = row1

		pBtn.MouseButton1Click:Connect(function()
			currentColor = p.hex
			for _, sib in ipairs(row1:GetChildren()) do
				local sibStroke = sib:FindFirstChildWhichIsA('UIStroke')
				if sibStroke and sib.Name:find('Color_') then
					sibStroke.Color = Color3.fromRGB(60, 65, 80)
					sibStroke.Thickness = 1
				end
			end
			pStroke.Color = Color3.fromRGB(255, 255, 255)
			pStroke.Thickness = 2.5
			currentMode = 'draw'
			for _, sibling in ipairs(row1:GetChildren()) do
				if sibling:IsA('TextButton') and sibling.Name == 'Tool_draw' then
					sibling.BackgroundColor3 = Color3.fromRGB(60, 120, 230)
				elseif sibling:IsA('TextButton') and sibling.Name:find('Tool_') then
					sibling.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
				end
			end
		end)
	end

	-- Row 2: Brush Thickness & Action Buttons
	local row2 = Instance.new('Frame')
	row2.Name = 'Row2'
	row2.Position = UDim2.new(0, 0, 0, 52)
	row2.Size = UDim2.new(1, 0, 0, 42)
	row2.BackgroundTransparency = 1
	row2.ZIndex = 3
	row2.Parent = toolbarFrame

	local row2Layout = Instance.new('UIListLayout')
	row2Layout.FillDirection = Enum.FillDirection.Horizontal
	row2Layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	row2Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	row2Layout.Padding = UDim.new(0, 8)
	row2Layout.Parent = row2

	local thickLabel = Instance.new('TextLabel')
	thickLabel.BackgroundTransparency = 1
	thickLabel.Size = UDim2.fromOffset(85, 32)
	thickLabel.Font = Enum.Font.FredokaOne
	thickLabel.TextSize = 13
	thickLabel.TextColor3 = Color3.fromRGB(160, 170, 190)
	thickLabel.Text = 'Width / 太さ:'
	thickLabel.ZIndex = 3
	thickLabel.Parent = row2

	local thicknessOptions = { { 'Thin / 細い', 3 }, { 'Med / 中', 6 }, { 'Thick / 太い', 12 } }
	for _, opt in ipairs(thicknessOptions) do
		local tBtn = Instance.new('TextButton')
		tBtn.Name = `Thick_{opt[2]}`
		tBtn.Size = UDim2.fromOffset(80, 32)
		tBtn.BackgroundColor3 = (currentThickness == opt[2]) and Color3.fromRGB(60, 120, 230) or Color3.fromRGB(40, 44, 56)
		tBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
		tBtn.Text = opt[1]
		tBtn.Font = Enum.Font.FredokaOne
		tBtn.TextSize = 12
		tBtn.ZIndex = 4
		local tCorner = Instance.new('UICorner')
		tCorner.CornerRadius = UDim.new(0, 6)
		tCorner.Parent = tBtn
		tBtn.Parent = row2

		tBtn.MouseButton1Click:Connect(function()
			currentThickness = opt[2]
			for _, sib in ipairs(row2:GetChildren()) do
				if sib:IsA('TextButton') and sib.Name:find('Thick_') then
					sib.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
				end
			end
			tBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 230)
		end)
	end

	-- Action Buttons container
	local actionBox = Instance.new('Frame')
	actionBox.Name = 'ActionBox'
	actionBox.Size = UDim2.new(1, -380, 1, 0)
	actionBox.BackgroundTransparency = 1
	actionBox.ZIndex = 3
	actionBox.Parent = row2

	local actLayout = Instance.new('UIListLayout')
	actLayout.FillDirection = Enum.FillDirection.Horizontal
	actLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	actLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	actLayout.Padding = UDim.new(0, 10)
	actLayout.Parent = actionBox

	-- Undo button
	local undoBtn = Instance.new('TextButton')
	undoBtn.Name = 'UndoBtn'
	undoBtn.Size = UDim2.fromOffset(85, 36)
	undoBtn.BackgroundColor3 = Color3.fromRGB(48, 52, 68)
	undoBtn.TextColor3 = Color3.fromRGB(230, 235, 245)
	undoBtn.Text = '↩ Undo / 戻す'
	undoBtn.Font = Enum.Font.FredokaOne
	undoBtn.TextSize = 12
	undoBtn.ZIndex = 4
	local uCorner = Instance.new('UICorner')
	uCorner.CornerRadius = UDim.new(0, 8)
	uCorner.Parent = undoBtn
	undoBtn.Parent = actionBox

	undoBtn.MouseButton1Click:Connect(function()
		if #historyStrokes > 0 then
			local lastStroke = table.remove(historyStrokes)
			if lastStroke then
				local strokeCount = #lastStroke
				for _ = 1, strokeCount do
					table.remove(localLines)
				end
				WhiteboardController.refreshView()
			end
		end
	end)

	-- Clear All button
	local clearBtn = Instance.new('TextButton')
	clearBtn.Name = 'ClearBtn'
	clearBtn.Size = UDim2.fromOffset(130, 36)
	clearBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
	clearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	clearBtn.Text = '🗑️ Clear / 全消去'
	clearBtn.Font = Enum.Font.FredokaOne
	clearBtn.TextSize = 13
	clearBtn.ZIndex = 4
	local clCorner = Instance.new('UICorner')
	clCorner.CornerRadius = UDim.new(0, 8)
	clCorner.Parent = clearBtn
	clearBtn.Parent = actionBox

	clearBtn.MouseButton1Click:Connect(function()
		localLines = {}
		localTexts = {}
		historyStrokes = {}
		WhiteboardController.refreshView()
		local _, clearEvent = getRemotes()
		if clearEvent and currentBoardId then
			clearEvent:FireServer(currentBoardId)
		end
	end)

	-- Apply to Board button
	local applyBtn = Instance.new('TextButton')
	applyBtn.Name = 'ApplyBtn'
	applyBtn.Size = UDim2.fromOffset(170, 38)
	applyBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 50)
	applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	applyBtn.Text = '💾 Apply / 掲示する'
	applyBtn.Font = Enum.Font.FredokaOne
	applyBtn.TextSize = 14
	applyBtn.ZIndex = 4
	local apCorner = Instance.new('UICorner')
	apCorner.CornerRadius = UDim.new(0, 8)
	apCorner.Parent = applyBtn
	applyBtn.Parent = actionBox

	applyBtn.MouseButton1Click:Connect(function()
		local updateEvent = getRemotes()
		if updateEvent and currentBoardId then
			updateEvent:FireServer(currentBoardId, localLines, localTexts)
		end
		applyBtn.Text = '✓ Applied / 掲示完了!'
		task.delay(1.2, function()
			if applyBtn then
				applyBtn.Text = '💾 Apply / 掲示する'
			end
		end)
	end)

	-- Text Input Modal Popup (with Sizing Controls)
	textInputModal = Instance.new('Frame')
	textInputModal.Name = 'TextInputModal'
	textInputModal.AnchorPoint = Vector2.new(0.5, 0.5)
	textInputModal.Position = UDim2.fromScale(0.5, 0.5)
	textInputModal.Size = UDim2.fromOffset(480, 290)
	textInputModal.BackgroundColor3 = Color3.fromRGB(30, 33, 42)
	textInputModal.BorderSizePixel = 0
	textInputModal.Active = true
	textInputModal.Visible = false
	textInputModal.ZIndex = 10
	local mCorner = Instance.new('UICorner')
	mCorner.CornerRadius = UDim.new(0, 12)
	mCorner.Parent = textInputModal
	local mStroke = Instance.new('UIStroke')
	mStroke.Color = Color3.fromRGB(70, 75, 95)
	mStroke.Thickness = 1.5
	mStroke.Parent = textInputModal
	textInputModal.Parent = mainWindow

	local mTitle = Instance.new('TextLabel')
	mTitle.BackgroundTransparency = 1
	mTitle.Position = UDim2.new(0, 16, 0, 10)
	mTitle.Size = UDim2.new(1, -32, 0, 24)
	mTitle.Font = Enum.Font.FredokaOne
	mTitle.TextSize = 16
	mTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
	mTitle.TextXAlignment = Enum.TextXAlignment.Left
	mTitle.Text = '🔤 Add Text Note / テキスト追加'
	mTitle.ZIndex = 11
	mTitle.Parent = textInputModal

	textInputBox = Instance.new('TextBox')
	textInputBox.Name = 'InputBox'
	textInputBox.Position = UDim2.new(0, 16, 0, 42)
	textInputBox.Size = UDim2.new(1, -32, 0, 105)
	textInputBox.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	textInputBox.TextColor3 = Color3.fromRGB(240, 240, 240)
	textInputBox.PlaceholderText = 'Type notes, vocabulary, math, or Japanese...\nExample: 諏訪学園 • 日本語の授業 (Lesson 1)'
	textInputBox.PlaceholderColor3 = Color3.fromRGB(110, 120, 135)
	textInputBox.Font = Enum.Font.FredokaOne
	textInputBox.TextSize = 15
	textInputBox.TextXAlignment = Enum.TextXAlignment.Left
	textInputBox.TextYAlignment = Enum.TextYAlignment.Top
	textInputBox.ClearTextOnFocus = false
	textInputBox.MultiLine = true
	textInputBox.ZIndex = 11
	local iCorner = Instance.new('UICorner')
	iCorner.CornerRadius = UDim.new(0, 8)
	iCorner.Parent = textInputBox
	textInputBox.Parent = textInputModal

	-- Font Size Selection Row in Text Modal
	local sizeRow = Instance.new('Frame')
	sizeRow.Name = 'SizeRow'
	sizeRow.BackgroundTransparency = 1
	sizeRow.Position = UDim2.new(0, 16, 0, 158)
	sizeRow.Size = UDim2.new(1, -32, 0, 36)
	sizeRow.ZIndex = 11
	sizeRow.Parent = textInputModal

	local sLayout = Instance.new('UIListLayout')
	sLayout.FillDirection = Enum.FillDirection.Horizontal
	sLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	sLayout.Padding = UDim.new(0, 8)
	sLayout.Parent = sizeRow

	local sizeLbl = Instance.new('TextLabel')
	sizeLbl.BackgroundTransparency = 1
	sizeLbl.Size = UDim2.fromOffset(105, 30)
	sizeLbl.Font = Enum.Font.FredokaOne
	sizeLbl.TextSize = 13
	sizeLbl.TextColor3 = Color3.fromRGB(160, 170, 190)
	sizeLbl.Text = 'Font Size / サイズ:'
	sizeLbl.ZIndex = 11
	sizeLbl.Parent = sizeRow

	local fontSizes = {
		{ label = 'Small (20)', val = 20 },
		{ label = 'Med (32)', val = 32 },
		{ label = 'Large (44)', val = 44 },
		{ label = 'Huge (60)', val = 60 },
	}
	for _, fs in ipairs(fontSizes) do
		local sBtn = Instance.new('TextButton')
		sBtn.Name = `Size_{fs.val}`
		sBtn.Size = UDim2.fromOffset(78, 30)
		sBtn.BackgroundColor3 = (currentFontSize == fs.val) and Color3.fromRGB(60, 120, 230) or Color3.fromRGB(40, 44, 56)
		sBtn.TextColor3 = Color3.fromRGB(240, 245, 255)
		sBtn.Text = fs.label
		sBtn.Font = Enum.Font.FredokaOne
		sBtn.TextSize = 12
		sBtn.ZIndex = 12
		local sc = Instance.new('UICorner')
		sc.CornerRadius = UDim.new(0, 6)
		sc.Parent = sBtn
		sBtn.Parent = sizeRow

		sBtn.MouseButton1Click:Connect(function()
			currentFontSize = fs.val
			for _, sib in ipairs(sizeRow:GetChildren()) do
				if sib:IsA('TextButton') and sib.Name:find('Size_') then
					sib.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
				end
			end
			sBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 230)
		end)
	end

	-- Bottom modal buttons
	local modalBtnRow = Instance.new('Frame')
	modalBtnRow.BackgroundTransparency = 1
	modalBtnRow.Position = UDim2.new(0, 16, 0, 210)
	modalBtnRow.Size = UDim2.new(1, -32, 0, 40)
	modalBtnRow.ZIndex = 11
	modalBtnRow.Parent = textInputModal

	local mLayout = Instance.new('UIListLayout')
	mLayout.FillDirection = Enum.FillDirection.Horizontal
	mLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	mLayout.Padding = UDim.new(0, 10)
	mLayout.Parent = modalBtnRow

	local cancelModalBtn = Instance.new('TextButton')
	cancelModalBtn.Size = UDim2.fromOffset(130, 36)
	cancelModalBtn.BackgroundColor3 = Color3.fromRGB(50, 54, 68)
	cancelModalBtn.TextColor3 = Color3.fromRGB(230, 230, 230)
	cancelModalBtn.Text = 'Cancel / キャンセル'
	cancelModalBtn.Font = Enum.Font.FredokaOne
	cancelModalBtn.TextSize = 13
	cancelModalBtn.ZIndex = 12
	local cCorner = Instance.new('UICorner')
	cCorner.CornerRadius = UDim.new(0, 6)
	cCorner.Parent = cancelModalBtn
	cancelModalBtn.Parent = modalBtnRow

	cancelModalBtn.MouseButton1Click:Connect(function()
		textInputModal.Visible = false
	end)

	local addTextBtn = Instance.new('TextButton')
	addTextBtn.Size = UDim2.fromOffset(150, 36)
	addTextBtn.BackgroundColor3 = Color3.fromRGB(46, 125, 50)
	addTextBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	addTextBtn.Text = '➕ Add / 追加'
	addTextBtn.Font = Enum.Font.FredokaOne
	addTextBtn.TextSize = 13
	addTextBtn.ZIndex = 12
	local atCorner = Instance.new('UICorner')
	atCorner.CornerRadius = UDim.new(0, 6)
	atCorner.Parent = addTextBtn
	addTextBtn.Parent = modalBtnRow

	addTextBtn.MouseButton1Click:Connect(function()
		local str = textInputBox and textInputBox.Text or ''
		if str:gsub('%s+', '') ~= '' then
			local posY = 40 + (#localTexts * 75)
			if posY > 320 then posY = 40 end
			local entry: TextEntry = {
				text = str,
				x = 40,
				y = posY,
				color = currentColor,
				size = currentFontSize,
			}
			table.insert(localTexts, entry)
			WhiteboardController.refreshView()
			textInputBox.Text = ''
		end
		textInputModal.Visible = false
	end)

	-- Drawing gestures on Canvas (Disabled in Read-Only Mode)
	canvasWrapper.InputBegan:Connect(function(input: InputObject)
		if isReadOnlyMode then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local virtPos = screenToCanvasCoords(input.Position)
			if virtPos then
				isDrawing = true
				lastCanvasPos = virtPos
				currentStroke = {}

				if currentMode == 'eraser' then
					applyEraserAt(virtPos)
				elseif currentMode == 'draw' then
					local line: LinePoint = {
						x1 = virtPos.X,
						y1 = virtPos.Y,
						x2 = virtPos.X,
						y2 = virtPos.Y,
						color = currentColor,
						thickness = currentThickness,
					}
					table.insert(localLines, line)
					table.insert(currentStroke, line)
					renderLocalLine(line)
				end
			end
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if isReadOnlyMode then return end
		if isDrawing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local virtPos = screenToCanvasCoords(input.Position)
			if virtPos and lastCanvasPos then
				if currentMode == 'eraser' then
					applyEraserAt(virtPos)
					lastCanvasPos = virtPos
				elseif currentMode == 'draw' then
					local dist = (virtPos - lastCanvasPos).Magnitude
					if dist >= 2 then
						local line: LinePoint = {
							x1 = lastCanvasPos.X,
							y1 = lastCanvasPos.Y,
							x2 = virtPos.X,
							y2 = virtPos.Y,
							color = currentColor,
							thickness = currentThickness,
						}
						table.insert(localLines, line)
						table.insert(currentStroke, line)
						renderLocalLine(line)
						lastCanvasPos = virtPos
					end
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if isReadOnlyMode then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if isDrawing then
				isDrawing = false
				lastCanvasPos = nil
				if #currentStroke > 0 then
					table.insert(historyStrokes, currentStroke)
					currentStroke = {}
				end
			end
		end
	end)
end

function WhiteboardController.openTextInput()
	if isReadOnlyMode then return end
	if textInputModal then
		textInputModal.Visible = true
		if textInputBox then
			textInputBox:CaptureFocus()
		end
	end
end

-- Open Editor Mode (Full write / draw access via E prompt at the whiteboard)
function WhiteboardController.open(boardId: string, roomName: string)
	isReadOnlyMode = false
	currentBoardId = boardId
	currentRoomName = roomName or 'Classroom'

	if not screenGui then
		createUI()
	end

	if mainWindow then
		local title = mainWindow:FindFirstChild('Header') and mainWindow.Header:FindFirstChild('Title') :: TextLabel?
		if title then
			title.Text = `🏫 Classroom Whiteboard / 教室黒板 • {currentRoomName}`
		end
		if toolbarFrame then
			toolbarFrame.Visible = true
		end
		mainWindow.Size = UDim2.fromOffset(980, 560)
	end

	local _, _, getDataFn = getRemotes()
	if getDataFn and currentBoardId then
		local ok, data = pcall(function()
			return getDataFn:InvokeServer(currentBoardId)
		end)
		if ok and typeof(data) == 'table' then
			localLines = data.lines or {}
			localTexts = data.texts or {}
		else
			localLines = {}
			localTexts = {}
		end
	else
		localLines = {}
		localTexts = {}
	end

	historyStrokes = {}
	WhiteboardController.refreshView()

	if screenGui then
		screenGui.Enabled = true
	end
end

-- Open Student Focus Mode (Read-Only: board right in front of eyes, cannot draw or edit)
function WhiteboardController.openStudentFocus(boardId: string, roomName: string)
	isReadOnlyMode = true
	currentBoardId = boardId
	currentRoomName = roomName or 'Classroom'

	if not screenGui then
		createUI()
	end

	if mainWindow then
		local title = mainWindow:FindFirstChild('Header') and mainWindow.Header:FindFirstChild('Title') :: TextLabel?
		if title then
			title.Text = `🎯 Student Focus / 黒板に集中 • {currentRoomName} (Read-Only / 閲覧専用)`
		end
		if toolbarFrame then
			toolbarFrame.Visible = false
		end
		-- Compact sleek height without toolbar
		mainWindow.Size = UDim2.fromOffset(980, 395)
	end

	local _, _, getDataFn = getRemotes()
	if getDataFn and currentBoardId then
		local ok, data = pcall(function()
			return getDataFn:InvokeServer(currentBoardId)
		end)
		if ok and typeof(data) == 'table' then
			localLines = data.lines or {}
			localTexts = data.texts or {}
		else
			localLines = {}
			localTexts = {}
		end
	else
		localLines = {}
		localTexts = {}
	end

	historyStrokes = {}
	WhiteboardController.refreshView()

	if screenGui then
		screenGui.Enabled = true
	end
end

function WhiteboardController.close()
	if screenGui then
		screenGui.Enabled = false
	end
	if textInputModal then
		textInputModal.Visible = false
	end
	isDrawing = false
	lastCanvasPos = nil
	currentBoardId = nil
	isReadOnlyMode = false
end

-- Student Seated Button Logic
local function createStudentFocusButton()
	if studentFocusGui then studentFocusGui:Destroy() end

	studentFocusGui = Instance.new('ScreenGui')
	studentFocusGui.Name = 'StudentFocusGui'
	studentFocusGui.ResetOnSpawn = false
	studentFocusGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	studentFocusGui.Enabled = false
	studentFocusGui.Parent = playerGui

	local btn = Instance.new('TextButton')
	btn.Name = 'FocusBtn'
	btn.AnchorPoint = Vector2.new(0.5, 1)
	btn.Position = if UIScaling.isTouch() then UDim2.new(0.5, 0, 1, -95) else UDim2.new(0.5, 0, 1, -25)
	btn.Size = UDim2.fromOffset(240, 44)
	btn.BackgroundColor3 = Color3.fromRGB(35, 75, 170)
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Text = '🎯 Focus Whiteboard / 黒板を見る'
	btn.Font = Enum.Font.FredokaOne
	btn.TextSize = 15
	local bCorner = Instance.new('UICorner')
	bCorner.CornerRadius = UDim.new(0, 10)
	bCorner.Parent = btn
	local bStroke = Instance.new('UIStroke')
	bStroke.Color = Color3.fromRGB(100, 150, 255)
	bStroke.Thickness = 1.5
	bStroke.Parent = btn
	btn.Parent = studentFocusGui

	UIScaling.fit(btn, 1.1)

	btn.MouseButton1Click:Connect(function()
		if seatedDeskRoomId and seatedDeskRoomName then
			WhiteboardController.openStudentFocus(seatedDeskRoomId, seatedDeskRoomName)
		end
	end)
end

local function setupSeatedListener()
	createStudentFocusButton()

	local function checkSeat(seat: Seat?)
		if seat and seat.Parent and (seat.Parent.Name == 'SchoolDesk' or seat.Parent.Name:find('Desk')) then
			local pos = seat.Position
			local floorNum = (pos.Y > 35 and 3) or (pos.Y > 20 and 2) or 1
			local roomNum = (pos.X > -235 and 1) or (pos.X > -272 and 2) or 3
			seatedDeskRoomId = `Floor_{floorNum}_Room_{roomNum}`
			seatedDeskRoomName = `Class {floorNum}-0{roomNum}`
			if studentFocusGui then
				studentFocusGui.Enabled = true
			end
		else
			seatedDeskRoomId = nil
			seatedDeskRoomName = nil
			if studentFocusGui then
				studentFocusGui.Enabled = false
			end
			-- Close focus mode if open
			if isReadOnlyMode then
				WhiteboardController.close()
			end
		end
	end

	local function bindChar(char: Model)
		local humanoid = char:WaitForChild('Humanoid', 5) :: Humanoid?
		if humanoid then
			humanoid:GetPropertyChangedSignal('SeatPart'):Connect(function()
				checkSeat(humanoid.SeatPart :: Seat?)
			end)
			checkSeat(humanoid.SeatPart :: Seat?)
		end
	end

	if localPlayer.Character then
		bindChar(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(bindChar)
end

function WhiteboardController.init()
	createUI()
	setupSeatedListener()

	-- Live updates listener (so students in focus mode see updates in real time!)
	local updateEvent, clearEvent = getRemotes()
	if updateEvent then
		updateEvent.OnClientEvent:Connect(function(boardId: string, lines: any, texts: any)
			if currentBoardId == boardId then
				localLines = lines or {}
				localTexts = texts or {}
				WhiteboardController.refreshView()
			end
		end)
	end

	if clearEvent then
		clearEvent.OnClientEvent:Connect(function(boardId: string)
			if currentBoardId == boardId then
				localLines = {}
				localTexts = {}
				WhiteboardController.refreshView()
			end
		end)
	end

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
		if playerWhoTriggered == localPlayer and prompt.Name == 'WhiteboardPrompt' then
			local part = prompt.Parent :: BasePart
			if part then
				local boardId = part:GetAttribute('BoardId') or 'Floor_1_Room_1'
				local roomName = part:GetAttribute('RoomName') or prompt.ObjectText or 'Classroom'
				WhiteboardController.open(boardId, roomName)
			end
		end
	end)

	print('[WhiteboardController] Initialized bilingual whiteboard with student focus mode')
end

return WhiteboardController
