--!strict

-- WhiteboardService.lua
-- Mengelola 9 papan tulis ruang kelas di gedung sekolah:
-- ProximityPrompt [E], SurfaceGui di Workspace, penyimpanan data goresan & teks,
-- serta sinkronisasi ke seluruh pemain.

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local HttpService = game:GetService('HttpService')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))

local WhiteboardService = {}

type LinePoint = {
	x1: number,
	y1: number,
	x2: number,
	y2: number,
	color: string, -- Hex string e.g. "#000000"
	thickness: number,
}

type TextEntry = {
	text: string,
	x: number,
	y: number,
	color: string,
	size: number,
}

type BoardData = {
	lines: { LinePoint },
	texts: { TextEntry },
}

local boardsData: { [string]: BoardData } = {}
local boardParts: { [string]: BasePart } = {}

local function hexToColor3(hex: string): Color3
	local cleanHex = hex:gsub('#', '')
	if #cleanHex == 6 then
		local r = tonumber(cleanHex:sub(1, 2), 16) or 255
		local g = tonumber(cleanHex:sub(3, 4), 16) or 255
		local b = tonumber(cleanHex:sub(5, 6), 16) or 255
		return Color3.fromRGB(r, g, b)
	end
	return Color3.fromRGB(30, 30, 30)
end

local function renderLineOnContainer(container: Frame, line: LinePoint)
	local p1 = Vector2.new(line.x1, line.y1)
	local p2 = Vector2.new(line.x2, line.y2)
	local diff = p2 - p1
	local dist = diff.Magnitude
	if dist <= 0.5 then
		-- Dot
		local dot = Instance.new('Frame')
		dot.Name = 'Dot'
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = UDim2.fromOffset(p1.X, p1.Y)
		dot.Size = UDim2.fromOffset(line.thickness, line.thickness)
		dot.BackgroundColor3 = hexToColor3(line.color)
		dot.BorderSizePixel = 0
		local corner = Instance.new('UICorner')
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = dot
		dot.Parent = container
		return
	end

	local mid = (p1 + p2) / 2
	local angle = math.atan2(diff.Y, diff.X)

	local seg = Instance.new('Frame')
	seg.Name = 'Segment'
	seg.AnchorPoint = Vector2.new(0.5, 0.5)
	seg.Position = UDim2.fromOffset(mid.X, mid.Y)
	seg.Size = UDim2.fromOffset(dist, line.thickness)
	seg.Rotation = math.deg(angle)
	seg.BackgroundColor3 = hexToColor3(line.color)
	seg.BorderSizePixel = 0

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = seg

	seg.Parent = container
end

local function renderTextOnContainer(container: Frame, textEntry: TextEntry)
	local label = Instance.new('TextLabel')
	label.Name = 'TextNote'
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(textEntry.x, textEntry.y)
	label.Size = UDim2.new(0, 750, 0, 160)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = textEntry.size or 32
	label.TextColor3 = hexToColor3(textEntry.color or '#1E1E1E')
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.Text = textEntry.text
	label.Parent = container
end

local function refreshSurfaceGui(boardId: string)
	local part = boardParts[boardId]
	if not part then return end

	local surfaceGui = part:FindFirstChild('WhiteboardSurfaceGui') :: SurfaceGui?
	if not surfaceGui then return end

	local canvas = surfaceGui:FindFirstChild('Canvas') :: Frame?
	if not canvas then return end

	local drawContainer = canvas:FindFirstChild('DrawContainer') :: Frame?
	local textContainer = canvas:FindFirstChild('TextContainer') :: Frame?

	if drawContainer then
		drawContainer:ClearAllChildren()
	end
	if textContainer then
		textContainer:ClearAllChildren()
	end

	local data = boardsData[boardId]
	if not data then return end

	if drawContainer and data.lines then
		for _, line in ipairs(data.lines) do
			renderLineOnContainer(drawContainer, line)
		end
	end

	if textContainer and data.texts then
		for _, textEntry in ipairs(data.texts) do
			renderTextOnContainer(textContainer, textEntry)
		end
	end
end

local function setupWhiteboardPart(part: BasePart, boardId: string, roomName: string)
	part:SetAttribute('BoardId', boardId)
	part:SetAttribute('RoomName', roomName)
	boardParts[boardId] = part
	boardsData[boardId] = boardsData[boardId] or { lines = {}, texts = {} }

	-- 1. ProximityPrompt
	local prompt = part:FindFirstChild('WhiteboardPrompt') :: ProximityPrompt?
	if not prompt then
		prompt = Instance.new('ProximityPrompt')
		prompt.Name = 'WhiteboardPrompt'
		prompt.Parent = part
	end
	prompt.ActionText = 'Write / 書く'
	prompt.ObjectText = `Whiteboard ({roomName}) / 黒板`
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false

	-- 2. SurfaceGui
	local surfaceGui = part:FindFirstChild('WhiteboardSurfaceGui') :: SurfaceGui?
	if not surfaceGui then
		surfaceGui = Instance.new('SurfaceGui')
		surfaceGui.Name = 'WhiteboardSurfaceGui'
		surfaceGui.Face = Enum.NormalId.Front
		surfaceGui.CanvasSize = Vector2.new(1200, 400)
		surfaceGui.LightInfluence = 0
		surfaceGui.AlwaysOnTop = false
		surfaceGui.ZOffset = 0
		surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
		surfaceGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		surfaceGui.Parent = part
	end

	-- Canvas root
	local canvas = surfaceGui:FindFirstChild('Canvas') :: Frame?
	if not canvas then
		canvas = Instance.new('Frame')
		canvas.Name = 'Canvas'
		canvas.Size = UDim2.fromScale(1, 1)
		canvas.BackgroundColor3 = Color3.fromRGB(248, 249, 250)
		canvas.BorderSizePixel = 0
		canvas.Parent = surfaceGui

		-- Header bar on the board
		local headerBar = Instance.new('Frame')
		headerBar.Name = 'HeaderBar'
		headerBar.Size = UDim2.new(1, 0, 0, 24)
		headerBar.BackgroundColor3 = Color3.fromRGB(225, 230, 235)
		headerBar.BorderSizePixel = 0
		headerBar.Parent = canvas

		local headerTitle = Instance.new('TextLabel')
		headerTitle.Name = 'HeaderTitle'
		headerTitle.BackgroundTransparency = 1
		headerTitle.Position = UDim2.new(0, 16, 0, 2)
		headerTitle.Size = UDim2.new(1, -32, 1, -4)
		headerTitle.Font = Enum.Font.FredokaOne
		headerTitle.TextSize = 14
		headerTitle.TextColor3 = Color3.fromRGB(100, 110, 120)
		headerTitle.TextXAlignment = Enum.TextXAlignment.Left
		headerTitle.Text = `諏訪学園 (Suwa Academy) • {roomName} Whiteboard`
		headerTitle.Parent = headerBar

		-- Containers for drawings and texts
		local drawContainer = Instance.new('Frame')
		drawContainer.Name = 'DrawContainer'
		drawContainer.Size = UDim2.fromScale(1, 1)
		drawContainer.BackgroundTransparency = 1
		drawContainer.BorderSizePixel = 0
		drawContainer.ZIndex = 2
		drawContainer.Parent = canvas

		local textContainer = Instance.new('Frame')
		textContainer.Name = 'TextContainer'
		textContainer.Size = UDim2.fromScale(1, 1)
		textContainer.BackgroundTransparency = 1
		textContainer.BorderSizePixel = 0
		textContainer.ZIndex = 3
		textContainer.Parent = canvas
	end

	refreshSurfaceGui(boardId)
end

function WhiteboardService.init()
	local school = workspace:WaitForChild('LanguageAcademy'):WaitForChild('ModernJapaneseSchoolCampus'):WaitForChild('Japanese school')
	
	-- Discover and register all 9 whiteboard parts
	for _, p in ipairs(school:GetDescendants()) do
		if p:IsA('BasePart') and p.Name == 'Part' and math.abs(p.Size.Y - 5.2) < 0.6 and math.abs(p.Size.X - 15.7) < 1.2 then
			local pos = p.Position
			local floorNum = (pos.Y > 40 and 3) or (pos.Y > 22 and 2) or 1
			local roomNum = (pos.X > -210 and 1) or (pos.X > -250 and 2) or 3
			local boardId = `Floor_{floorNum}_Room_{roomNum}`
			local roomName = `Class {floorNum}-0{roomNum}`
			setupWhiteboardPart(p, boardId, roomName)
		end
	end

	-- Setup Remotes
	local updateEvent = RemoteRegistry.getEvent('WhiteboardUpdate')
	local clearEvent = RemoteRegistry.getEvent('WhiteboardClear')
	local getDataFn = RemoteRegistry.getFunction('WhiteboardGetData')

	if getDataFn then
		getDataFn.OnServerInvoke = function(player: Player, boardId: string)
			if typeof(boardId) ~= 'string' then return { lines = {}, texts = {} } end
			return boardsData[boardId] or { lines = {}, texts = {} }
		end
	end

	if updateEvent then
		updateEvent.OnServerEvent:Connect(function(player: Player, boardId: string, lines: any, texts: any)
			if typeof(boardId) ~= 'string' or not boardsData[boardId] then return end

			local data = boardsData[boardId]
			if typeof(lines) == 'table' then
				if #lines > 600 then
					local trimmed = {}
					for i = #lines - 599, #lines do
						table.insert(trimmed, lines[i])
					end
					lines = trimmed
				end
				data.lines = lines
			end

			if typeof(texts) == 'table' then
				if #texts > 25 then
					local trimmed = {}
					for i = 1, 25 do
						table.insert(trimmed, texts[i])
					end
					texts = trimmed
				end
				data.texts = texts
			end

			refreshSurfaceGui(boardId)
			updateEvent:FireAllClients(boardId, data.lines, data.texts)
		end)
	end

	if clearEvent then
		clearEvent.OnServerEvent:Connect(function(player: Player, boardId: string)
			if typeof(boardId) ~= 'string' or not boardsData[boardId] then return end
			boardsData[boardId] = { lines = {}, texts = {} }
			refreshSurfaceGui(boardId)
			clearEvent:FireAllClients(boardId)
		end)
	end

	print(`[WhiteboardService] Initialized with 9 classroom boards`)
end

return WhiteboardService
