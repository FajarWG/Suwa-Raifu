--[[
	-------------------------------------------------------
	     EMOTE SYSTEM CLIENT (SUWA RAIFU ADAPTIVE)
	-------------------------------------------------------
]]

local CONFIG = {
	-- Animation Settings
	AnimationPriority = Enum.AnimationPriority.Action4,
	DefaultLooped = true,
	FadeInTime = 0.08,
	FadeOutTime = 0.08,
	MenuOpenTweenTime = 0.3,
	ButtonHoverTweenTime = 0.15,

	-- Button Styling
	ButtonSize = UDim2.new(1, -6, 0, 42),
	ButtonBackgroundColor = Color3.fromRGB(38, 38, 42),
	ButtonHoverColor = Color3.fromRGB(55, 55, 60),
	ButtonActiveColor = Color3.fromRGB(0, 170, 255),
	ButtonTextSize = 13,
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
}

-- Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local screenGui = script.Parent
local mainFrame = screenGui:WaitForChild("MainFrame")
local emoteList = mainFrame:WaitForChild("EmoteList")
local searchBar = mainFrame:WaitForChild("SearchBar")
local emoteButton = screenGui:WaitForChild("EmoteButton")
local closeButton = mainFrame:WaitForChild("CloseButton")
local favoriteButton = mainFrame:WaitForChild("FavoriteButton")

local templateButton = emoteList:FindFirstChild("Template")
if templateButton then templateButton.Parent = nil end

-- Setup ScrollingFrame for flawless mobile touch scrolling
emoteList.AutomaticCanvasSize = Enum.AutomaticSize.Y
emoteList.CanvasSize = UDim2.new(0, 0, 0, 0)
emoteList.ScrollBarThickness = 6
emoteList.ScrollingDirection = Enum.ScrollingDirection.Y
emoteList.ElasticBehavior = Enum.ElasticBehavior.Always
mainFrame.ClipsDescendants = true

-- Emotes Folder & Remotes
local emotesFolder = ReplicatedStorage:WaitForChild("Emotes")
local emoteRemotesFolder = ReplicatedStorage:WaitForChild("Remotes", 5):WaitForChild("EmoteRemotes", 5)
local LoadFavoritesRemote = emoteRemotesFolder and emoteRemotesFolder:WaitForChild("LoadFavorites", 5) or nil
local SaveFavoriteRemote = emoteRemotesFolder and emoteRemotesFolder:WaitForChild("SaveFavorite", 5) or nil

-- State variables
local animt = nil
local chara = nil
local currentButton = nil
local loadedAnimations = {}
local emoteAnimations = {}
local favoriteEmotes = {}
local showingFavorites = false
local favoritesLoaded = false
local charConnections = {}
local globalConnections = {}

-- Drag variables
local isDragging = false
local dragStartPos = nil
local frameStartPos = nil
local lastFramePosition = mainFrame.Position

local function debugPrint(...)
	if CONFIG.DebugMode then
		print("[EMOTE]", ...)
	end
end

-- ==================== CHARACTER & MOVEMENT STATE ====================

local function stopCurrentEmote()
	if animt then
		pcall(function()
			animt:Stop(CONFIG.FadeOutTime)
		end)
		animt = nil
	end
	if currentButton then
		currentButton.BackgroundTransparency = 0
		currentButton = nil
	end
end

-- Check if player is currently in a state where dancing is allowed (must be idle/standing still, not sitting, driving, swimming, etc.)
local function canPlayEmote()
	if not chara or not chara.Parent then return false end
	local humanoid = chara:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	-- Not sitting (benches, bicycles, boats, cars)
	if humanoid.Sit or humanoid.SeatPart ~= nil then return false end

	-- Not moving (must stand still to start an emote)
	if humanoid.MoveDirection.Magnitude > 0.05 then return false end

	-- State checks
	local state = humanoid:GetState()
	if state == Enum.HumanoidStateType.Swimming
		or state == Enum.HumanoidStateType.Climbing
		or state == Enum.HumanoidStateType.Seated
		or state == Enum.HumanoidStateType.Dead
		or state == Enum.HumanoidStateType.PlatformStanding then
		return false
	end

	-- Not sleeping / ragdoll
	if chara:GetAttribute("Sleeping") == true or humanoid.PlatformStand then
		return false
	end

	return true
end

-- Check whether the EmoteButton should be visible on HUD
local function updateEmoteButtonVisibility()
	if not chara or not chara.Parent then
		emoteButton.Visible = false
		if mainFrame.Visible then mainFrame.Visible = false end
		stopCurrentEmote()
		return
	end

	local humanoid = chara:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		emoteButton.Visible = false
		if mainFrame.Visible then mainFrame.Visible = false end
		stopCurrentEmote()
		return
	end

	local isSeated = humanoid.Sit or (humanoid.SeatPart ~= nil) or (chara:FindFirstChild("SeatWeld") ~= nil)
	local state = humanoid:GetState()
	local isSwimming = (state == Enum.HumanoidStateType.Swimming) or (humanoid.FloorMaterial == Enum.Material.Water)
	local isClimbing = (state == Enum.HumanoidStateType.Climbing)
	local isSleeping = (chara:GetAttribute("Sleeping") == true) or humanoid.PlatformStand

	local isBusy = isSeated or isSwimming or isClimbing or isSleeping

	if isBusy then
		emoteButton.Visible = false
		if mainFrame.Visible then
			mainFrame.Visible = false
		end
		stopCurrentEmote()
	else
		emoteButton.Visible = true
	end
end

-- ==================== ANIMATION LOADING ====================

local function loadEmotesFromFolder()
	emoteAnimations = {}
	for _, anim in pairs(emotesFolder:GetChildren()) do
		if anim:IsA("Animation") then
			table.insert(emoteAnimations, {
				name = anim.Name,
				animation = anim,
				isFavorite = false,
			})
		end
	end

	table.sort(emoteAnimations, function(a, b)
		return a.name:lower() < b.name:lower()
	end)
end

local function getOrLoadTrack(emoteData)
	if not chara or not chara.Parent then return nil end
	local humanoid = chara:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then return nil end

	-- Check cache
	local cacheData = loadedAnimations[emoteData.name]
	if cacheData and cacheData.track and cacheData.track.Animation then
		return cacheData.track
	end

	-- On-demand load fallback
	if emoteData.animation then
		local success, track = pcall(function()
			return animator:LoadAnimation(emoteData.animation)
		end)
		if success and track then
			track.Looped = CONFIG.DefaultLooped
			track.Priority = CONFIG.AnimationPriority
			loadedAnimations[emoteData.name] = { track = track, animation = emoteData.animation }
			return track
		end
	end

	return nil
end

local function preloadAnimations(character)
	if not CONFIG.PreloadAllAnimations then return end

	task.spawn(function()
		local humanoid = character:WaitForChild("Humanoid", 5)
		local animator = humanoid and humanoid:WaitForChild("Animator", 5)
		if not animator then return end

		for _, data in pairs(loadedAnimations) do
			if data.track and data.track.IsPlaying then
				pcall(function() data.track:Stop(0) end)
			end
		end
		loadedAnimations = {}

		for _, animation in pairs(emotesFolder:GetChildren()) do
			if animation:IsA("Animation") then
				local success, track = pcall(function()
					return animator:LoadAnimation(animation)
				end)
				if success and track then
					track.Looped = CONFIG.DefaultLooped
					track.Priority = CONFIG.AnimationPriority
					loadedAnimations[animation.Name] = { track = track, animation = animation }
				end
			end
		end
	end)
end

-- ==================== FAVORITES ====================

local function saveFavoriteToServer(emoteName)
	if not SaveFavoriteRemote then return end
	task.spawn(function()
		SaveFavoriteRemote:FireServer(emoteName)
	end)
end

local function loadFavoritesFromServer()
	if not LoadFavoritesRemote then return end

	task.spawn(function()
		local success, result = pcall(function()
			return LoadFavoritesRemote:InvokeServer()
		end)

		if success and result then
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
		end
	end)
end

if SaveFavoriteRemote then
	table.insert(globalConnections, SaveFavoriteRemote.OnClientEvent:Connect(function(updatedFavorites)
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
	end))
end

-- ==================== UI EMOTE LIST ====================

local updateEmoteList

updateEmoteList = function(emotes)
	-- Synchronously clean up existing buttons to prevent task.spawn race condition
	for _, child in ipairs(emoteList:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "Template" then
			child:Destroy()
		end
	end

	for _, emoteData in ipairs(emotes) do
		local button = Instance.new("TextButton")
		button.Name = emoteData.name
		button.Size = CONFIG.ButtonSize
		button.BackgroundColor3 = CONFIG.ButtonBackgroundColor
		button.BorderSizePixel = 0
		button.Text = "  " .. emoteData.name
		button.TextColor3 = Color3.fromRGB(245, 245, 245)
		button.Font = CONFIG.ButtonFont
		button.TextSize = CONFIG.ButtonTextSize
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.AutoButtonColor = true
		button.ClipsDescendants = true

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = button

		local padding = Instance.new("UIPadding")
		padding.PaddingLeft = UDim.new(0, 8)
		padding.Parent = button

		if CONFIG.EnableFavorites then
			local starButton = Instance.new("TextButton")
			starButton.Name = "StarButton"
			starButton.Size = UDim2.new(0, 36, 0, 36)
			starButton.Position = UDim2.new(1, -38, 0.5, -18)
			starButton.BackgroundTransparency = 1
			starButton.Text = emoteData.isFavorite and "★" or "☆"
			starButton.TextColor3 = CONFIG.FavoriteColor
			starButton.Font = CONFIG.ButtonFont
			starButton.TextSize = 19
			starButton.ZIndex = 2
			starButton.Parent = button

			starButton.Activated:Connect(function()
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

		-- Reliable Activated event for mobile touch & desktop click
		button.Activated:Connect(function()
			-- If already dancing this emote -> toggle off
			if currentButton == button and animt then
				stopCurrentEmote()
				return
			end

			-- Must not be driving, sitting, swimming, moving
			if not canPlayEmote() then
				return
			end

			local track = getOrLoadTrack(emoteData)
			if not track then return end

			stopCurrentEmote()

			animt = track
			pcall(function()
				animt:Play(CONFIG.FadeInTime, 1, 1)
			end)

			currentButton = button
			button.BackgroundTransparency = 0.45
		end)

		button.Parent = emoteList
	end
end

local function filterEmotes(searchText)
	if not CONFIG.EnableSearch then return end
	local filtered = {}
	local sourceList = showingFavorites and favoriteEmotes or emoteAnimations

	if searchText == "" then
		filtered = sourceList
	else
		local search = CONFIG.SearchCaseSensitive and searchText or searchText:lower()
		for _, emoteData in pairs(sourceList) do
			local emoteName = CONFIG.SearchCaseSensitive and emoteData.name or emoteData.name:lower()
			if string.find(emoteName, search, 1, true) then
				table.insert(filtered, emoteData)
			end
		end
	end

	updateEmoteList(filtered)
end

local function toggleFrame()
	if not canPlayEmote() and not mainFrame.Visible then
		-- Don't open panel if busy
		return
	end

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

-- ==================== DRAGGING ====================

local function startDrag(input)
	if not mainFrame.Visible then return end
	isDragging = true
	dragStartPos = input.Position
	frameStartPos = mainFrame.Position
end

local function dragFrame(input)
	if not isDragging or not dragStartPos then return end
	local delta = input.Position - dragStartPos
	mainFrame.Position = frameStartPos + UDim2.new(0, delta.X, 0, delta.Y)
end

local function stopDrag()
	isDragging = false
	dragStartPos = nil
	frameStartPos = nil
	lastFramePosition = mainFrame.Position
end

local function isDragStart(input)
	return input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch
end

local function isDragMove(input)
	return input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch
end

table.insert(globalConnections, mainFrame.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if isDragStart(input) then startDrag(input) end
end))

table.insert(globalConnections, mainFrame.InputChanged:Connect(function(input, gameProcessed)
	if isDragMove(input) then dragFrame(input) end
end))

table.insert(globalConnections, mainFrame.InputEnded:Connect(function(input, gameProcessed)
	if isDragStart(input) then stopDrag() end
end))

-- ==================== CHARACTER SETUP & MOVEMENT HOOKS ====================

local function setupCharacter(character)
	chara = character
	stopCurrentEmote()

	-- Disconnect old character listeners
	for _, conn in ipairs(charConnections) do
		pcall(function() conn:Disconnect() end)
	end
	charConnections = {}

	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end

	-- 1. CRITICAL: Stop dancing immediately when the player starts walking or running!
	table.insert(charConnections, humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		if humanoid.MoveDirection.Magnitude > 0.05 then
			stopCurrentEmote()
		end
	end))

	-- 2. State change handler: stops dance and manages button visibility
	table.insert(charConnections, humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Running
			or newState == Enum.HumanoidStateType.Jumping
			or newState == Enum.HumanoidStateType.Freefall
			or newState == Enum.HumanoidStateType.Climbing
			or newState == Enum.HumanoidStateType.Swimming
			or newState == Enum.HumanoidStateType.Seated
			or newState == Enum.HumanoidStateType.PlatformStanding
			or newState == Enum.HumanoidStateType.Dead then
			stopCurrentEmote()
		end
		updateEmoteButtonVisibility()
	end))

	-- 3. Seated / SeatPart changes (driving bicycle, boat, car, bench)
	table.insert(charConnections, humanoid:GetPropertyChangedSignal("Sit"):Connect(function()
		if humanoid.Sit then
			stopCurrentEmote()
		end
		updateEmoteButtonVisibility()
	end))

	table.insert(charConnections, humanoid:GetPropertyChangedSignal("SeatPart"):Connect(function()
		if humanoid.SeatPart ~= nil then
			stopCurrentEmote()
		end
		updateEmoteButtonVisibility()
	end))

	-- 4. Sleeping / Ragdoll attribute changes
	table.insert(charConnections, character:GetAttributeChangedSignal("Sleeping"):Connect(function()
		updateEmoteButtonVisibility()
	end))

	table.insert(charConnections, humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
		updateEmoteButtonVisibility()
	end))

	-- Initial check & animation preload
	updateEmoteButtonVisibility()
	preloadAnimations(character)
end

-- Lightweight periodic watcher (every 0.25s) to guarantee zero state desync on vehicles/water
local lastStateCheck = 0
table.insert(globalConnections, RunService.Heartbeat:Connect(function(dt)
	lastStateCheck = lastStateCheck + dt
	if lastStateCheck >= 0.25 then
		lastStateCheck = 0
		updateEmoteButtonVisibility()
	end

	-- Instant cancel dance on move
	if animt and chara and chara.Parent then
		local hum = chara:FindFirstChildOfClass("Humanoid")
		if hum and hum.MoveDirection.Magnitude > 0.05 then
			stopCurrentEmote()
		end
	end
end))

-- ==================== INITIALIZATION ====================

loadEmotesFromFolder()
updateEmoteList(emoteAnimations)
loadFavoritesFromServer()

if player.Character then
	setupCharacter(player.Character)
end

table.insert(globalConnections, player.CharacterAdded:Connect(setupCharacter))

-- Button connections (using Activated for instant mobile touch response)
table.insert(globalConnections, emoteButton.Activated:Connect(toggleFrame))
table.insert(globalConnections, closeButton.Activated:Connect(function()
	mainFrame.Visible = false
end))

if CONFIG.EnableSearch then
	table.insert(globalConnections, searchBar:GetPropertyChangedSignal("Text"):Connect(function()
		filterEmotes(searchBar.Text)
	end))
end

if CONFIG.EnableFavorites then
	table.insert(globalConnections, favoriteButton.Activated:Connect(function()
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

table.insert(globalConnections, Players.PlayerRemoving:Connect(function(leavingPlayer)
	if leavingPlayer == player then
		for _, conn in ipairs(charConnections) do
			pcall(function() conn:Disconnect() end)
		end
		charConnections = {}
		for _, conn in ipairs(globalConnections) do
			pcall(function() conn:Disconnect() end)
		end
		globalConnections = {}
		for _, data in pairs(loadedAnimations) do
			if data.track then
				pcall(function() data.track:Destroy() end)
			end
		end
		loadedAnimations = {}
	end
end))
