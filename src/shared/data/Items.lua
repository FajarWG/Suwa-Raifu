--!strict

-- Data definitions statis (single source of truth untuk item).
-- Referensi tipe: shared/types/Definitions.lua (ItemDef).

local ITEMS = {
	onigiri = {
		id = 'onigiri',
		nameKey = 'item.onigiri.name',
		category = 'food',
		price = 150,
		stackable = true,
		consumable = true,
		effects = { hunger = -30, energy = 5 },
		icon = '',
		tags = { 'food', 'japanese' },
	},
	fishing_rod = {
		id = 'fishing_rod',
		nameKey = 'item.fishing_rod.name',
		category = 'fishing',
		price = 2000,
		stackable = false,
		consumable = false,
		effects = {},
		icon = '',
		tags = { 'fishing' },
	},
}

return {
	ITEMS = ITEMS,
}
