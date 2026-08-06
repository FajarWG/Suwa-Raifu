--!strict

-- HUDController (client): menampilkan status (Yen, XP, Level) dan quest aktif.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local LocalizationService =
	require(ReplicatedStorage.Shared:WaitForChild('services'):WaitForChild('LocalizationService'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

local currentLocale = 'en'
local hudGui: ScreenGui?

local HUDController = {}

local function createGui(): ScreenGui
	if hudGui then
		return hudGui
	end
	local gui = Instance.new('ScreenGui')
	gui.Name = 'HUDGui'
	gui.ResetOnSpawn = false
	gui.Parent = PlayerGui

	-- Panel status kiri atas
	local panel = Instance.new('Frame')
	panel.Name = 'StatusPanel'
	panel.Position = UDim2.new(0, 10, 0, 10)
	panel.Size = UDim2.new(0, 200, 0, 70)
	panel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	panel.BackgroundTransparency = 0.3
	panel.BorderSizePixel = 0
	panel.Parent = gui

	local yenLabel = Instance.new('TextLabel')
	yenLabel.Name = 'Yen'
	yenLabel.Size = UDim2.new(1, 0, 0, 22)
	yenLabel.BackgroundTransparency = 1
	yenLabel.Font = Enum.Font.GothamBold
	yenLabel.TextColor3 = Color3.fromRGB(140, 220, 140)
	yenLabel.TextXAlignment = Enum.TextXAlignment.Left
	yenLabel.Parent = panel

	local xpLabel = Instance.new('TextLabel')
	xpLabel.Name = 'Xp'
	xpLabel.Position = UDim2.new(0, 0, 0, 24)
	xpLabel.Size = UDim2.new(1, 0, 0, 22)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Font = Enum.Font.Gotham
	xpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.Parent = panel

	local levelLabel = Instance.new('TextLabel')
	levelLabel.Name = 'Level'
	levelLabel.Position = UDim2.new(0, 0, 0, 48)
	levelLabel.Size = UDim2.new(1, 0, 0, 22)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextColor3 = Color3.fromRGB(220, 200, 140)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = panel

	-- Quest log kanan atas
	local questPanel = Instance.new('Frame')
	questPanel.Name = 'QuestPanel'
	questPanel.AnchorPoint = Vector2.new(1, 0)
	questPanel.Position = UDim2.new(1, -10, 0, 10)
	questPanel.Size = UDim2.new(0, 240, 0, 120)
	questPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	questPanel.BackgroundTransparency = 0.3
	questPanel.BorderSizePixel = 0
	questPanel.Parent = gui

	local questTitle = Instance.new('TextLabel')
	questTitle.Name = 'Title'
	questTitle.Size = UDim2.new(1, 0, 0, 24)
	questTitle.BackgroundTransparency = 1
	questTitle.Font = Enum.Font.GothamBold
	questTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
	questTitle.TextXAlignment = Enum.TextXAlignment.Left
	questTitle.Parent = questPanel

	local questList = Instance.new('Frame')
	questList.Name = 'List'
	questList.Position = UDim2.new(0, 0, 0, 26)
	questList.Size = UDim2.new(1, 0, 1, -26)
	questList.BackgroundTransparency = 1
	questList.Parent = questPanel

	hudGui = gui
	return gui
end

local function clearQuestList()
	if not hudGui then
		return
	end
	local list = hudGui.QuestPanel.List
	for _, child in list:GetChildren() do
		child:Destroy()
	end
end

local function setStatus(profile: ProfileTypes.Profile)
	if not hudGui then
		return
	end
	hudGui.StatusPanel.Yen.Text = '¥ ' .. tostring(profile.economy.yen)
	hudGui.StatusPanel.Xp.Text = 'JP XP: ' .. tostring(profile.progress.japaneseXp)
	hudGui.StatusPanel.Level.Text = 'Level: ' .. tostring(profile.progress.japaneseLevel)
end

local function setQuests(quests: { { id: string } })
	if not hudGui then
		return
	end
	clearQuestList()
	local list = hudGui.QuestPanel.List
	if #quests == 0 then
		local empty = Instance.new('TextLabel')
		empty.Text = LocalizationService.get(currentLocale, 'ui.questlog.empty')
		empty.Size = UDim2.new(1, 0, 0, 20)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextColor3 = Color3.fromRGB(180, 180, 180)
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.Parent = list
		return
	end
	for i, quest in quests do
		local label = Instance.new('TextLabel')
		label.Name = 'Quest' .. i
		label.Size = UDim2.new(1, 0, 0, 20)
		label.Position = UDim2.new(0, 0, 0, (i - 1) * 22)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.Gotham
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = LocalizationService.get(currentLocale, 'quest.' .. quest.id .. '.title')
		label.Parent = list
	end
end

function HUDController.setLocale(locale: string)
	currentLocale = locale
end

function HUDController.refresh(profile: ProfileTypes.Profile, quests: { { id: string } })
	setStatus(profile)
	setQuests(quests)
end

function HUDController.init()
	createGui()
	setQuests({})

	-- Ambil profile & quest aktif dari server
	task.spawn(function()
		local profile = RemoteController.invoke('GetProfile')
		if type(profile) == 'table' then
			setStatus(profile)
			local quests = RemoteController.invoke('GetQuestLog')
			if type(quests) == 'table' then
				setQuests(quests)
			end
		end
	end)
end

return HUDController
