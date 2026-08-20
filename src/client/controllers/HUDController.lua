--!strict

-- HUDController: status Yen/XP, quest log, dan tombol School.
-- Onboarding banner dan guide beam telah dinonaktifkan total agar UI bersih dan pemain bebas beraktivitas.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))
local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local LocalizationService = require(ReplicatedStorage.Shared:WaitForChild('util'):WaitForChild('Localization'))

local HUDController = {}

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

local hudGui: ScreenGui? = nil
local currentProfile: ProfileTypes.Profile? = nil
local currentQuests: { { id: string } } = {}
local currentLocale = 'en'

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
	yenLabel.Position = UDim2.new(0, 5, 0, 5)
	yenLabel.Size = UDim2.new(1, -10, 0, 18)
	yenLabel.BackgroundTransparency = 1
	yenLabel.Font = Enum.Font.GothamBold
	yenLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
	yenLabel.TextXAlignment = Enum.TextXAlignment.Left
	yenLabel.Text = '¥ 0'
	yenLabel.Parent = panel

	local xpLabel = Instance.new('TextLabel')
	xpLabel.Name = 'Xp'
	xpLabel.Position = UDim2.new(0, 5, 0, 25)
	xpLabel.Size = UDim2.new(1, -10, 0, 18)
	xpLabel.BackgroundTransparency = 1
	xpLabel.Font = Enum.Font.Gotham
	xpLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	xpLabel.TextXAlignment = Enum.TextXAlignment.Left
	xpLabel.Text = 'JP XP: 0'
	xpLabel.Parent = panel

	local levelLabel = Instance.new('TextLabel')
	levelLabel.Name = 'Level'
	levelLabel.Position = UDim2.new(0, 5, 0, 45)
	levelLabel.Size = UDim2.new(1, -10, 0, 18)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Font = Enum.Font.Gotham
	levelLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Text = 'Level: 1'
	levelLabel.Parent = panel

	-- Panel quest kanan atas
	local questPanel = Instance.new('Frame')
	questPanel.Name = 'QuestPanel'
	questPanel.Position = UDim2.new(1, -210, 0, 10)
	questPanel.Size = UDim2.new(0, 200, 0, 90)
	questPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	questPanel.BackgroundTransparency = 0.3
	questPanel.BorderSizePixel = 0
	questPanel.Parent = gui

	local questTitle = Instance.new('TextLabel')
	questTitle.Name = 'Title'
	questTitle.Position = UDim2.new(0, 5, 0, 5)
	questTitle.Size = UDim2.new(1, -10, 0, 18)
	questTitle.BackgroundTransparency = 1
	questTitle.Font = Enum.Font.GothamBold
	questTitle.TextColor3 = Color3.fromRGB(255, 200, 100)
	questTitle.TextXAlignment = Enum.TextXAlignment.Left
	questTitle.Text = LocalizationService.get(currentLocale, 'ui.questlog.title')
	questTitle.Parent = questPanel

	local questList = Instance.new('Frame')
	questList.Name = 'List'
	questList.Position = UDim2.new(0, 5, 0, 25)
	questList.Size = UDim2.new(1, -10, 1, -30)
	questList.BackgroundTransparency = 1
	questList.Parent = questPanel

	-- Tombol School kiri (di bawah status)
	local schoolBtn = Instance.new('TextButton')
	schoolBtn.Name = 'SchoolButton'
	schoolBtn.Position = UDim2.new(0, 10, 0, 88)
	schoolBtn.Size = UDim2.new(0, 110, 0, 32)
	schoolBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 140)
	schoolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	schoolBtn.Font = Enum.Font.GothamMedium
	schoolBtn.TextSize = 13
	schoolBtn.Text = LocalizationService.get(currentLocale, 'ui.school.open')
	schoolBtn.Parent = gui

	local schoolCorner = Instance.new('UICorner')
	schoolCorner.CornerRadius = UDim.new(0, 6)
	schoolCorner.Parent = schoolBtn

	schoolBtn.MouseButton1Click:Connect(function()
		local controllers = script.Parent
		local SchoolController = require(controllers:WaitForChild('SchoolController'))
		SchoolController.togglePanel()
	end)

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
	currentProfile = profile
	hudGui.StatusPanel.Yen.Text = '¥ ' .. tostring(profile.economy.yen)
	hudGui.StatusPanel.Xp.Text = 'JP XP: ' .. tostring(profile.progress.japaneseXp)
	hudGui.StatusPanel.Level.Text = 'Level: ' .. tostring(profile.progress.japaneseLevel)
end

local function setQuests(quests: { { id: string } })
	if not hudGui then
		return
	end
	currentQuests = quests
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
	if hudGui then
		hudGui.QuestPanel.Title.Text = LocalizationService.get(currentLocale, 'ui.questlog.title')
		hudGui.SchoolButton.Text = LocalizationService.get(currentLocale, 'ui.school.open')
	end
end

function HUDController.refresh(profile: ProfileTypes.Profile, quests: { { id: string } })
	setStatus(profile)
	setQuests(quests)
end

function HUDController.init()
	createGui()
	setQuests({})

	RemoteController.onEvent('ProfileUpdated', function(profile: ProfileTypes.Profile)
		setStatus(profile)
	end)

	RemoteController.onEvent('QuestLogUpdated', function(quests: { { id: string } })
		setQuests(quests)
	end)

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
