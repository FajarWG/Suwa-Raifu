--!strict

-- HUDController (client): menampilkan status (Yen, XP, Level) dan quest aktif.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')

local RemoteController = require(script.Parent:WaitForChild('RemoteController'))
local LocalizationService =
	require(ReplicatedStorage.Shared:WaitForChild('services'):WaitForChild('LocalizationService'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild('PlayerGui')

local currentLocale = 'en'
local hudGui: ScreenGui?
local currentProfile: ProfileTypes.Profile? = nil
local currentQuests: { { id: string } } = {}
local sakuraHighlight: Highlight? = nil
local navBeam: Beam? = nil
local navFromAttachment: Attachment? = nil
local navToAttachment: Attachment? = nil

local HUDController = {}

local function getSakuraBody(): BasePart?
	local npcs = Workspace:FindFirstChild('NPCs')
	if npcs then
		local sakuraModel = npcs:FindFirstChild('teacher_sakura')
		if sakuraModel and sakuraModel:IsA('Model') then
			local body = sakuraModel:FindFirstChild('Body')
			if body and body:IsA('BasePart') then
				return body
			end
		end
	end

	local direct = Workspace:FindFirstChild('teacher_sakura')
	if direct and direct:IsA('Model') then
		local body = direct:FindFirstChild('Body')
		if body and body:IsA('BasePart') then
			return body
		end
	end

	return nil
end

local function getCharacterRoot(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local root = character:FindFirstChild('HumanoidRootPart')
	if root and root:IsA('BasePart') then
		return root
	end
	return nil
end

local function hasQuest(questId: string): boolean
	for _, quest in currentQuests do
		if quest.id == questId then
			return true
		end
	end
	return false
end

local function isQuestCompleted(questId: string): boolean
	if not currentProfile then
		return false
	end
	for _, completedId in currentProfile.quests.completed do
		if completedId == questId then
			return true
		end
	end
	return false
end

local function shouldShowOnboarding(): boolean
	if isQuestCompleted('quest_intro') then
		return false
	end
	if hasQuest('quest_intro') then
		return false
	end
	return true
end

local function clearNavigationAssist()
	if navBeam then
		navBeam:Destroy()
		navBeam = nil
	end
	if navFromAttachment then
		navFromAttachment:Destroy()
		navFromAttachment = nil
	end
	if navToAttachment then
		navToAttachment:Destroy()
		navToAttachment = nil
	end
	if sakuraHighlight then
		sakuraHighlight:Destroy()
		sakuraHighlight = nil
	end
end

local function ensureNavigationAssist(root: BasePart, sakuraBody: BasePart)
	if not sakuraHighlight then
		local model = sakuraBody:FindFirstAncestorOfClass('Model')
		if model then
			local highlight = Instance.new('Highlight')
			highlight.Name = 'OnboardingSakuraHighlight'
			highlight.FillColor = Color3.fromRGB(255, 214, 102)
			highlight.OutlineColor = Color3.fromRGB(255, 248, 210)
			highlight.FillTransparency = 0.58
			highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			highlight.Adornee = model
			highlight.Parent = model
			sakuraHighlight = highlight
		end
	end

	if not navFromAttachment or navFromAttachment.Parent ~= root then
		if navFromAttachment then
			navFromAttachment:Destroy()
		end
		navFromAttachment = Instance.new('Attachment')
		navFromAttachment.Name = 'OnboardingNavFrom'
		navFromAttachment.Position = Vector3.new(0, 1.6, 0)
		navFromAttachment.Parent = root
	end

	if not navToAttachment or navToAttachment.Parent ~= sakuraBody then
		if navToAttachment then
			navToAttachment:Destroy()
		end
		navToAttachment = Instance.new('Attachment')
		navToAttachment.Name = 'OnboardingNavTo'
		navToAttachment.Position = Vector3.new(0, 3, 0)
		navToAttachment.Parent = sakuraBody
	end

	if not navBeam or navBeam.Parent ~= root then
		if navBeam then
			navBeam:Destroy()
		end
		navBeam = Instance.new('Beam')
		navBeam.Name = 'OnboardingGuideBeam'
		navBeam.FaceCamera = true
		navBeam.Width0 = 0.09
		navBeam.Width1 = 0.12
		navBeam.LightEmission = 0.9
		navBeam.LightInfluence = 0
		navBeam.Transparency = NumberSequence.new(0.12)
		navBeam.Color = ColorSequence.new(Color3.fromRGB(120, 229, 255), Color3.fromRGB(255, 243, 170))
		navBeam.Parent = root
	end

	navBeam.Attachment0 = navFromAttachment
	navBeam.Attachment1 = navToAttachment
end

local function directionHint(from: Vector3, to: Vector3): string
	local delta = to - from
	if delta.Magnitude < 2 then
		return 'You are at Sakura.'
	end
	local eastWest = if delta.X > 0 then 'east' else 'west'
	local northSouth = if delta.Z > 0 then 'south' else 'north'
	if math.abs(delta.X) > math.abs(delta.Z) * 1.5 then
		return `Move {eastWest}.`
	elseif math.abs(delta.Z) > math.abs(delta.X) * 1.5 then
		return `Move {northSouth}.`
	end
	return `Move {northSouth}-{eastWest}.`
end

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
	questTitle.Text = LocalizationService.get(currentLocale, 'ui.questlog.title')
	questTitle.TextColor3 = Color3.fromRGB(255, 220, 120)
	questTitle.TextXAlignment = Enum.TextXAlignment.Left
	questTitle.Parent = questPanel

	local questList = Instance.new('Frame')
	questList.Name = 'List'
	questList.Position = UDim2.new(0, 0, 0, 26)
	questList.Size = UDim2.new(1, 0, 1, -26)
	questList.BackgroundTransparency = 1
	questList.Parent = questPanel

	-- Tombol buka panel sekolah
	local schoolBtn = Instance.new('TextButton')
	schoolBtn.Name = 'SchoolButton'
	schoolBtn.Position = UDim2.new(0, 10, 0, 90)
	schoolBtn.Size = UDim2.new(0, 110, 0, 30)
	schoolBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 140)
	schoolBtn.Font = Enum.Font.Gotham
	schoolBtn.Text = LocalizationService.get(currentLocale, 'ui.school.open')
	schoolBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	schoolBtn.Parent = gui
	schoolBtn.Activated:Connect(function()
		local SchoolController = require(script.Parent:WaitForChild('SchoolController'))
		SchoolController.open()
	end)

	local onboardingPanel = Instance.new('Frame')
	onboardingPanel.Name = 'OnboardingPanel'
	onboardingPanel.AnchorPoint = Vector2.new(0.5, 0)
	onboardingPanel.Position = UDim2.new(0.5, 0, 0, 10)
	onboardingPanel.Size = UDim2.new(0, 440, 0, 88)
	onboardingPanel.BackgroundColor3 = Color3.fromRGB(22, 32, 45)
	onboardingPanel.BackgroundTransparency = 0.16
	onboardingPanel.BorderSizePixel = 0
	onboardingPanel.Visible = false
	onboardingPanel.Parent = gui

	local onboardingTitle = Instance.new('TextLabel')
	onboardingTitle.Name = 'Title'
	onboardingTitle.Position = UDim2.new(0, 12, 0, 6)
	onboardingTitle.Size = UDim2.new(1, -24, 0, 24)
	onboardingTitle.BackgroundTransparency = 1
	onboardingTitle.Font = Enum.Font.GothamBold
	onboardingTitle.TextColor3 = Color3.fromRGB(255, 236, 170)
	onboardingTitle.TextXAlignment = Enum.TextXAlignment.Left
	onboardingTitle.Text = 'Onboarding: Find Teacher Sakura'
	onboardingTitle.Parent = onboardingPanel

	local onboardingHint = Instance.new('TextLabel')
	onboardingHint.Name = 'Hint'
	onboardingHint.Position = UDim2.new(0, 12, 0, 30)
	onboardingHint.Size = UDim2.new(1, -24, 0, 24)
	onboardingHint.BackgroundTransparency = 1
	onboardingHint.Font = Enum.Font.Gotham
	onboardingHint.TextColor3 = Color3.fromRGB(199, 222, 241)
	onboardingHint.TextXAlignment = Enum.TextXAlignment.Left
	onboardingHint.Text = 'Follow the guidance line and approach Sakura.'
	onboardingHint.Parent = onboardingPanel

	local onboardingDistance = Instance.new('TextLabel')
	onboardingDistance.Name = 'Distance'
	onboardingDistance.Position = UDim2.new(0, 12, 0, 54)
	onboardingDistance.Size = UDim2.new(1, -24, 0, 24)
	onboardingDistance.BackgroundTransparency = 1
	onboardingDistance.Font = Enum.Font.GothamBold
	onboardingDistance.TextColor3 = Color3.fromRGB(125, 234, 255)
	onboardingDistance.TextXAlignment = Enum.TextXAlignment.Left
	onboardingDistance.Text = 'Distance: --'
	onboardingDistance.Parent = onboardingPanel

	hudGui = gui
	return gui
end

local function updateOnboardingDisplay()
	if not hudGui then
		return
	end

	local panel = hudGui:FindFirstChild('OnboardingPanel')
	if not panel or not panel:IsA('Frame') then
		return
	end

	if not shouldShowOnboarding() then
		panel.Visible = false
		clearNavigationAssist()
		return
	end

	panel.Visible = true
	local hint = panel:FindFirstChild('Hint')
	local distanceLabel = panel:FindFirstChild('Distance')
	if not hint or not hint:IsA('TextLabel') or not distanceLabel or not distanceLabel:IsA('TextLabel') then
		return
	end

	local root = getCharacterRoot()
	local sakuraBody = getSakuraBody()
	if not root or not sakuraBody then
		hint.Text = 'Waiting for Sakura marker...'
		distanceLabel.Text = 'Distance: --'
		clearNavigationAssist()
		return
	end

	ensureNavigationAssist(root, sakuraBody)
	local distance = (sakuraBody.Position - root.Position).Magnitude
	distanceLabel.Text = `Distance: {math.floor(distance)} studs`
	if distance <= 10 then
		hint.Text = 'Sakura is nearby. Press Talk on the prompt.'
	else
		hint.Text = directionHint(root.Position, sakuraBody.Position)
	end
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
	updateOnboardingDisplay()
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
	updateOnboardingDisplay()
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
	RunService.RenderStepped:Connect(updateOnboardingDisplay)

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
