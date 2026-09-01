--!strict

-- Lets a player set a short status line that floats above their head, above
-- the default nameplate (e.g. "menunggu teman", "べんきょうしています"). Text
-- is capped at Config.statusMaxLength and always goes through TextService
-- before anyone else can see it, since it is free-form player input.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TextService = game:GetService('TextService')

local RemoteRegistry = require(script.Parent:WaitForChild('RemoteRegistryService'))
local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))

local StatusService = {}

local TAG_NAME = 'SuwaStatusTag'
local pending: { [Player]: number } = {} -- request stamp, so a slow filter never clobbers a newer one
local currentStatus: { [Player]: string } = {}

local function clearTag(character: Model)
	local head = character:FindFirstChild('Head')
	local existing = head and head:FindFirstChild(TAG_NAME)
	if existing then
		existing:Destroy()
	end
	for _, desc in character:GetDescendants() do
		if desc:IsA('BillboardGui') and desc.Name == TAG_NAME then
			desc:Destroy()
		end
	end
end

local function buildTag(character: Model, text: string)
	local head = character:FindFirstChild('Head')
	if not head or not head:IsA('BasePart') then
		return
	end
	clearTag(character)

	local gui = Instance.new('BillboardGui')
	gui.Name = TAG_NAME
	gui.Size = UDim2.fromOffset(220, 40)
	-- Sits above the default nameplate/health bar so the two never overlap.
	gui.StudsOffset = Vector3.new(0, 3.1, 0)
	gui.AlwaysOnTop = true
	gui.Adornee = head
	gui.Parent = head

	local label = Instance.new('TextLabel')
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(25, 42, 49)
	label.BackgroundTransparency = 0.18
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Text = text
	label.Parent = gui

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function applyStatus(player: Player, filtered: string)
	local character = player.Character
	if filtered == '' then
		currentStatus[player] = nil
		if character then
			clearTag(character)
		end
	else
		currentStatus[player] = filtered
		if character then
			buildTag(character, filtered)
		end
	end
end

local function setStatus(player: Player, rawText: unknown)
	local text = if typeof(rawText) == 'string' then rawText else ''
	local trimmed = text:gsub('^%s+', ''):gsub('%s+$', '')

	-- #trimmed counts bytes, not characters: a Japanese/CJK status is ~3
	-- bytes per character, so byte-based truncation used to slice a
	-- character in half and render as a broken glyph. utf8.offset finds the
	-- real character boundary instead.
	local length = utf8.len(trimmed)
	if length and length > Config.statusMaxLength then
		local cutByte = utf8.offset(trimmed, Config.statusMaxLength + 1)
		if cutByte then
			trimmed = trimmed:sub(1, cutByte - 1)
		end
	elseif not length then
		-- Malformed UTF-8; fall back to a safe byte cap rather than risk a
		-- filter call on garbage input.
		trimmed = trimmed:sub(1, Config.statusMaxLength)
	end

	local stamp = (pending[player] or 0) + 1
	pending[player] = stamp

	if trimmed == '' then
		applyStatus(player, '')
		return
	end

	task.spawn(function()
		local ok, result = pcall(function()
			local filterResult = TextService:FilterStringAsync(trimmed, player.UserId)
			return filterResult:GetNonChatStringForBroadcastAsync()
		end)

		-- A newer request landed while this filter call was in flight; drop this one.
		if pending[player] ~= stamp then
			return
		end

		if ok and typeof(result) == 'string' then
			applyStatus(player, result)
		else
			warn(`[Status] Filter failed for {player.Name}: {result}`)
		end
	end)
end

function StatusService.init()
	RemoteRegistry.registerEvent('SetStatus', setStatus)
	RemoteRegistry.registerEvent('ClearStatus', function(player: Player)
		setStatus(player, '')
	end)

	local function hookPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			local status = currentStatus[player]
			if status and status ~= '' then
				local head = character:WaitForChild('Head', 5)
				if head and currentStatus[player] == status then
					buildTag(character, status)
				end
			end
		end)
	end

	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end
	Players.PlayerAdded:Connect(hookPlayer)

	Players.PlayerRemoving:Connect(function(player)
		pending[player] = nil
		currentStatus[player] = nil
	end)
end

return StatusService
