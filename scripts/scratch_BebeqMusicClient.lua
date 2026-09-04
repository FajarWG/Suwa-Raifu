--[[
    ____       __                 _____                                
   / __ )___  / /_  ___  ____ _  / ___/__  ______  ________  ____ ___  ___ 
  / __  / _ \/ __ \/ _ \/ __ `/  \__ \/ / / / __ \/ ___/ _ \/ __ `__ \/ _ \
 / /_/ /  __/ /_/ /  __/ /_/ /  ___/ / /_/ / /_/ / /  /  __/ / / / / /  __/
/_____/\___/_.___/\___/\__, /  /____/\__,_/ .___/_/   \___/_/ /_/ /_/\___/ 
                         /_/             /_/                               

Script by / Dibuat oleh : Bebeq (Optimized & Bugfixed for Suwa-Raifu)
Script 					: Clubkit Music System
Version / Versi         : 1.1 (Japanese Countryside Edition)
]]

local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider  = game:GetService("ContentProvider")
local SoundService     = game:GetService("SoundService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local localPlayer = Players.LocalPlayer
local playerGui   = localPlayer:WaitForChild("PlayerGui")

local Config       = require(ReplicatedStorage:WaitForChild("BebeqMusicSystem"):WaitForChild("BebeqMusicConfig"))
local ColorPalette = require(ReplicatedStorage:WaitForChild("BebeqColor"):WaitForChild("BebeqColorPalette"))
local Icon         = require(ReplicatedStorage:WaitForChild("Icon"))
local S            = Config.Settings

local function computeIsAdmin()
	if localPlayer.UserId == game.CreatorId or localPlayer.UserId == 9261166252 then return true end
	for _, v in ipairs(Config.Whitelist or {}) do
		if type(v) == "number" and v == localPlayer.UserId then return true end
		if type(v) == "string" and string.lower(v) == string.lower(localPlayer.Name) then return true end
	end
	return false
end
local localIsAdmin = computeIsAdmin()

local remotes     = ReplicatedStorage:WaitForChild("BebeqMusicSystem"):WaitForChild("BebeqMusicRemotes")
local NowPlaying  = remotes:WaitForChild("NowPlaying")
local QueueUpdate = remotes:WaitForChild("QueueUpdate")
local VoteUpdate  = remotes:WaitForChild("VoteUpdate")
local Notify      = remotes:WaitForChild("Notify")
local RequestSong = remotes:WaitForChild("RequestSong")
local VoteSkip    = remotes:WaitForChild("VoteSkip")
local AdminSkip   = remotes:WaitForChild("AdminSkip")
local ReportDuration = remotes:WaitForChild("ReportDuration")
local DurationUpdate = remotes:WaitForChild("DurationUpdate")
local PreloadList = remotes:WaitForChild("PreloadList")
local GetState    = remotes:WaitForChild("GetState")

local C = {
	bg      = ColorPalette.ActiveTheme.Background,
	panel   = ColorPalette.ActiveTheme.Surface,
	panel2  = ColorPalette.ActiveTheme.SurfaceElevated,
	panel3  = ColorPalette.ActiveTheme.SurfaceHighest,
	stroke  = ColorPalette.ActiveTheme.Border,
	accent  = ColorPalette.ActiveTheme.Primary,
	text    = ColorPalette.ActiveTheme.TextMain,
	subtext = ColorPalette.ActiveTheme.TextMuted,
	divider = ColorPalette.ActiveTheme.Divider,
}

local sound = Instance.new("Sound")
sound.Name = "BebeqMusicSound"
sound.Looped = false
sound.Volume = S.DefaultVolume
sound.Parent = SoundService

local userVolume = S.DefaultVolume
local muted = false
local current = nil

local function effectiveVolume()
	return muted and 0 or userVolume
end

local probed = {}

local function probeAndReport(index)
	if probed[index] then return end
	local t = Config.Playlist[index]
	if not t then return end
	probed[index] = true

	task.spawn(function()
		local probe = Instance.new("Sound")
		probe.Name = "BebeqMusicProbe"
		probe.SoundId = t.soundId
		probe.Parent = SoundService

		local status
		pcall(function()
			ContentProvider:PreloadAsync({ probe }, function(_, st)
				status = st
			end)
		end)

		local tries = 0
		while probe.TimeLength <= 0 and tries < 25 do
			task.wait(0.1)
			tries += 1
		end

		local len = probe.TimeLength
		probe:Destroy()

		local failed = (status == Enum.AssetFetchStatus.Failure)
			or (status == Enum.AssetFetchStatus.TimedOut)
			or (len <= 0)

		ReportDuration:FireServer(index, len, failed)
	end)
end

local function preloadWindow(indices)
	if type(indices) ~= "table" then return end
	for _, index in ipairs(indices) do
		probeAndReport(index)
	end
end

local function playSynced(packet)
	current = packet
	if not packet then
		sound:Stop()
		return
	end

	sound:Stop()
	sound.SoundId = packet.soundId
	sound.Volume  = effectiveVolume()

	local function offsetNow()
		local e = workspace:GetServerTimeNow() - packet.startTime
		if e < 0 then e = 0 end
		local dur = packet.duration
		if (not dur or dur <= 0) and sound.TimeLength > 0 then
			dur = sound.TimeLength
		end
		if dur and dur > 0 then
			e = e % dur
		else
			if sound.TimeLength > 0 then
				e = e % sound.TimeLength
			else
				e = 0
			end
		end
		return e
	end

	pcall(function()
		sound.TimePosition = offsetNow()
	end)
	sound:Play()

	task.spawn(function()
		if not sound.IsLoaded then
			local t0 = os.clock()
			while not sound.IsLoaded and (os.clock() - t0) < 5 do
				task.wait(0.1)
			end
		end
		if current == packet and sound.IsLoaded then
			pcall(function()
				local off = offsetNow()
				if sound.TimeLength > 0 and off >= sound.TimeLength then
					off = off % sound.TimeLength
				end
				sound.TimePosition = off
			end)
			if not sound.Playing then
				sound:Play()
			end
		end
	end)
end

task.spawn(function()
	while true do
		task.wait(2)
		if current and sound.IsLoaded and sound.Playing then
			local dur = current.duration
			if (not dur or dur <= 0) and sound.TimeLength > 0 then
				dur = sound.TimeLength
			end
			if dur and dur > 0 then
				local expected = (workspace:GetServerTimeNow() - current.startTime) % dur
				if expected >= 0 and math.abs(sound.TimePosition - expected) > S.SyncDriftTolerance then
					pcall(function()
						sound.TimePosition = expected
					end)
				end
			end
		end
	end
end)

---------------------------------------------------------
-- [ UI HELPERS ]
---------------------------------------------------------
local function mk(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		o[k] = v
	end
	if parent then o.Parent = parent end
	return o
end
local function corner(p, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 8) }, p) end
local function stroke(p, col, th) mk("UIStroke", { Color = col or C.stroke, Thickness = th or 1, Transparency = 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end
local function pad(p, n) mk("UIPadding", { PaddingTop = UDim.new(0,n), PaddingBottom = UDim.new(0,n), PaddingLeft = UDim.new(0,n), PaddingRight = UDim.new(0,n) }, p) end

local PANEL_W, PANEL_H = 420, 470

---------------------------------------------------------
-- [ AMBIL REFERENSI UI ]
---------------------------------------------------------
local gui     = playerGui:WaitForChild("BebeqMusicUI", math.huge)
local panel   = gui:WaitForChild("MainPanel")
local uiScale = panel:WaitForChild("UIScale")

local header   = panel:WaitForChild("Header")
local closeBtn = header:WaitForChild("CloseButton")

local npCard   = panel:WaitForChild("NowPlaying")
local npTitle  = npCard:WaitForChild("Title")
local npArtist = npCard:WaitForChild("Artist")
local barBg    = npCard:WaitForChild("ProgressBg")
local barFill  = barBg:WaitForChild("ProgressFill")
local timeLbl  = npCard:WaitForChild("TimeLabel")

local voteBtn  = panel:WaitForChild("VoteSkip")
local adminBtn = panel:WaitForChild("AdminSkip")

local tabBar   = panel:WaitForChild("TabBar")
local tabQueue = tabBar:WaitForChild("QueueTab")
local tabList  = tabBar:WaitForChild("ListTab")

local listScroll  = panel:WaitForChild("ListScroll")
local queueScroll = panel:WaitForChild("QueueScroll")

local volRow     = panel:WaitForChild("VolumeRow")
local muteBtn    = volRow:WaitForChild("MuteButton")
local sliderBg   = volRow:WaitForChild("SliderBg")
local sliderFill = sliderBg:WaitForChild("SliderFill")
local sliderKnob = sliderBg:WaitForChild("SliderKnob")

local toastHolder = gui:WaitForChild("Toasts")

if localIsAdmin then
	voteBtn.Size = UDim2.new(0.5, -16, 0, 34)
	adminBtn.Visible = true
end

sliderFill.Size = UDim2.new(userVolume, 0, 1, 0)
sliderKnob.Position = UDim2.new(userVolume, 0, 0.5, 0)
muteBtn.Text = (userVolume <= 0.001) and "\u{1F507}" or "\u{1F50A}"

local function skinStroke(inst, col)
	local s = inst:FindFirstChildOfClass("UIStroke")
	if s then s.Color = col end
end

local function applyTheme()
	panel.BackgroundColor3 = C.bg
	skinStroke(panel, C.stroke)
	local pGrad = panel:FindFirstChild("PGradient")
	if pGrad then
		pGrad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, C.accent),
			ColorSequenceKeypoint.new(1, C.bg),
		})
	end

	header.TitleLabel.TextColor3 = C.text
	closeBtn.BackgroundColor3 = C.panel2; closeBtn.TextColor3 = C.text
	skinStroke(closeBtn, C.stroke)

	npCard.BackgroundColor3 = C.panel2
	skinStroke(npCard, C.stroke)
	npTitle.TextColor3 = C.text
	npArtist.TextColor3 = C.subtext
	barBg.BackgroundColor3 = C.panel3
	barFill.BackgroundColor3 = C.accent
	timeLbl.TextColor3 = C.subtext

	voteBtn.BackgroundColor3 = C.panel2; voteBtn.TextColor3 = C.text
	skinStroke(voteBtn, C.stroke)
	adminBtn.BackgroundColor3 = C.accent; adminBtn.TextColor3 = C.bg

	skinStroke(tabQueue, C.stroke)
	skinStroke(tabList, C.stroke)

	listScroll.ScrollBarImageColor3 = C.subtext
	queueScroll.ScrollBarImageColor3 = C.subtext

	muteBtn.BackgroundColor3 = C.panel2; muteBtn.TextColor3 = C.text
	skinStroke(muteBtn, C.stroke)
	sliderBg.BackgroundColor3 = C.panel3
	sliderFill.BackgroundColor3 = C.accent
	sliderKnob.BackgroundColor3 = C.accent
end
applyTheme()

---------------------------------------------------------
-- [ TOAST / NOTIF ]
---------------------------------------------------------
local function toast(kind, text)
	local col = C.accent
	if kind == "warn" then col = Color3.fromRGB(230, 170, 40)
	elseif kind == "error" then col = Color3.fromRGB(220, 70, 70) end
	local t = mk("TextLabel", {
		Text = text, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = col,
		BackgroundColor3 = C.panel2, Size = UDim2.new(1, 0, 0, 30),
		AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true,
	}, toastHolder)
	corner(t, 8)
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10),
	}, t)
	task.delay(3, function()
		if t and t.Parent then
			TweenService:Create(t, TweenInfo.new(0.3), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
			task.wait(0.3); t:Destroy()
		end
	end)
end

---------------------------------------------------------
-- [ ISI LIST LAGU & ANTRIAN ]
---------------------------------------------------------
local function clearChildren(frame)
	for _, ch in ipairs(frame:GetChildren()) do
		if not (ch:IsA("UIListLayout") or ch:IsA("UIPadding")) then
			ch:Destroy()
		end
	end
end

local function buildSongList()
	clearChildren(listScroll)
	for i, trk in ipairs(Config.Playlist) do
		local row = mk("Frame", { BackgroundColor3 = C.panel2, Size = UDim2.new(1, -16, 0, 46), LayoutOrder = i }, listScroll)
		corner(row, 9); stroke(row)
		mk("TextLabel", {
			Text = trk.title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -95, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		mk("TextLabel", {
			Text = trk.artist or "", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(1, -95, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		local reqBtn = mk("TextButton", {
			Text = "Request", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.bg,
			BackgroundColor3 = C.accent, AutoButtonColor = true, AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.new(0, 70, 0, 28),
		}, row)
		corner(reqBtn, 8)
		reqBtn.Activated:Connect(function()
			RequestSong:FireServer(i)
		end)
	end
end

local function buildQueue(queueData)
	clearChildren(queueScroll)
	if #queueData == 0 then
		mk("TextLabel", {
			Text = "Queue is empty. Request a song from the 'Song List' tab.",
			Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.subtext, TextWrapped = true,
			BackgroundTransparency = 1, Size = UDim2.new(1, -16, 0, 40), LayoutOrder = 1,
		}, queueScroll)
		return
	end
	for i, q in ipairs(queueData) do
		local row = mk("Frame", { BackgroundColor3 = C.panel2, Size = UDim2.new(1, -16, 0, 44), LayoutOrder = i }, queueScroll)
		corner(row, 9); stroke(row)
		mk("TextLabel", {
			Text = i .. ".  " .. q.title, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 6), Size = UDim2.new(1, -24, 0, 18), TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
		mk("TextLabel", {
			Text = q.by and ("requested by " .. q.by) or "from playlist",
			Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.subtext,
			TextXAlignment = Enum.TextXAlignment.Left, BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 24), Size = UDim2.new(1, -24, 0, 14), TextTruncate = Enum.TextTruncate.AtEnd,
		}, row)
	end
end

---------------------------------------------------------
-- [ NOW PLAYING / PROGRESS / VOTE DISPLAY ]
---------------------------------------------------------
local function fmt(sec)
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d", math.floor(sec / 60), sec % 60)
end

local function setNowPlaying(packet)
	if not packet then
		npTitle.Text = "Nothing playing"
		npArtist.Text = ""
		return
	end
	npTitle.Text = packet.title or "-"
	local sub = packet.artist or ""
	if packet.requestedBy then sub = sub .. "  -  requested by " .. packet.requestedBy end
	npArtist.Text = sub
end

RunService.RenderStepped:Connect(function()
	local dur = current and current.duration
	if (not dur or dur <= 0) and sound.IsLoaded and sound.TimeLength > 0 then
		dur = sound.TimeLength
	end
	if current and dur and dur > 0 then
		local e = (workspace:GetServerTimeNow() - current.startTime) % dur
		if e < 0 then e = 0 end
		local frac = math.clamp(e / dur, 0, 1)
		barFill.Size = UDim2.new(frac, 0, 1, 0)
		timeLbl.Text = fmt(e) .. " / " .. fmt(dur)
	else
		barFill.Size = UDim2.new(0, 0, 1, 0)
		timeLbl.Text = "0:00 / 0:00"
	end
end)

local hasVoted = false
local lastVotes, lastNeed = 0, 0
local function refreshVoteBtn()
	voteBtn.Text = (hasVoted and "Voted" or "Vote Skip") .. " (" .. lastVotes .. "/" .. lastNeed .. ")"
end
local function setVotes(cur, need)
	lastVotes, lastNeed = cur or 0, need or 0
	refreshVoteBtn()
end
local function resetVoteState()
	hasVoted = false
	voteBtn.AutoButtonColor = true
	voteBtn.BackgroundColor3 = C.panel2
	voteBtn.TextColor3 = C.text
	refreshVoteBtn()
end

---------------------------------------------------------
-- [ EVENT WIRING ]
---------------------------------------------------------
NowPlaying.OnClientEvent:Connect(function(packet)
	resetVoteState()
	setNowPlaying(packet)
	playSynced(packet)
end)

QueueUpdate.OnClientEvent:Connect(function(queueData)
	buildQueue(queueData or {})
end)

PreloadList.OnClientEvent:Connect(function(indices)
	preloadWindow(indices)
end)

VoteUpdate.OnClientEvent:Connect(function(cur, need)
	setVotes(cur, need)
end)

Notify.OnClientEvent:Connect(function(kind, text)
	toast(kind, text)
end)

DurationUpdate.OnClientEvent:Connect(function(trackIndex, duration)
	if current and current.trackIndex == trackIndex and duration and duration > 0 then
		current.duration = duration
		if sound.IsLoaded then
			local e = (workspace:GetServerTimeNow() - current.startTime) % duration
			if e < 0 then e = 0 end
			pcall(function()
				sound.TimePosition = e
			end)
			if not sound.Playing then sound:Play() end
		end
	end
end)

voteBtn.Activated:Connect(function()
	if hasVoted then return end
	hasVoted = true
	voteBtn.AutoButtonColor = false
	voteBtn.BackgroundColor3 = C.accent
	voteBtn.TextColor3 = C.bg
	refreshVoteBtn()
	VoteSkip:FireServer()
end)

adminBtn.Activated:Connect(function()
	toast("info", "Skipping current song (Admin)...")
	AdminSkip:FireServer()
end)

-- Tabs
local function selectTab(which)
	listScroll.Visible  = (which == "list")
	queueScroll.Visible = (which == "queue")
	tabList.BackgroundColor3  = (which == "list")  and C.accent or C.panel2
	tabList.TextColor3        = (which == "list")  and C.bg or C.text
	tabQueue.BackgroundColor3 = (which == "queue") and C.accent or C.panel2
	tabQueue.TextColor3       = (which == "queue") and C.bg or C.text
end
tabList.Activated:Connect(function() selectTab("list") end)
tabQueue.Activated:Connect(function() selectTab("queue") end)
selectTab("queue")

---------------------------------------------------------
-- [ VOLUME SLIDER ]
---------------------------------------------------------
local draggingVol = false
local function applyVolFromX(x)
	local rel = math.clamp((x - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
	userVolume = rel
	sliderFill.Size = UDim2.new(rel, 0, 1, 0)
	sliderKnob.Position = UDim2.new(rel, 0, 0.5, 0)
	if not muted then sound.Volume = rel end
	muteBtn.Text = (rel <= 0.001 or muted) and "\u{1F507}" or "\u{1F50A}"
end

local function bindSliderInput(obj)
	obj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingVol = true
			applyVolFromX(input.Position.X)
		end
	end)
end

bindSliderInput(sliderBg)
bindSliderInput(sliderFill)
bindSliderInput(sliderKnob)

UserInputService.InputChanged:Connect(function(input)
	if draggingVol and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		applyVolFromX(input.Position.X)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		draggingVol = false
	end
end)
muteBtn.Activated:Connect(function()
	muted = not muted
	sound.Volume = effectiveVolume()
	muteBtn.Text = (muted or userVolume <= 0.001) and "\u{1F507}" or "\u{1F50A}"
end)

---------------------------------------------------------
-- [ BUKA / TUTUP PANEL ]
---------------------------------------------------------
local isOpen = false

local camera = workspace.CurrentCamera
local function fitScale()
	local vp = (camera and camera.ViewportSize) or Vector2.new(PANEL_W, PANEL_H)
	local sw = (vp.X - 24) / PANEL_W
	local sh = (vp.Y - 80) / PANEL_H
	return math.clamp(math.min(1, sw, sh), 0.4, 1)
end

local function openPanel()
	isOpen = true
	panel.Visible = true
	local target = fitScale()
	uiScale.Scale = target * 0.92
	TweenService:Create(uiScale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = target }):Play()
end
local function closePanel()
	isOpen = false
	local tw = TweenService:Create(uiScale, TweenInfo.new(0.14), { Scale = fitScale() * 0.92 })
	tw:Play()
	tw.Completed:Once(function()
		if not isOpen then panel.Visible = false end
	end)
end

if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		if isOpen then uiScale.Scale = fitScale() end
	end)
end

local canOpenUI = (not S.WhitelistOnly) or localIsAdmin
if canOpenUI then
	local musicIcon = Icon.new()
		:setLabel("Music")
		:bindEvent("selected", function() openPanel() end)
		:bindEvent("deselected", function() closePanel() end)

	task.spawn(function() _G.SuwaTopbarApps = _G.SuwaTopbarApps or {}; table.insert(_G.SuwaTopbarApps, musicIcon) end)

	closeBtn.Activated:Connect(function()
		musicIcon:deselect()
		closePanel()
	end)
end

---------------------------------------------------------
-- [ SINKRONISASI AWAL ]
---------------------------------------------------------
buildSongList()

task.spawn(function()
	local ok, state = pcall(function()
		return GetState:InvokeServer()
	end)
	if ok and state then
		preloadWindow(state.preload)
		setVotes(state.votes, state.votesNeeded)
		buildQueue(state.queue or {})
		if state.nowPlaying then
			setNowPlaying(state.nowPlaying)
			playSynced(state.nowPlaying)
		end
	end
end)
