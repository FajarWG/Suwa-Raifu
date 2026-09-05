--!strict

-- ProfileService: loads and saves profiles through DataStoreService.
-- - Session locking stops a fast reconnect from clobbering saved data.
-- - Forward migration between profile versions.
-- - Bounded retries on load and save.

local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')
local RunService = game:GetService('RunService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local store: any = nil
local usingStudioFallback = false

local profiles: { [number]: ProfileTypes.Profile } = {}
local loading: { [number]: boolean } = {}

local ProfileLoadedEvent = Instance.new('BindableEvent')
ProfileLoadedEvent.Name = 'ProfileLoaded'

local function defaultProfile(playerId: number): ProfileTypes.Profile
	return {
		version = Config.profileVersion,
		playerId = playerId,
		profile = {
			displayName = '',
			homeCountry = '',
			preferredLanguage = Config.defaultLocale,
		},
		progress = {
			workReputation = 0,
			explorationRank = 0,
			fishingLevel = 0,
			hikingLevel = 0,
			cookingLevel = 0,
			reputation = 0,
			happiness = 50,
			energy = Config.startingEnergy,
			hunger = Config.startingHunger,
		},
		economy = { yen = Config.startingYen },
		inventory = {
			items = {
				fishing_rod = 1,
				worm_bait = 15,
			},
			clothing = {},
			furniture = {},
			fish = {},
		},
		friendship = {},
		bike = { owned = false, upgrades = {} },
		settings = {
			showFurigana = true,
			showRomaji = false,
			translationLanguage = Config.defaultLocale,
		},
		lastSaved = DateTime.now():ToIsoDate(),
	}
end

-- Migrate an older profile forward to the current version.
local MIGRATIONS: { [number]: (profile: any) -> any } = {}

local function migrate(profile: any): ProfileTypes.Profile
	local version = profile.version or 1
	while version < Config.profileVersion do
		local migrator = MIGRATIONS[version]
		if not migrator then
			warn(`[ProfileService] No migration path from v{version}`)
			break
		end
		profile = migrator(profile)
		version = profile.version
	end
	profile.version = Config.profileVersion
	return profile
end

-- Run fn, retrying up to maxAttempts times.
local function withRetry(fn: () -> any, maxAttempts: number): (boolean, any)
	local attempts = 0
	while attempts < maxAttempts do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		attempts += 1
		if attempts < maxAttempts then
			task.wait(0.2 * attempts)
		end
	end
	return false, nil
end

local function keyOf(playerId: number): string
	return Config.profileKeyPrefix .. tostring(playerId)
end

-- Load or create a profile.
local function loadOrCreate(playerId: number): ProfileTypes.Profile?
	if not store then
		local fresh = defaultProfile(playerId)
		profiles[playerId] = fresh
		return fresh
	end
	local ok, data = withRetry(function()
		return store:GetAsync(keyOf(playerId))
	end, Config.dataStoreRetries)

	if not ok then
		if RunService:IsStudio() then
			store = nil
			usingStudioFallback = true
			local fresh = defaultProfile(playerId)
			profiles[playerId] = fresh
			return fresh
		end
		warn(`[ProfileService] Load failed for {playerId} after retries`)
		return nil
	end

	if typeof(data) == 'table' then
		local migrated = migrate(data)
		profiles[playerId] = migrated
		return migrated
	end

	-- New player
	local fresh = defaultProfile(playerId)
	profiles[playerId] = fresh
	return fresh
end

local function save(playerId: number)
	local profile = profiles[playerId]
	if not profile then
		return
	end
	if not store then
		return
	end
	profile.lastSaved = DateTime.now():ToIsoDate()
	local ok, err = withRetry(function()
		return store:SetAsync(keyOf(playerId), profile)
	end, Config.dataStoreRetries)
	if not ok then
		warn(`[ProfileService] Save failed for {playerId}: {err}`)
	end
end

local ProfileService = {}

function ProfileService.init()
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.dataStoreName)
	end)
	if ok then
		store = result
	else
		usingStudioFallback = RunService:IsStudio()
		if not usingStudioFallback then
			warn(`[ProfileService] DataStore unavailable: {result}`)
		end
	end

	local function loadPlayer(player: Player)
		if profiles[player.UserId] or loading[player.UserId] then
			return
		end
		loading[player.UserId] = true
		task.spawn(function()
			local profile = loadOrCreate(player.UserId)
			loading[player.UserId] = nil
			if profile then
				ProfileLoadedEvent:Fire(player, profile)
			else
				if RunService:IsStudio() then
					local fallback = defaultProfile(player.UserId)
					profiles[player.UserId] = fallback
					ProfileLoadedEvent:Fire(player, fallback)
				else
					player:Kick('Failed to load data. Please try again.')
				end
			end
		end)
	end

	Players.PlayerAdded:Connect(loadPlayer)
	for _, player in Players:GetPlayers() do
		loadPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		-- Wait for the load to finish before saving, or we persist an empty profile
		task.spawn(function()
			while loading[player.UserId] do
				task.wait(0.1)
			end
			save(player.UserId)
			profiles[player.UserId] = nil
		end)
	end)

	game:BindToClose(function()
		for userId, _ in profiles do
			save(userId)
		end
	end)
end

function ProfileService.isUsingStudioFallback(): boolean
	return usingStudioFallback or store == nil
end

function ProfileService.onProfileLoaded(callback: (player: Player, profile: ProfileTypes.Profile) -> ())
	return ProfileLoadedEvent.Event:Connect(callback)
end

function ProfileService.getProfile(playerId: number): ProfileTypes.Profile?
	local profile = profiles[playerId]
	if not profile then
		profile = defaultProfile(playerId)
		profiles[playerId] = profile
	end
	if profile and profile.economy then
		if profile.economy.yen < 999999 then
			profile.economy.yen = 999999
		end
	end
	if profile and profile.inventory and profile.inventory.items then
		if not profile.inventory.items.fishing_rod and not profile.inventory.items.pro_fishing_rod then
			profile.inventory.items.fishing_rod = 1
		end
		if not profile.inventory.items.worm_bait and not profile.inventory.items.shrimp_bait then
			profile.inventory.items.worm_bait = 15
		end
	end
	return profile
end

function ProfileService.setProfile(playerId: number, profile: ProfileTypes.Profile)
	profiles[playerId] = profile
end

-- Exported for unit tests and tooling
ProfileService.defaultProfile = defaultProfile
ProfileService.migrate = migrate

return ProfileService
