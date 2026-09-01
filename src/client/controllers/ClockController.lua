--!strict

-- ClockController: Responsive Topbar Right JST (Japan Standard Time / Suwa & Tokyo) Clock
-- Sits in the top-right corner of the Topbar (via TopbarPlus :setRight()).
-- Integrated with SuwaTopbarMinimizer (_G.SuwaTopbarApps) so it hides when "Hide Apps" is toggled.
-- Provides players across the globe (e.g. Indonesia WIB/WITA/WIT, etc.) with accurate JST time,
-- countdown to the 20:30 Lake Suwa Fireworks (諏訪湖花火大会), and local time comparisons.

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local UserInputService = game:GetService('UserInputService')

local UIScaling = require(script.Parent:WaitForChild('UIScaling'))

local player = Players.LocalPlayer

local ClockController = {}

-- UI Elements & State
local clockIcon: any = nil

local detailsGui: ScreenGui
local detailsPanel: Frame
local liveJstLabel: TextLabel
local liveDateLabel: TextLabel
local localTimeLabel: TextLabel
local timeDiffLabel: TextLabel
local fireworksStatusLabel: TextLabel
local fireworksCountdownLabel: TextLabel
local fireworksBoxStroke: UIStroke

local isOpen = false

-- Day of week and month names
local DAYS = { 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday' }
local MONTHS = { 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec' }

-- Calculate JST (Japan Standard Time = UTC+9)
local function getJSTTable(): { [string]: any }
	local now = os.time()
	return os.date('!*t', now + 9 * 3600)
end

-- Detect player's local device time & timezone offset
local function getLocalInfo(): (string, string, number)
	local now = os.time()
	local localTable = os.date('*t', now)
	local utcTable = os.date('!*t', now)
	
	local localFormatted = string.format('%02d:%02d:%02d', localTable.hour, localTable.min, localTable.sec)
	
	-- Calculate local UTC offset in hours
	local localTimeSecs = os.time(localTable)
	local utcTimeSecs = os.time(utcTable)
	local diffHours = math.floor(((localTimeSecs - utcTimeSecs) / 3600) + 0.5)
	
	local tzName = if diffHours == 7 then 'WIB'
		elseif diffHours == 8 then 'WITA'
		elseif diffHours == 9 then 'WIT / JST'
		elseif diffHours >= 0 then `UTC+{diffHours}`
		else `UTC{diffHours}`
	
	local jstOffsetDiff = 9 - diffHours -- How many hours JST is ahead of user
	
	return localFormatted, tzName, jstOffsetDiff
end

-- Calculate equivalent local time for a given JST hour/minute
local function getLocalEquivString(jstHour: number, jstMin: number, jstOffsetDiff: number, tzName: string): string
	if jstOffsetDiff == 0 then
		return '20:30 JST'
	end
	local localHour = (jstHour - jstOffsetDiff) % 24
	if localHour < 0 then
		localHour += 24
	end
	return string.format('20:30 JST (%02d:%02d %s)', localHour, jstMin, tzName)
end

-- Calculate fireworks status (20:30 JST, show duration 10 mins / 600s)
local function getFireworksInfo(jst: { [string]: any }, jstOffsetDiff: number, tzName: string): (string, string, string, boolean, boolean)
	local currentSecs = jst.hour * 3600 + jst.min * 60 + jst.sec
	local showStartSecs = 20 * 3600 + 30 * 60 -- 20:30:00 JST (73800s)
	local isAug15 = (jst.month == 8 and jst.day == 15)
	local showDurationSecs = if isAug15 then 3600 else 600
	local showEndSecs = showStartSecs + showDurationSecs
	
	local isActive = (currentSecs >= showStartSecs and currentSecs < showEndSecs)
	local isApproaching = (not isActive and currentSecs >= (showStartSecs - 900) and currentSecs < showStartSecs)
	
	if isActive then
		local remainingSecs = math.max(0, showEndSecs - currentSecs)
		local mins = math.floor(remainingSecs / 60)
		local secs = remainingSecs % 60
		local liveLabel = string.format('🎆 LIVE (%02d:%02d)', mins, secs)
		return '🎆 Fireworks Show LIVE Now!', string.format('Show ends in %02d:%02d', mins, secs), liveLabel, true, true
	end
	
	local diffSecs = showStartSecs - currentSecs
	if diffSecs < 0 then
		diffSecs += 24 * 3600 -- Tomorrow's 20:30
	end
	
	local hours = math.floor(diffSecs / 3600)
	local mins = math.floor((diffSecs % 3600) / 60)
	local secs = diffSecs % 60
	
	local countdownText: string
	if hours > 0 then
		countdownText = string.format('Starts in %02dh %02dm %02ds', hours, mins, secs)
	else
		countdownText = string.format('Starts in %02dm %02ds', mins, secs)
	end
	
	local timeSchedule = getLocalEquivString(20, 30, jstOffsetDiff, tzName)
	local title = if isApproaching then '🎆 Fireworks Starting Soon!' else `🎆 Fireworks • {timeSchedule}`
	return title, countdownText, '', false, isApproaching
end

local function updateClock()
	local jst = getJSTTable()
	local jstTimeStr = string.format('%02d:%02d:%02d', jst.hour, jst.min, jst.sec)
	local dayName = DAYS[jst.wday] or 'Today'
	local monthName = MONTHS[jst.month] or ''
	local jstDateStr = string.format('%s, %d %s %d • %d月%d日', dayName, jst.day, monthName, jst.year, jst.month, jst.day)
	
	local localFormatted, tzName, jstOffsetDiff = getLocalInfo()
	local fireworksTitle, fireworksCountdown, liveLabel, isShowActive, isApproaching = getFireworksInfo(jst, jstOffsetDiff, tzName)
	
	-- Update Topbar Icon Label
	if clockIcon then
		if isShowActive then
			clockIcon:setLabel(liveLabel)
			clockIcon:setCaption('Lake Suwa Fireworks LIVE NOW!')
		elseif isApproaching then
			clockIcon:setLabel(`🎆 {jstTimeStr} JST`)
			clockIcon:setCaption(`Fireworks starting soon • {fireworksCountdown}`)
		else
			clockIcon:setLabel(`🕒 {jstTimeStr} JST`)
			clockIcon:setCaption('Suwa & Tokyo Time (JST • UTC+9)')
		end
	end
	
	-- Update Details Popup Panel if visible
	if detailsPanel and detailsPanel.Visible then
		liveJstLabel.Text = `{jstTimeStr} JST`
		liveDateLabel.Text = jstDateStr
		
		localTimeLabel.Text = `📍 Your Device: {localFormatted} ({tzName})`
		
		if jstOffsetDiff == 0 then
			timeDiffLabel.Text = 'You are in the same timezone as Japan (JST)!'
		elseif jstOffsetDiff > 0 then
			timeDiffLabel.Text = `Suwa, Japan is {jstOffsetDiff}h ahead of your local time`
		else
			timeDiffLabel.Text = `Suwa, Japan is {math.abs(jstOffsetDiff)}h behind your local time`
		end
		
		fireworksStatusLabel.Text = fireworksTitle
		fireworksCountdownLabel.Text = fireworksCountdown
		
		if isShowActive then
			fireworksBoxStroke.Color = Color3.fromRGB(255, 80, 80)
			fireworksStatusLabel.TextColor3 = Color3.fromRGB(255, 120, 120)
		else
			fireworksBoxStroke.Color = Color3.fromRGB(240, 175, 75)
			fireworksStatusLabel.TextColor3 = Color3.fromRGB(255, 220, 140)
		end
	end
end

local function openDetails()
	isOpen = true
	if detailsPanel then
		detailsPanel.Visible = true
		updateClock()
	end
end

local function closeDetails()
	isOpen = false
	if detailsPanel then
		detailsPanel.Visible = false
	end
	if clockIcon and clockIcon.isSelected then
		clockIcon:deselect()
	end
end

local function buildGui()
	local playerGui = player:WaitForChild('PlayerGui')
	
	local existing = playerGui:FindFirstChild('SuwaClockGui')
	if existing then
		existing:Destroy()
	end
	
	detailsGui = Instance.new('ScreenGui')
	detailsGui.Name = 'SuwaClockGui'
	detailsGui.ResetOnSpawn = false
	detailsGui.DisplayOrder = 15
	detailsGui.Parent = playerGui
	
	-- Dropdown Details Popup Panel
	detailsPanel = Instance.new('Frame')
	detailsPanel.Name = 'DetailsPanel'
	detailsPanel.AnchorPoint = Vector2.new(1, 0)
	detailsPanel.Position = UDim2.new(1, -14, 0, 46) -- Positioned right below Topbar right slot
	detailsPanel.Size = UDim2.new(0, 290, 0, 225)
	detailsPanel.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
	detailsPanel.BackgroundTransparency = 0.06
	detailsPanel.Visible = false
	detailsPanel.ZIndex = 30
	detailsPanel.Parent = detailsGui
	
	local panelCorner = Instance.new('UICorner')
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = detailsPanel
	
	local panelStroke = Instance.new('UIStroke')
	panelStroke.Color = Color3.fromRGB(140, 175, 220)
	panelStroke.Thickness = 1.2
	panelStroke.Transparency = 0.35
	panelStroke.Parent = detailsPanel
	
	UIScaling.fit(detailsPanel)
	
	local panelPadding = Instance.new('UIPadding')
	panelPadding.PaddingTop = UDim.new(0, 12)
	panelPadding.PaddingBottom = UDim.new(0, 12)
	panelPadding.PaddingLeft = UDim.new(0, 14)
	panelPadding.PaddingRight = UDim.new(0, 14)
	panelPadding.Parent = detailsPanel
	
	local panelList = Instance.new('UIListLayout')
	panelList.FillDirection = Enum.FillDirection.Vertical
	panelList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	panelList.SortOrder = Enum.SortOrder.LayoutOrder
	panelList.Padding = UDim.new(0, 8)
	panelList.Parent = detailsPanel
	
	-- Header
	local headerFrame = Instance.new('Frame')
	headerFrame.Name = 'Header'
	headerFrame.LayoutOrder = 1
	headerFrame.Size = UDim2.new(1, 0, 0, 20)
	headerFrame.BackgroundTransparency = 1
	headerFrame.ZIndex = 31
	headerFrame.Parent = detailsPanel
	
	local headerTitle = Instance.new('TextLabel')
	headerTitle.Name = 'Title'
	headerTitle.Size = UDim2.new(0.68, 0, 1, 0)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Font = Enum.Font.GothamBold
	headerTitle.TextSize = 13
	headerTitle.TextColor3 = Color3.fromRGB(240, 245, 255)
	headerTitle.TextXAlignment = Enum.TextXAlignment.Left
	headerTitle.Text = '🗾 Suwa & Tokyo Time'
	headerTitle.ZIndex = 31
	headerTitle.Parent = headerFrame
	
	local headerBadge = Instance.new('TextLabel')
	headerBadge.Name = 'Badge'
	headerBadge.AnchorPoint = Vector2.new(1, 0)
	headerBadge.Position = UDim2.new(1, 0, 0, 0)
	headerBadge.Size = UDim2.new(0.32, 0, 1, 0)
	headerBadge.BackgroundTransparency = 1
	headerBadge.Font = Enum.Font.GothamBold
	headerBadge.TextSize = 11
	headerBadge.TextColor3 = Color3.fromRGB(130, 195, 255)
	headerBadge.TextXAlignment = Enum.TextXAlignment.Right
	headerBadge.Text = 'JST (UTC+9)'
	headerBadge.ZIndex = 31
	headerBadge.Parent = headerFrame
	
	-- JST Clock Section
	local jstBox = Instance.new('Frame')
	jstBox.Name = 'JstBox'
	jstBox.LayoutOrder = 2
	jstBox.Size = UDim2.new(1, 0, 0, 48)
	jstBox.BackgroundColor3 = Color3.fromRGB(30, 36, 48)
	jstBox.BackgroundTransparency = 0.3
	jstBox.ZIndex = 31
	jstBox.Parent = detailsPanel
	
	local jstBoxCorner = Instance.new('UICorner')
	jstBoxCorner.CornerRadius = UDim.new(0, 8)
	jstBoxCorner.Parent = jstBox
	
	liveJstLabel = Instance.new('TextLabel')
	liveJstLabel.Name = 'LiveJST'
	liveJstLabel.Size = UDim2.new(1, -16, 0, 26)
	liveJstLabel.Position = UDim2.new(0, 10, 0, 3)
	liveJstLabel.BackgroundTransparency = 1
	liveJstLabel.Font = Enum.Font.GothamBold
	liveJstLabel.TextSize = 20
	liveJstLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	liveJstLabel.TextXAlignment = Enum.TextXAlignment.Left
	liveJstLabel.Text = '00:00:00 JST'
	liveJstLabel.ZIndex = 32
	liveJstLabel.Parent = jstBox
	
	liveDateLabel = Instance.new('TextLabel')
	liveDateLabel.Name = 'LiveDate'
	liveDateLabel.Size = UDim2.new(1, -16, 0, 16)
	liveDateLabel.Position = UDim2.new(0, 10, 0, 28)
	liveDateLabel.BackgroundTransparency = 1
	liveDateLabel.Font = Enum.Font.Gotham
	liveDateLabel.TextSize = 11
	liveDateLabel.TextColor3 = Color3.fromRGB(160, 175, 195)
	liveDateLabel.TextXAlignment = Enum.TextXAlignment.Left
	liveDateLabel.Text = 'Date loading...'
	liveDateLabel.ZIndex = 32
	liveDateLabel.Parent = jstBox
	
	-- Local User Device Time Section
	local localFrame = Instance.new('Frame')
	localFrame.Name = 'LocalFrame'
	localFrame.LayoutOrder = 3
	localFrame.Size = UDim2.new(1, 0, 0, 32)
	localFrame.BackgroundTransparency = 1
	localFrame.ZIndex = 31
	localFrame.Parent = detailsPanel
	
	localTimeLabel = Instance.new('TextLabel')
	localTimeLabel.Name = 'LocalTime'
	localTimeLabel.Size = UDim2.new(1, 0, 0, 16)
	localTimeLabel.BackgroundTransparency = 1
	localTimeLabel.Font = Enum.Font.GothamMedium
	localTimeLabel.TextSize = 11
	localTimeLabel.TextColor3 = Color3.fromRGB(200, 215, 235)
	localTimeLabel.TextXAlignment = Enum.TextXAlignment.Left
	localTimeLabel.Text = '📍 Your Device: 00:00:00'
	localTimeLabel.ZIndex = 31
	localTimeLabel.Parent = localFrame
	
	timeDiffLabel = Instance.new('TextLabel')
	timeDiffLabel.Name = 'TimeDiff'
	timeDiffLabel.Size = UDim2.new(1, 0, 0, 14)
	timeDiffLabel.Position = UDim2.new(0, 0, 0, 16)
	timeDiffLabel.BackgroundTransparency = 1
	timeDiffLabel.Font = Enum.Font.Gotham
	timeDiffLabel.TextSize = 10
	timeDiffLabel.TextColor3 = Color3.fromRGB(140, 155, 175)
	timeDiffLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeDiffLabel.Text = 'Suwa is 2 hours ahead of your local time'
	timeDiffLabel.ZIndex = 31
	timeDiffLabel.Parent = localFrame
	
	-- Lake Suwa Fireworks Section
	local fireworksBox = Instance.new('Frame')
	fireworksBox.Name = 'FireworksBox'
	fireworksBox.LayoutOrder = 4
	fireworksBox.Size = UDim2.new(1, 0, 0, 52)
	fireworksBox.BackgroundColor3 = Color3.fromRGB(36, 32, 48)
	fireworksBox.BackgroundTransparency = 0.25
	fireworksBox.ZIndex = 31
	fireworksBox.Parent = detailsPanel
	
	local fireCorner = Instance.new('UICorner')
	fireCorner.CornerRadius = UDim.new(0, 8)
	fireCorner.Parent = fireworksBox
	
	fireworksBoxStroke = Instance.new('UIStroke')
	fireworksBoxStroke.Color = Color3.fromRGB(240, 175, 75)
	fireworksBoxStroke.Thickness = 1
	fireworksBoxStroke.Transparency = 0.5
	fireworksBoxStroke.Parent = fireworksBox
	
	fireworksStatusLabel = Instance.new('TextLabel')
	fireworksStatusLabel.Name = 'Status'
	fireworksStatusLabel.Size = UDim2.new(1, -16, 0, 20)
	fireworksStatusLabel.Position = UDim2.new(0, 10, 0, 6)
	fireworksStatusLabel.BackgroundTransparency = 1
	fireworksStatusLabel.Font = Enum.Font.GothamBold
	fireworksStatusLabel.TextSize = 12
	fireworksStatusLabel.TextColor3 = Color3.fromRGB(255, 220, 140)
	fireworksStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
	fireworksStatusLabel.Text = '🎆 Fireworks • 20:30 JST'
	fireworksStatusLabel.ZIndex = 32
	fireworksStatusLabel.Parent = fireworksBox
	
	fireworksCountdownLabel = Instance.new('TextLabel')
	fireworksCountdownLabel.Name = 'Countdown'
	fireworksCountdownLabel.Size = UDim2.new(1, -16, 0, 18)
	fireworksCountdownLabel.Position = UDim2.new(0, 10, 0, 26)
	fireworksCountdownLabel.BackgroundTransparency = 1
	fireworksCountdownLabel.Font = Enum.Font.GothamMedium
	fireworksCountdownLabel.TextSize = 11
	fireworksCountdownLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	fireworksCountdownLabel.TextXAlignment = Enum.TextXAlignment.Left
	fireworksCountdownLabel.Text = 'Starts in 00h 00m'
	fireworksCountdownLabel.ZIndex = 32
	fireworksCountdownLabel.Parent = fireworksBox
	
	-- Close popup when clicking outside on mobile or desktop
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if not isOpen or not detailsPanel or not detailsPanel.Visible then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = input.Position
			local panelPos = detailsPanel.AbsolutePosition
			local panelSize = detailsPanel.AbsoluteSize
			
			local insidePanel = (mousePos.X >= panelPos.X and mousePos.X <= panelPos.X + panelSize.X
				and mousePos.Y >= panelPos.Y and mousePos.Y <= panelPos.Y + panelSize.Y)
			
			if not insidePanel then
				closeDetails()
			end
		end
	end)
end

function ClockController.init()
	buildGui()
	
	-- Initialize TopbarPlus Icon on the Right
	local Icon = require(ReplicatedStorage:WaitForChild('Icon'))
	
	clockIcon = Icon.new()
		:setRight()
		:setLabel('🕒 00:00:00 JST')
		:setCaption('Suwa & Tokyo Time (JST • UTC+9)')
		:bindEvent('selected', function()
			openDetails()
		end)
		:bindEvent('deselected', function()
			closeDetails()
		end)
	
	-- Register with SuwaTopbarMinimizer so clicking "Hide Apps" also hides the clock!
	task.spawn(function()
		_G.SuwaTopbarApps = _G.SuwaTopbarApps or {}
		table.insert(_G.SuwaTopbarApps, clockIcon)
	end)
	
	updateClock()
	
	-- Tick every second
	task.spawn(function()
		while true do
			task.wait(1)
			updateClock()
		end
	end)
end

return ClockController
