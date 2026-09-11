--!strict

-- Cinematic Mode / Hide UI Controller (TikTok Video Recording & Aesthetic View)
-- Provides:
--   1. Clean "Hide UI" toggle pill button in the unified Top-Right Dock
--   2. Keyboard shortcut: H (on PC)
--   3. Chat commands: /hideui, /showui, /cam, /cinematic, /noui
--   4. Minimalist translucent "👁️ Show UI" restore button when HUD is hidden
--   5. Full restore on tap/click or keypress

local Players = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')
local TextChatService = game:GetService('TextChatService')

local UIDock = require(script.Parent:WaitForChild('UIDock'))

local player = Players.LocalPlayer

local CinematicController = {}

local isHidden = false
local restoreGui: ScreenGui? = nil
local restoreButton: TextButton? = nil

-- Guis that should be toggled
local MANAGED_GUIS = {
	'SuwaTopDockGui',
	'SuwaBottomDockGui',
	'EmoteSystemGui',
	'OutfitCatalogGui',
	'SuwaStatusGui',
	'SuwaSushiHUD',
	'BebeqMusicUI',
	'FishingGameGui',
	'LakesideShopGui',
}

local previousVisibility: { [string]: boolean } = {}

local function getPlayerGui(): PlayerGui?
	return player:FindFirstChild('PlayerGui') :: PlayerGui?
end

local function setHUDHidden(hidden: boolean)
	isHidden = hidden
	local pGui = getPlayerGui()
	if not pGui then
		return
	end

	if hidden then
		-- Hide all managed ScreenGuis
		for _, name in ipairs(MANAGED_GUIS) do
			local g = pGui:FindFirstChild(name)
			if g and g:IsA('ScreenGui') then
				previousVisibility[name] = g.Enabled
				g.Enabled = false
			end
		end

		-- Also hide TopDock row directly
		local topRow = pGui:FindFirstChild('SuwaTopDockGui')
		if topRow then
			local row = topRow:FindFirstChild('Row')
			if row and row:IsA('GuiObject') then
				row.Visible = false
			end
		end

		-- Show the discreet Restore button
		if restoreGui then
			restoreGui.Enabled = true
		end
	else
		-- Restore all managed ScreenGuis
		for _, name in ipairs(MANAGED_GUIS) do
			local g = pGui:FindFirstChild(name)
			if g and g:IsA('ScreenGui') then
				local prev = previousVisibility[name]
				g.Enabled = if prev ~= nil then prev else true
			end
		end

		local topRow = pGui:FindFirstChild('SuwaTopDockGui')
		if topRow then
			local row = topRow:FindFirstChild('Row')
			if row and row:IsA('GuiObject') then
				row.Visible = true
			end
		end

		-- Hide the Restore button
		if restoreGui then
			restoreGui.Enabled = false
		end
	end
end

local function toggle()
	setHUDHidden(not isHidden)
end

local function buildRestoreButton()
	local pGui = player:WaitForChild('PlayerGui')
	local gui = Instance.new('ScreenGui')
	gui.Name = 'SuwaCinematicRestoreGui'
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 999
	gui.Parent = pGui
	restoreGui = gui

	-- Discreet semi-transparent restore pill at top right corner
	local btn = Instance.new('TextButton')
	btn.Name = 'RestoreButton'
	btn.AnchorPoint = Vector2.new(1, 0)
	btn.Position = UDim2.new(1, -16, 0, 16)
	btn.Size = UDim2.new(0, 110, 0, 36)
	btn.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	btn.BackgroundTransparency = 0.55
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 12
	btn.TextColor3 = Color3.fromRGB(220, 235, 255)
	btn.Text = '👁️ Show UI'
	btn.AutoButtonColor = true

	local corner = Instance.new('UICorner')
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = btn

	local stroke = Instance.new('UIStroke')
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Thickness = 1
	stroke.Transparency = 0.7
	stroke.Parent = btn

	btn.Activated:Connect(function()
		setHUDHidden(false)
	end)

	btn.Parent = gui
	restoreButton = btn
end

local function setupChatCommands()
	local function onChatMessage(messageText: string)
		local clean = string.lower(string.gsub(messageText, '^%s+', ''):gsub('%s+$', ''))
		if clean == '/hideui' or clean == '/cinematic' or clean == '/cam' or clean == '/noui' or clean == '/clearscreen' then
			setHUDHidden(true)
		elseif clean == '/showui' or clean == '/openui' then
			setHUDHidden(false)
		elseif clean == '/toggleui' then
			toggle()
		end
	end

	player.Chatted:Connect(onChatMessage)

	task.spawn(function()
		pcall(function()
			if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
				local textChannels = TextChatService:WaitForChild('TextChannels', 5)
				if textChannels then
					local rbxGeneral = textChannels:WaitForChild('RBXGeneral', 5)
					if rbxGeneral and rbxGeneral:IsA('TextChannel') then
						rbxGeneral.MessageReceived:Connect(function(textChatMessage)
							if textChatMessage.TextSource and textChatMessage.TextSource.UserId == player.UserId then
								onChatMessage(textChatMessage.Text)
							end
						end)
					end
				end
			end
		end)
	end)
end

function CinematicController.init()
	buildRestoreButton()
	setupChatCommands()

	-- Add Hide UI pill button in the top-right dock
	local hideBtn = UIDock.pillButton('Hide UI', 10)
	hideBtn.Name = 'HideUIButton'
	hideBtn.ZIndex = 2
	hideBtn.Parent = UIDock.getTopRightRow()

	hideBtn.Activated:Connect(function()
		setHUDHidden(true)
	end)

	-- Hotkey H on PC / Keyboard
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.H then
			toggle()
		end
	end)

	_G.SuwaCinematic = {
		toggle = toggle,
		setHidden = setHUDHidden,
		isHidden = function()
			return isHidden
		end,
	}
end

return CinematicController
