--!strict

-- EmoteController: Integrates Emote/Dance panel cleanly into the unified Top-Right Dock.
-- Replaces the old clunky blue button on the left with a sleek [Emotes] pill button.
-- Provides chat commands: /dance, /emote, /emotes, /joget

local Players = game:GetService('Players')
local TextChatService = game:GetService('TextChatService')
local TweenService = game:GetService('TweenService')

local UIDock = require(script.Parent:WaitForChild('UIDock'))

local player = Players.LocalPlayer

local EmoteController = {}

local emoteButton: TextButton? = nil

local function getEmoteGui(): ScreenGui?
	local pGui = player:FindFirstChild('PlayerGui')
	return pGui and pGui:FindFirstChild('EmoteSystemGui') :: ScreenGui?
end

local function toggleEmotePanel()
	local emoteGui = getEmoteGui()
	if not emoteGui then return end

	local mainFrame = emoteGui:FindFirstChild('MainFrame') :: Frame?
	if not mainFrame then return end

	mainFrame.Visible = not mainFrame.Visible

	if mainFrame.Visible then
		-- Position cleanly on the right side under the top-right dock
		mainFrame.AnchorPoint = Vector2.new(1, 0)
		mainFrame.Position = UDim2.new(1, -16, 0, 58)

		local searchBar = mainFrame:FindFirstChild('SearchBar') :: TextBox?
		if searchBar then
			searchBar.Text = ''
		end

		TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(1, -16, 0, 58)
		}):Play()
	end
end

local function setupChatCommands()
	local function onChatMessage(messageText: string)
		local clean = string.lower(string.gsub(messageText, '^%s+', ''):gsub('%s+$', ''))
		if clean == '/dance' or clean == '/emote' or clean == '/emotes' or clean == '/joget' then
			toggleEmotePanel()
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

function EmoteController.toggle()
	toggleEmotePanel()
end

function EmoteController.init()
	setupChatCommands()

	-- 1. Create [Emotes] pill button in top-right dock
	local btn = UIDock.pillButton('Emotes', 1)
	btn.Name = 'EmotesButton'
	btn.ZIndex = 2
	btn.Parent = UIDock.getTopRightRow()

	btn.Activated:Connect(toggleEmotePanel)
	emoteButton = btn

	-- 2. Hide old standalone blue square button on the left
	task.spawn(function()
		local pGui = player:WaitForChild('PlayerGui', 10)
		if pGui then
			local emoteGui = pGui:WaitForChild('EmoteSystemGui', 10)
			if emoteGui then
				local oldBtn = emoteGui:WaitForChild('EmoteButton', 5)
				if oldBtn and oldBtn:IsA('GuiObject') then
					oldBtn.Visible = false
				end
			end
		end
	end)

	_G.SuwaEmotes = {
		toggle = toggleEmotePanel,
	}
end

return EmoteController
