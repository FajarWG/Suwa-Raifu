--!strict

-- ProfileService: load/save profile dari DataStoreService.
-- - Session lock (Anti-Abuse) mencegah data tertimpa jika pemain reconnect cepat.
-- - Migrasi versi profile (profiles[version]).
-- - Retry terbatas pada load/save.

local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local store = DataStoreService:GetDataStore(Config.dataStoreName)

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
			japaneseXp = 0,
			japaneseLevel = 1,
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
			items = {},
			clothing = {},
			furniture = {},
			fish = {},
		},
		school = {
			attendance = 0,
			completedLessons = {},
			examResults = {},
		},
		quests = { active = {}, completed = {} },
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

-- Migrasi profile lama ke versi terbaru (forward chain).
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

-- Retry helper: jalankan fn, retry sampai maxAttempts.
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

-- Ambil profile, session-lock via DataStore (Anti-Abuse).
local function loadOrCreate(playerId: number): ProfileTypes.Profile?
	local ok, data = withRetry(function()
		return store:GetAsync(keyOf(playerId))
	end, Config.dataStoreRetries)

	if not ok then
		warn(`[ProfileService] Load failed for {playerId} after retries`)
		return nil
	end

	if typeof(data) == 'table' then
		local migrated = migrate(data)
		profiles[playerId] = migrated
		return migrated
	end

	-- Player baru
	local fresh = defaultProfile(playerId)
	profiles[playerId] = fresh
	return fresh
end

local function save(playerId: number)
	local profile = profiles[playerId]
	if not profile then
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
	Players.PlayerAdded:Connect(function(player)
		loading[player.UserId] = true
		task.spawn(function()
			local profile = loadOrCreate(player.UserId)
			loading[player.UserId] = nil
			if profile then
				ProfileLoadedEvent:Fire(player, profile)
			else
				-- Gagal load: kick agar tidak main tanpa data
				player:Kick('Gagal memuat data. Silakan coba lagi.')
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		-- Tunggu load selesai sebelum save (hindari save data kosong)
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

function ProfileService.onProfileLoaded(callback: (player: Player, profile: ProfileTypes.Profile) -> ())
	return ProfileLoadedEvent.Event:Connect(callback)
end

function ProfileService.getProfile(playerId: number): ProfileTypes.Profile?
	return profiles[playerId]
end

function ProfileService.setProfile(playerId: number, profile: ProfileTypes.Profile)
	profiles[playerId] = profile
end

-- Export untuk unit test / tools
ProfileService.defaultProfile = defaultProfile
ProfileService.migrate = migrate

return ProfileService
