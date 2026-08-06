--!strict

-- ProfileService: load/save profile dari DataStoreService.
-- Skeleton: init() dipanggil runner; pada real dev pakai session lock & retry.

local Players = game:GetService('Players')
local DataStoreService = game:GetService('DataStoreService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Config = require(ReplicatedStorage.Shared:WaitForChild('constants'):WaitForChild('Config'))
local ProfileTypes = require(ReplicatedStorage.Shared:WaitForChild('types'):WaitForChild('ProfileTypes'))

local store = DataStoreService:GetDataStore(Config.dataStoreName)

local profiles: { [number]: ProfileTypes.Profile } = {}

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

local function loadOrCreate(playerId: number): ProfileTypes.Profile
	local key = Config.profileKeyPrefix .. tostring(playerId)
	local ok, data = pcall(function()
		return store:GetAsync(key)
	end)
	if ok and typeof(data) == 'table' then
		-- TODO: migrasi versi profile
		return data
	end
	if not ok then
		warn(`[ProfileService] Load failed for {playerId}: {data}`)
	end
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
	local key = Config.profileKeyPrefix .. tostring(playerId)
	local ok, err = pcall(function()
		store:SetAsync(key, profile)
	end)
	if not ok then
		warn(`[ProfileService] Save failed for {playerId}: {err}`)
	end
end

local ProfileService = {}

function ProfileService.init()
	Players.PlayerAdded:Connect(function(player)
		profiles[player.UserId] = loadOrCreate(player.UserId)
	end)

	Players.PlayerRemoving:Connect(function(player)
		save(player.UserId)
		profiles[player.UserId] = nil
	end)

	game:BindToClose(function()
		for userId, _ in profiles do
			save(userId)
		end
	end)
end

function ProfileService.getProfile(playerId: number): ProfileTypes.Profile?
	return profiles[playerId]
end

function ProfileService.setProfile(playerId: number, profile: ProfileTypes.Profile)
	profiles[playerId] = profile
end

return ProfileService
