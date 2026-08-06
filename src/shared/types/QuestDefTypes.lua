--!strict

-- Quest definition (statis, data).

export type QuestObjectiveDef = {
	id: string,
	type: string,
	target: string,
	requiredCount: number,
}

export type QuestDef = {
	id: string,
	titleKey: string,
	descKey: string,
	giverNpcId: string,
	requirements: {
		japaneseLevel: number?,
	},
	objectives: { QuestObjectiveDef },
	rewards: {
		xp: number,
		yen: number,
		items: { string },
	},
}

export type QuestDefs = { [string]: QuestDef }

return nil
