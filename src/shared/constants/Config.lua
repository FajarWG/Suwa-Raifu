--!strict

-- Global konfigurasi game (single source of truth).
-- PRD: pemain/server, ekonomi, time system.

export type GameConfig = {
	-- Server & gameplay
	maxPlayersPerServer: number,
	dailyLoopDurationMinutes: number, -- durasi 1 hari game (real menit)
	dayPhases: { string },

	-- Ekonomi
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

	-- Quest
	initialQuestId: string,
	textbookItemId: string,

	-- NPC
	spawnNpcId: string,

	-- Bahasa
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

	initialQuestId = 'quest_intro',
	textbookItemId = 'textbook',

	spawnNpcId = 'teacher_sakura',

	-- Prototype map-first memakai English saja. Resource ja/id disimpan untuk phase localization nanti.
	availableLocales = { 'en' },
	defaultLocale = 'en',
}

return Config
