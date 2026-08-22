--!strict
-- SoundtrackService: Lake Suwa Anime Piano & Nostalgic Atmosphere BGM System
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local SoundtrackService = {}

-- Main Track: Sparkle - Your Name (Kimi no Na wa) Piano Version & Shinkai Suite
local PLAYLIST = {
	{
		id = "rbxassetid://9044561897",
		title = "Sparkle (Piano Ver.) - Kimi no Na wa OST",
		artist = "RADWIMPS / Your Name",
		volume = 0.32,
	},
	{
		id = "rbxassetid://1836972679",
		title = "Katawaredoki / Memories of Lake Suwa",
		artist = "Makoto Shinkai Piano Suite",
		volume = 0.30,
	},
	{
		id = "rbxassetid://9044748817",
		title = "Nandemonaiya - Lake Breeze Piano",
		artist = "Your Name Relaxing Piano",
		volume = 0.28,
	},
}

local currentTrackIndex = 1
local activeSound: Sound? = nil
local isMuted = false

local function showMusicHUD(player: Player, trackTitle: string)
	local pGui = player:FindFirstChild("PlayerGui")
	if not pGui then return end

	local sg = pGui:FindFirstChild("SuwaMusicHUD")
	if not sg then
		local newSg = Instance.new("ScreenGui")
		newSg.Name = "SuwaMusicHUD"
		newSg.ResetOnSpawn = false
		newSg.DisplayOrder = 10
		newSg.Parent = pGui
		sg = newSg

		-- Mute/Unmute HUD Button (Top Right)
		local btn = Instance.new("TextButton")
		btn.Name = "MuteToggleBtn"
		btn.AnchorPoint = Vector2.new(1, 0)
		btn.Position = UDim2.new(1, -20, 0, 20)
		btn.Size = UDim2.new(0, 44, 0, 44)
		btn.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
		btn.BackgroundTransparency = 0.2
		btn.Font = Enum.Font.GothamBold
		btn.Text = "🔊"
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 22
		btn.Parent = sg
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)

		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Color3.fromRGB(255, 180, 210)
		stroke.Thickness = 1.6

		btn.MouseButton1Click:Connect(function()
			isMuted = not isMuted
			btn.Text = if isMuted then "🔇" else "🔊"
			btn.BackgroundColor3 = if isMuted then Color3.fromRGB(55, 25, 30) else Color3.fromRGB(24, 28, 38)
			if activeSound then
				local targetVol = if isMuted then 0 else (PLAYLIST[currentTrackIndex].volume or 0.30)
				TweenService:Create(activeSound, TweenInfo.new(0.35), { Volume = targetVol }):Play()
			end
		end)
	end

	-- Track Title Banner Notification
	local banner = Instance.new("Frame")
	banner.Name = "TrackBanner"
	banner.AnchorPoint = Vector2.new(1, 0)
	banner.Position = UDim2.new(1, -72, 0, 20)
	banner.Size = UDim2.new(0, 310, 0, 44)
	banner.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	banner.BackgroundTransparency = 1
	banner.BorderSizePixel = 0
	banner.Parent = sg
	Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)

	local stroke = Instance.new("UIStroke", banner)
	stroke.Color = Color3.fromRGB(255, 180, 210)
	stroke.Thickness = 1.2
	stroke.Transparency = 1

	local label = Instance.new("TextLabel", banner)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.Size = UDim2.new(1, -28, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = string.format("🎹 %s", trackTitle)
	label.TextColor3 = Color3.fromRGB(255, 230, 245)
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextTransparency = 1

	local tIn = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(banner, tIn, { BackgroundTransparency = 0.2 }):Play()
	TweenService:Create(stroke, tIn, { Transparency = 0.3 }):Play()
	TweenService:Create(label, tIn, { TextTransparency = 0 }):Play()

	task.delay(7.0, function()
		local tOut = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(banner, tOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, tOut, { Transparency = 1 }):Play()
		TweenService:Create(label, tOut, { TextTransparency = 1 }):Play()
		task.delay(0.7, function() if banner.Parent then banner:Destroy() end end)
	end)
end

local function playTrack(index: number)
	currentTrackIndex = ((index - 1) % #PLAYLIST) + 1
	local track = PLAYLIST[currentTrackIndex]

	local oldSound = activeSound
	if oldSound then
		local fadeOut = TweenService:Create(oldSound, TweenInfo.new(2.0), { Volume = 0 })
		fadeOut:Play()
		fadeOut.Completed:Connect(function() oldSound:Destroy() end)
	end

	local sound = Instance.new("Sound")
	sound.Name = "SuwaAmbientBGM"
	sound.SoundId = track.id
	sound.Volume = 0
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()
	activeSound = sound

	local targetVol = if isMuted then 0 else track.volume
	local fadeIn = TweenService:Create(sound, TweenInfo.new(2.5), { Volume = targetVol })
	fadeIn:Play()

	for _, p in ipairs(Players:GetPlayers()) do
		showMusicHUD(p, track.title)
	end
end

function SoundtrackService.setCustomAudioId(audioId: string, trackTitle: string?)
	table.insert(PLAYLIST, 1, {
		id = if audioId:find("rbxassetid://") then audioId else ("rbxassetid://" .. audioId),
		title = trackTitle or "Sparkle - Your Name (Custom Upload)",
		artist = "RADWIMPS",
		volume = 0.35,
	})
	playTrack(1)
end

function SoundtrackService.init()
	for _, s in ipairs(SoundService:GetChildren()) do
		if s.Name == "SuwaAmbientBGM" then s:Destroy() end
	end

	task.delay(1.5, function()
		playTrack(1)
	end)

	Players.PlayerAdded:Connect(function(player)
		task.delay(2.0, function()
			if activeSound and player.Parent then
				local track = PLAYLIST[currentTrackIndex]
				showMusicHUD(player, track.title)
			end
		end)
	end)
end

return SoundtrackService
