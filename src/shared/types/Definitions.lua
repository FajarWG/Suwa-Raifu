--!strict

export type ItemDef = {
	id: string,
	nameKey: string,
	category: string,
	price: number,
	stackable: boolean,
	consumable: boolean,
	effects: { hunger: number?, energy: number?, happiness: number? },
	icon: string,
	tags: { string },
}

export type QuestDef = {
	id: string,
	titleKey: string,
	descKey: string,
	giverNpcId: string,
	requirements: { japaneseLevel: number? },
	objectives: { type: string, target: string, count: number },
	rewards: { xp: number, yen: number, items: { string } },
}

export type DialogueLine = {
	npcId: string,
	level: string,
	intent: string,
	japanese: string,
	reading: string,
	romaji: string,
	translations: { [string]: string },
}

return nil
