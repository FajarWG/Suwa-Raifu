--[[
	-------------------------------------------------------
	     EMOTE SYSTEM CLIENT (STANDALONE VERSION)
	     Independent Emote System without Sync Integration
	-------------------------------------------------------
]]

local CONFIG = {
	-- Animation Settings
	AnimationPriority = Enum.AnimationPriority.Action4,
	DefaultLooped = true,
	FadeInTime = 0.08,
	FadeOutTime = 0.08,
	MenuOpenTweenTime = 0.4,
	ButtonHoverTweenTime = 0.2,

	-- Button Styling
	ButtonSize = UDim2.new(1, -10, 0, 45),
	ButtonBackgroundColor = Color3.fromRGB(45, 45, 45),
	ButtonHoverColor = Color3.fromRGB(60, 60, 60),
	ButtonActiveColor = Color3.fromRGB(0, 170, 255),
	ButtonTextSize = 14,
	ButtonFont = Enum.Font.GothamBold,

	-- Preloading
	PreloadAllAnimations = true,

	-- Favorites
	EnableFavorites = true,
	FavoriteButtonText = "★ Favorites",
	AllEmotesButtonText = "☆ All Emotes",
	FavoriteColor = Color3.fromRGB(255, 200, 0),

	-- Search
	EnableSearch = true,
	SearchCaseSensitive = false,

	-- Debug
	DebugMode = false,
	ShowAnimationCount = false,
	LogEmoteActions = false,
}

-- Services & UI
local replica = game:GetService('ReplicatedStorage')
local player = game.Players.LocalPlayer
local emotesFolder = replica:WaitForChild('Emotes')
local mainFrame = script.Parent:WaitForChild('MainFrame')
local emoteList = mainFrame:WaitForChild('EmoteList')
local searchBar = mainFrame:WaitForChild('SearchBar')
local emoteButton = script.Parent:WaitForChild('EmoteButton')
local closeButton = mainFrame:WaitForChild('CloseButton')
local favoriteButton = mainFrame:WaitForChild('FavoriteButton')
local templateButton = emoteList:FindFirstChild("Template")
if templateButton then templateButton.Parent = nil end

-- DataStore Remotes
local emoteRemotesFolder = replica:WaitForChild("Remotes", 5):WaitForChild("EmoteRemotes",5)
local LoadFavoritesRemote = nil
local SaveFavoriteRemote = nil

if emoteRemotesFolder then
	LoadFavoritesRemote = emoteRemotesFolder:WaitForChild("LoadFavorites", 5)
	SaveFavoriteRemote = emoteRemotesFolder:WaitForChild("SaveFavorite", 5)
end

local function debugPrint(...)
	if CONFIG.DebugMode then
		print("[EMOTE]", ...)
	end
end

-- Variables
local animt = nil
local chara = nil
local currentButton = nil
local loadedAnimations = {}
local emoteAnimations = {}
local favoriteEmotes = {}
local showingFavorites = false
local favoritesLoaded = false
local connections = {} -- Track connections for cleanup

-- Drag variables
local isDragging = false
local dragStartPos = nil
local frameStartPos = nil
local lastFramePosition = mainFrame.Position

local TweenService = game:GetService("TweenService")

-- Connection tracking
local function trackConnection(conn)
	table.insert(connections, conn)
	return conn
end

-- ==================== MAIN FUNCTIONS ====================
local function loadEmotesFromFolder()
	emoteAnimations = {}
	for _, anim in pairs(emotesFolder:GetChildren()) do
		if anim:IsA("Animation") then
			table.insert(emoteAnimations, {
				name = anim.Name,
				animation = anim,
				isFavorite = false
			})
		end
	end

	table.sort(emoteAnimations, function(a, b)
		return a.name:lower() < b.name:lower()
	end)

	if CONFIG.ShowAnimationCount then
		debugPrint("Loaded", #emoteAnimations, "emotes from folder")
	end
end

-- Forward declaration
local updateEmoteList

local function saveFavoriteToServer(emoteName)
	if not SaveFavoriteRemote then
		warn("[EMOTE] SaveFavoriteRemote not found!")
		return
	end

	task.spawn(function()
		SaveFavoriteRemote:FireServer(emoteName)
	end)
end

-- Define updateEmoteList
updateEmoteList = function(emotes)
	task.spawn(function()
		for _, child in pairs(emoteList:GetChildren()) do
			if child:IsA("TextButton") and child.Name ~= "Template" then
				child:Destroy()
			end
		end
	end)

	for _, emoteData in pairs(emotes) do
		local button = Instance.new("TextButton")
		button.Name = emoteData.name
		button.Size = CONFIG.ButtonSize
		button.BackgroundColor3 = CONFIG.ButtonBackgroundColor
		button.BorderSizePixel = 0
		button.Text = "  " .. emoteData.name
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.Font = CONFIG.ButtonFont
		button.TextSize = CONFIG.ButtonTextSize
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.AutoButtonColor = false
		button.ClipsDescendants = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 10)
		padding.Parent = button

		if CONFIG.EnableFavorites then
			local starButton = Instance.new("TextButton")
			starButton.Name = "StarButton"
			starButton.Size = UDim2.new(0, 35, 0, 35)
			starButton.Position = UDim2.new(1, -40, 0.5, -17.5)
			starButton.BackgroundTransparency = 1
			starButton.Text = emoteData.isFavorite and "★" or "☆"
			starButton.TextColor3 = CONFIG.FavoriteColor
			starButton.Font = CONFIG.ButtonFont
			starButton.TextSize = 20
			starButton.ZIndex = 2
			starButton.Parent = button

			starButton.MouseButton1Click:Connect(function()
				emoteData.isFavorite = not emoteData.isFavorite
				starButton.Text = emoteData.isFavorite and "★" or "☆"

				saveFavoriteToServer(emoteData.name)

				if emoteData.isFavorite then
					local exists = false
					for _, v in pairs(favoriteEmotes) do
						if v.name == emoteData.name then exists = true break end
					end
					if not exists then table.insert(favoriteEmotes, emoteData) end
				else
					for i, v in pairs(favoriteEmotes) do
						if v.name == emoteData.name then table.remove(favoriteEmotes, i) break end
					end
				end

				if showingFavorites then updateEmoteList(favoriteEmotes) end
			end)
		end

		button.MouseButton1Click:Connect(function()
			if not chara or not chara.Parent then return end

			local cacheData = loadedAnimations[emoteData.name]
			if not cacheData then return end

			local track = cacheData.track

			if currentButton == button and animt then
				pcall(function()
					animt:Stop(CONFIG.FadeOutTime)
				end)
				animt = nil
				currentButton.BackgroundTransparency = 0
				currentButton = nil

				if CONFIG.LogEmoteActions then
					debugPrint("Stopped emote:", emoteData.name)
				end
				return
			end

			if animt and animt.IsPlaying then
				pcall(function()
					animt:Stop(CONFIG.FadeOutTime)
				end)
			end

			if currentButton then
				currentButton.BackgroundTransparency = 0
			end

			animt = track
			pcall(function()
				animt:Play(CONFIG.FadeInTime, 1, 1)
			end)

			currentButton = button
			task.spawn(function()
				button.BackgroundTransparency = 0.5
			end)

			if CONFIG.LogEmoteActions then
				debugPrint("Playing emote:", emoteData.name)
			end
		end)

		button.MouseEnter:Connect(function()
			if button ~= currentButton then
				task.spawn(function()
					TweenService:Create(button, TweenInfo.new(CONFIG.ButtonHoverTweenTime, Enum.EasingStyle.Quad), {
						BackgroundColor3 = CONFIG.ButtonHoverColor
					}):Play()
				end)
			end
		end)

		button.MouseLeave:Connect(function()
			if button ~= currentButton then
				task.spawn(function()
					TweenService:Create(button, TweenInfo.new(CONFIG.ButtonHoverTweenTime, Enum.EasingStyle.Quad), {
						BackgroundColor3 = CONFIG.ButtonBackgroundColor
					}):Play()
				end)
			end
		end)

		button.Parent = emoteList
	end

	task.wait(0.1)
	local listLayout = emoteList:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		emoteList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end
end

-- ==================== DATASTORE FUNCTIONS ====================
local function loadFavoritesFromServer()
	if not LoadFavoritesRemote then
		warn("[EMOTE] LoadFavoritesRemote not found!")
		return {}
	end

	task.spawn(function()
		local success, result = pcall(function()
			return LoadFavoritesRemote:InvokeServer()
		end)

		if success and result then
			debugPrint("Loaded", #result, "favorites from server")

			for _, favName in ipairs(result) do
				for _, emoteData in ipairs(emoteAnimations) do
					if emoteData.name == favName then
						emoteData.isFavorite = true
						table.insert(favoriteEmotes, emoteData)
						break
					end
				end
			end

			favoritesLoaded = true

			if showingFavorites then
				updateEmoteList(favoriteEmotes)
			end
		else
			warn("[EMOTE] Failed to load favorites:", result)
		end
	end)
end

-- Listen for favorite updates from server
if SaveFavoriteRemote then
	trackConnection(SaveFavoriteRemote.OnClientEvent:Connect(function(updatedFavorites)
		debugPrint("Received updated favorites from server:", #updatedFavorites)

		favoriteEmotes = {}
		for _, emoteData in ipairs(emoteAnimations) do
			emoteData.isFavorite = false
		end

		for _, favName in ipairs(updatedFavorites) do
			for _, emoteData in ipairs(emoteAnimations) do
				if emoteData.name == favName then
					emoteData.isFavorite = true
					table.insert(favoriteEmotes, emoteData)
					break
				end
			end
		end

		if showingFavorites then
			updateEmoteList(favoriteEmotes)
		else
			updateEmoteList(emoteAnimations)
		end
	end))
end

local function preloadAnimations(character)
	if not CONFIG.PreloadAllAnimations then return end

	task.spawn(function()
		local humanoid = character:WaitForChild('Humanoid')
		local animator = humanoid:WaitForChild('Animator')

		for _, data in pairs(loadedAnimations) do
			if data.track and data.track.IsPlaying then
				pcall(function()
					data.track:Stop(0)
				end)
			end
		end
		loadedAnimations = {}

		local count = 0
		for _, animation in pairs(emotesFolder:GetChildren()) do
			if animation:IsA("Animation") then
				local success, track = pcall(function()
					return animator:LoadAnimation(animation)
				end)

				if success and track then
					track.Looped = CONFIG.DefaultLooped
					track.Priority = CONFIG.AnimationPriority
					loadedAnimations[animation.Name] = {track = track, animation = animation}
					count = count + 1
				end
			end
		end

		if CONFIG.ShowAnimationCount then
			debugPrint("Preloaded", count, "animations")
		end
	end)
end

local function setupEmotes(character)
	chara = character

	if animt and animt.IsPlaying then
		pcall(function()
			animt:Stop(0)
		end)
		animt = nil
	end

	if currentButton then
		currentButton.BackgroundTransparency = 0
		currentButton = nil
	end

	preloadAnimations(character)
end

local function filterEmotes(searchText)
	if not CONFIG.EnableSearch then return end

	task.spawn(function()
		local filtered = {}
		local sourceList = showingFavorites and favoriteEmotes or emoteAnimations

		if searchText == "" then
			filtered = sourceList
		else
			for _, emoteData in pairs(sourceList) do
				local emoteName = CONFIG.SearchCaseSensitive and emoteData.name or emoteData.name:lower()
				local search = CONFIG.SearchCaseSensitive and searchText or searchText:lower()

				if string.find(emoteName, search, 1, true) then
					table.insert(filtered, emoteData)
				end
			end
		end

		updateEmoteList(filtered)
	end)
end

local function toggleFrame()
	mainFrame.Visible = not mainFrame.Visible

	if mainFrame.Visible then
		if CONFIG.EnableSearch then
			searchBar.Text = ""
		end

		if showingFavorites then
			updateEmoteList(favoriteEmotes)
		else
			updateEmoteList(emoteAnimations)
		end

		TweenService:Create(mainFrame, TweenInfo.new(CONFIG.MenuOpenTweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = lastFramePosition
		}):Play()
	end
end

local function startDrag(input)
	if not mainFrame.Visible then return end
	isDragging = true
	dragStartPos = input.Position
	frameStartPos = mainFrame.Position
end

local function dragFrame(input)
	if not isDragging or not dragStartPos then return end
	local delta = input.Position - dragStartPos
	local newPos = frameStartPos + UDim2.new(0, delta.X, 0, delta.Y)
	mainFrame.Position = newPos
end

local function stopDrag()
	isDragging = false
	dragStartPos = nil
	frameStartPos = nil
	lastFramePosition = mainFrame.Position
end

-- Touch counts here as well as the mouse. Without it the panel simply could
-- not be moved on a phone: a finger reports UserInputType.Touch, never
-- MouseButton1/MouseMovement, so every drag handler ignored it.
local function isDragStart(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isDragMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

trackConnection(mainFrame.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isDragStart(input) then
		startDrag(input)
	end
end))

trackConnection(mainFrame.InputChanged:Connect(function(input, gameProcessed)
	if isDragMove(input) then
		dragFrame(input)
	end
end))

trackConnection(mainFrame.InputEnded:Connect(function(input, gameProcessed)
	if isDragStart(input) then
		stopDrag()
	end
end))

-- ==================== INITIALIZATION ====================
loadEmotesFromFolder()
updateEmoteList(emoteAnimations)

loadFavoritesFromServer()

if player.Character then
	setupEmotes(player.Character)
end

trackConnection(player.CharacterAdded:Connect(function(character)
	setupEmotes(character)
end))

-- ==================== BUTTON CONNECTIONS ====================
trackConnection(emoteButton.MouseButton1Click:Connect(toggleFrame))

trackConnection(closeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false
end))

if CONFIG.EnableSearch then
	trackConnection(searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		filterEmotes(searchBar.Text)
	end))
end

if CONFIG.EnableFavorites then
	trackConnection(favoriteButton.MouseButton1Click:Connect(function()
		showingFavorites = not showingFavorites

		if showingFavorites then
			favoriteButton.Text = CONFIG.AllEmotesButtonText
			favoriteButton.BackgroundColor3 = CONFIG.FavoriteColor
			updateEmoteList(favoriteEmotes)
		else
			favoriteButton.Text = CONFIG.FavoriteButtonText
			favoriteButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			if CONFIG.EnableSearch then
				searchBar.Text = ""
			end
			updateEmoteList(emoteAnimations)
		end
	end))
end

-- ==================== CLEANUP ====================
local Players = game:GetService("Players")

trackConnection(Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		-- Disconnect all connections
		for _, conn in ipairs(connections) do
			if conn and typeof(conn) == "RBXScriptConnection" then
				if conn.Connected then
					conn:Disconnect()
				end
			end
		end
		connections = {}

		-- Clear animations
		for _, data in pairs(loadedAnimations) do
			if data.track then
				pcall(function()
					data.track:Destroy()
				end)
			end
		end
		loadedAnimations = {}

		debugPrint("Emote system cleaned up")
	end
end))