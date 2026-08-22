--!strict
-- SoundtrackService: Lake Suwa Anime Piano & Nostalgic Atmosphere BGM System
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local SoundtrackService = {}

-- Curated Peaceful Japanese Anime Piano & Orchestral Playlist (Kimi no Na wa / Makoto Shinkai Vibe)
local PLAYLIST = {
	{
		id = "rbxassetid://9044561897",
		title = "When Stars Collide (Kimi no Na wa Vibe)",
		artist = "APM / Radwimps Style",
		volume = 0.28,
	},
	{
		id = "rbxassetid://9044748817",
		title = "Dignity & Memories of Suwa",
		artist = "Lake Suwa Piano Suite",
		volume = 0.26,
	},
	{
		id = "rbxassetid://1836972679",
		title = "Thoughtful Moments by the Lake",
		artist = "Shinkai Piano Acoustic",
		volume = 0.28,
	},
	{
		id = "rbxassetid://9043254399",
		title = "Majestic Lake Suwa Sunrise",
		artist = "Panoramic Orchestral",
		volume = 0.24,
	},
}

local currentTrackIndex = 1
local activeSound: Sound? = nil

local function showMusicHUD(player: Player, trackTitle: string)
	local pGui = player:FindFirstChild("PlayerGui")
	if not pGui then return end

	local sg = pGui:FindFirstChild("SuwaMusicHUD")
	if not sg then
		local newSg = Instance.new("ScreenGui")
		newSg.Name = "SuwaMusicHUD"
		newSg.ResetOnSpawn = false
		newSg.Parent = pGui
		sg = newSg

		-- Mute/Unmute toggle button
		local btn = Instance.new("TextButton")
		btn.Name = "MuteToggleBtn"
		btn.AnchorPoint = Vector2.new(1, 0)
		btn.Position = UDim2.new(1, -16, 0, 16)
		btn.Size = UDim2.new(0, 38, 0, 38)
		btn.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
		btn.BackgroundTransparency = 0.25
		btn.Font = Enum.Font.GothamBold
		btn.Text = "🔊"
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.TextSize = 18
		btn.Parent = sg
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
		local stroke = Instance.new("UIStroke", btn)
		stroke.Color = Color3.fromRGB(245, 165, 195)
		stroke.Thickness = 1.2

		local isMuted = false
		btn.MouseButton1Click:Connect(function()
			isMuted = not isMuted
			btn.Text = if isMuted then "🔇" else "🔊"
			if activeSound then
				activeSound.Volume = if isMuted then 0 else (PLAYLIST[currentTrackIndex].volume or 0.25)
			end
		end)
	end

	-- Show small track notification banner
	local banner = Instance.new("Frame")
	banner.Name = "TrackBanner"
	banner.AnchorPoint = Vector2.new(1, 0)
	banner.Position = UDim2.new(1, -62, 0, 16)
	banner.Size = UDim2.new(0, 260, 0, 38)
	banner.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	banner.BackgroundTransparency = 1
	banner.BorderSizePixel = 0
	banner.Parent = sg
	Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 10)

	local stroke = Instance.new("UIStroke", banner)
	stroke.Color = Color3.fromRGB(245, 165, 195)
	stroke.Thickness = 1
	stroke.Transparency = 1

	local label = Instance.new("TextLabel", banner)
	label.Position = UDim2.new(0, 12, 0, 0)
	label.Size = UDim2.new(1, -24, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamMedium
	label.Text = string.format("🎵 %s", trackTitle)
	label.TextColor3 = Color3.fromRGB(245, 220, 235)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.TextTransparency = 1

	local tIn = TweenInfo.new(0.4)
	TweenService:Create(banner, tIn, { BackgroundTransparency = 0.2 }):Play()
	TweenService:Create(stroke, tIn, { Transparency = 0.3 }):Play()
	TweenService:Create(label, tIn, { TextTransparency = 0 }):Play()

	task.delay(6.0, function()
		local tOut = TweenInfo.new(0.5)
		TweenService:Create(banner, tOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, tOut, { Transparency = 1 }):Play()
		TweenService:Create(label, tOut, { TextTransparency = 1 }):Play()
		task.delay(0.6, function() if banner.Parent then banner:Destroy() end end)
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

	local fadeIn = TweenService:Create(sound, TweenInfo.new(2.5), { Volume = track.volume })
	fadeIn:Play()

	for _, p in ipairs(Players:GetPlayers()) do
		showMusicHUD(p, track.title)
	end
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
