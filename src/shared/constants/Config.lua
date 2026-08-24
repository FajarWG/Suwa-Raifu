--!strict

-- Global game configuration (single source of truth).

export type GameConfig = {
	-- Server and gameplay
	maxPlayersPerServer: number,
	dailyLoopDurationMinutes: number, -- length of one in-game day, in real minutes
	dayPhases: { string },

	-- Economy
	startingYen: number,
	startingEnergy: number,
	startingHunger: number,
	maxEnergy: number,
	maxHunger: number,

	-- Remote rate limit (calls per second per player)
	remoteRateLimit: number,

	-- DataStore
	dataStoreName: string,
	profileKeyPrefix: string,
	profileVersion: number,
	dataStoreRetries: number,

	-- Language
	availableLocales: { string },
	defaultLocale: string,
}

local Config: GameConfig = {
	maxPlayersPerServer = 30,
	dailyLoopDurationMinutes = 20,
	dayPhases = { 'morning', 'daytime', 'evening', 'night', 'late_night' },

	startingYen = 5000,
	startingEnergy = 100,
	startingHunger = 0,
	maxEnergy = 100,
	maxHunger = 100,

	remoteRateLimit = 10,

	dataStoreName = 'SuwaLife_Profiles',
	profileKeyPrefix = 'player_',
	profileVersion = 1,
	dataStoreRetries = 3,

	-- English only for now.
	availableLocales = { 'en' },
	defaultLocale = 'en',
}

return Config
