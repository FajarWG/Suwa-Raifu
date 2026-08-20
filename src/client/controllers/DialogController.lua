--!strict

-- DialogController (client): mendeteksi ProximityPrompt NPC, membuka dialog,
-- menampilkan teks, dan mengirim pilihan ke server.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local LocalizationService =
	require(ReplicatedStorage.Shared:WaitForChild('services'):WaitForChild('LocalizationService'))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

-- Cache localization locale dari profile (di-set oleh ProfileController)
local currentLocale = 'en'

-- Dialog UI state
local dialogGui: ScreenGui?

local DialogController = {}

local function createDialogGui(): ScreenGui
	if dialogGui then
		dialogGui.Enabled = true
		return dialogGui
	end

	local gui = Instance.new('ScreenGui')
	gui.Name = 'DialogGui'
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	local frame = Instance.new('Frame')
	frame.Name = 'DialogFrame'
	frame.AnchorPoint = Vector2.new(0.5, 1)
	frame.Position = UDim2.new(0.5, 0, 1, -40)
	frame.Size = UDim2.new(0.8, 0, 0, 180)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = gui

	local speaker = Instance.new('TextLabel')
	speaker.Name = 'Speaker'
	speaker.Size = UDim2.new(1, 0, 0, 30)
	speaker.BackgroundTransparency = 1
	speaker.Font = Enum.Font.GothamBold
	speaker.TextColor3 = Color3.fromRGB(255, 220, 120)
	speaker.TextScaled = true
	speaker.TextXAlignment = Enum.TextXAlignment.Left
	speaker.Parent = frame

	local text = Instance.new('TextLabel')
	text.Name = 'Text'
	text.Position = UDim2.new(0, 0, 0, 35)
	text.Size = UDim2.new(1, 0, 0, 70)
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.Gotham
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.TextWrapped = true
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.TextYAlignment = Enum.TextYAlignment.Top
	text.Parent = frame

	local choices = Instance.new('Frame')
	choices.Name = 'Choices'
	choices.Position = UDim2.new(0, 0, 0, 110)
	choices.Size = UDim2.new(1, 0, 0, 65)
	choices.BackgroundTransparency = 1
	choices.Parent = frame

	dialogGui = gui
	return gui
end

local function closeDialog()
	if dialogGui then
		dialogGui.Enabled = false
	end
end

local function clearChoices()
	if not dialogGui then
		return
	end
	local choices = dialogGui.DialogFrame.Choices
	for _, child in choices:GetChildren() do
		child:Destroy()
	end
end

local function showLines(npcName: string, lines: { { key: string } }, onDone: () -> ())
	if not dialogGui then
		return
	end
	local frame = dialogGui.DialogFrame
	frame.Speaker.Text = LocalizationService.get(currentLocale, npcName)

	local index = 0
	local continueButton: TextButton = Instance.new('TextButton')
	continueButton.Name = 'Continue'
	continueButton.Size = UDim2.new(0.15, 0, 0, 30)
	continueButton.Position = UDim2.new(1, -60, 0.5, -15)
	continueButton.BackgroundColor3 = Color3.fromRGB(60, 90, 140)
	continueButton.Font = Enum.Font.Gotham
	continueButton.Text = LocalizationService.get(currentLocale, 'ui.dialog.continue')
	continueButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	continueButton.Parent = frame

	local function showNext()
		index += 1
		if index > #lines then
			continueButton:Destroy()
			onDone()
			return
		end
		frame.Text.Text = LocalizationService.get(currentLocale, lines[index].key)
	end
	continueButton.Activated:Connect(showNext)
	showNext()
end

local function showChoices(choices: { { textKey: string, next: string?, action: string? } }, onPick: (choice) -> ())
	if not dialogGui then
		return
	end
	clearChoices()
	local choicesFrame = dialogGui.DialogFrame.Choices
	for i, choice in choices do
		local button = Instance.new('TextButton')
		button.Name = 'Choice' .. i
		button.Size = UDim2.new(1, 0, 0, 28)
		button.Position = UDim2.new(0, 0, 0, (i - 1) * 32)
		button.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
		button.Text = LocalizationService.get(currentLocale, choice.textKey)
		button.Font = Enum.Font.Gotham
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Parent = choicesFrame
		button.Activated:Connect(function()
			onPick(choice)
		end)
	end
end

-- Navigasi node: tampilkan baris, lalu pilihan / lanjut / tutup.
local function showNode(npc: { id: string, displayNameKey: string }, node: { lines: any, choices: any, next: string? })
	local function handleAction(action: string?)
		if action then
			local questId = action:match('^quest_accept:(.+)$')
			if questId then
				RemoteController.fire('QuestAccept', questId)
				return
			end
			questId = action:match('^quest_claim:(.+)$')
			if questId then
				RemoteController.fire('QuestClaim', questId)
			end
		end
	end

	showLines(npc.displayNameKey, node.lines, function()
		if node.choices and #node.choices > 0 then
			showChoices(node.choices, function(choice)
				handleAction(choice.action)
				if choice.next then
					local result = RemoteController.invoke('NPCGetDialog', npc.id, choice.next)
					if result and result.node then
						showNode(npc, result.node)
					else
						closeDialog()
					end
				else
					closeDialog()
				end
			end)
		elseif node.next then
			local result = RemoteController.invoke('NPCGetDialog', npc.id, node.next)
			if result and result.node then
				showNode(npc, result.node)
			else
				closeDialog()
			end
		else
			closeDialog()
		end
	end)
end

-- Buka dialog untuk NPC: fetch root node dari server, tampilkan.
local function openDialog(npcId: string)
	local gui = createDialogGui()
	gui.Enabled = true

	local result = RemoteController.invoke('NPCGetDialog', npcId, nil)
	if not result or not result.node then
		closeDialog()
		return
	end

	local npc = { id = npcId, displayNameKey = 'npc.' .. npcId .. '.name' }
	showNode(npc, result.node)
end

function DialogController.setLocale(locale: string)
	currentLocale = locale
end

function DialogController.init()
	-- Deteksi prompt NPC
	RemoteController.onEvent('NPCOpenDialog', function(payload)
		if type(payload) ~= 'table' then
			return
		end
		openDialog(payload.npcId)
	end)

	-- Cari ProximityPrompt di Workspace (NPC model)
	local function connectPrompt(prompt: ProximityPrompt)
		if prompt.Name ~= 'InteractPrompt' then
			return
		end
		local npcId = prompt.ObjectText
		prompt.Triggered:Connect(function()
			RemoteController.fire('NPCInteract', npcId)
		end)
	end

	-- Scan NPC yang sudah ada + yang baru muncul
	for _, model in workspace:GetChildren() do
		local prompt = model:FindFirstChild('InteractPrompt', true)
		if prompt and prompt:IsA('ProximityPrompt') then
			connectPrompt(prompt)
		end
	end
	workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA('ProximityPrompt') and desc.Name == 'InteractPrompt' then
			connectPrompt(desc)
		end
	end)
end

return DialogController
