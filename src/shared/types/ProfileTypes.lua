--!strict

export type JapaneseLevel = 'beginner1' | 'beginner2' | 'elementary' | 'intermediate' | 'advanced'

export type Profile = {
	version: number,
	playerId: number,
	profile: {
		displayName: string,
		homeCountry: string,
		preferredLanguage: string,
	},
	progress: {
		workReputation: number,
		explorationRank: number,
		fishingLevel: number,
		hikingLevel: number,
		cookingLevel: number,
		reputation: number,
		happiness: number,
		energy: number,
		hunger: number,
	},
	economy: {
		yen: number,
	},
	inventory: {
		items: { [string]: number },
		clothing: { [string]: number },
		furniture: { [string]: number },
		fish: { [string]: number },
	},
	friendship: { [string]: number },
	bike: {
		owned: boolean,
		upgrades: { [string]: boolean },
	},
	settings: {
		showFurigana: boolean,
		showRomaji: boolean,
		translationLanguage: string,
	},
	lastSaved: string,
}

export type Result<T> = { ok: true, data: T } | { ok: false, error: string }

export type TimeInfo = {
	dayNumber: number,
	hour: number,
	minute: number,
	season: string,
	weather: string,
}

return nil
