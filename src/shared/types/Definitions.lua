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

export type Items = { [string]: ItemDef }

return nil
