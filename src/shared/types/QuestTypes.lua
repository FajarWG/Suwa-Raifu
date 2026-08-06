--!strict

-- Definisi tipe shared untuk sistem game.

export type JapaneseLevel = 'beginner1' | 'beginner2' | 'elementary' | 'intermediate' | 'advanced'

export type Result<T> = { ok: true, data: T } | { ok: false, error: string }

export type TimeInfo = {
	dayNumber: number,
	hour: number,
	minute: number,
	season: string,
	weather: string,
}

-- Objective quest: type menentukan cara progress.
-- talk = bicara ke NPC target, collect = punya item target.
export type QuestObjective = {
	id: string,
	type: 'talk' | 'collect',
	target: string,
	requiredCount: number,
	currentCount: number,
	complete: boolean,
}

export type QuestState = {
	id: string,
	objectives: { QuestObjective },
	acceptedAt: number,
}

return nil
