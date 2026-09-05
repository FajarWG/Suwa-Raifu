--!strict

-- Server-authoritative fishing and lakeside shop definitions.

local Fishing = {}

Fishing.fish = {
	wakasagi = {
		id = 'wakasagi',
		name = 'Wakasagi Smelt',
		japaneseName = 'ワカサギ',
		rarity = 'Common',
		weight = 38,
		minLength = 7,
		maxLength = 14,
		baseValue = 90,
		color = Color3.fromRGB(176, 193, 199),
	},
	crucian_carp = {
		id = 'crucian_carp',
		name = 'Crucian Carp',
		japaneseName = 'フナ',
		rarity = 'Common',
		weight = 24,
		minLength = 18,
		maxLength = 34,
		baseValue = 260,
		color = Color3.fromRGB(145, 137, 99),
	},
	common_carp = {
		id = 'common_carp',
		name = 'Common Carp',
		japaneseName = 'コイ',
		rarity = 'Uncommon',
		weight = 15,
		minLength = 35,
		maxLength = 78,
		baseValue = 620,
		color = Color3.fromRGB(173, 128, 72),
	},
	black_bass = {
		id = 'black_bass',
		name = 'Black Bass',
		japaneseName = 'ブラックバス',
		rarity = 'Uncommon',
		weight = 11,
		minLength = 24,
		maxLength = 52,
		baseValue = 540,
		color = Color3.fromRGB(91, 115, 78),
	},
	rainbow_trout = {
		id = 'rainbow_trout',
		name = 'Rainbow Trout',
		japaneseName = 'ニジマス',
		rarity = 'Rare',
		weight = 7,
		minLength = 27,
		maxLength = 58,
		baseValue = 980,
		color = Color3.fromRGB(127, 163, 159),
	},
	eel = {
		id = 'eel',
		name = 'Japanese Eel',
		japaneseName = 'ウナギ',
		rarity = 'Rare',
		weight = 5,
		minLength = 38,
		maxLength = 85,
		baseValue = 1250,
		color = Color3.fromRGB(74, 75, 55),
	},
}

Fishing.junk = {
	old_boot = {
		id = 'old_boot',
		name = 'Old Boot',
		rarity = 'Junk',
		weight = 5,
		baseValue = 5,
	},
	empty_can = {
		id = 'empty_can',
		name = 'Empty Can',
		rarity = 'Junk',
		weight = 4,
		baseValue = 3,
	},
}

Fishing.shops = {
	fishing_supply = {
		id = 'fishing_supply',
		name = 'Suwako Fishing Supply',
		items = {
			{ id = 'fishing_rod', name = 'Beginner Fishing Rod', price = 0, amount = 1 },
			{ id = 'worm_bait', name = 'Worm Bait ×5', price = 0, amount = 5 },
			{ id = 'tackle_box', name = 'Small Tackle Box', price = 0, amount = 1 },
		},
	},
	ice_cream = {
		id = 'ice_cream',
		name = 'Suwako Ice Cream',
		items = {
			{ id = 'vanilla_ice_cream', name = 'Vanilla Ice Cream', price = 0, amount = 1 },
			{ id = 'matcha_ice_cream', name = 'Matcha Ice Cream', price = 0, amount = 1 },
			{ id = 'apple_sorbet', name = 'Shinshu Apple Sorbet', price = 0, amount = 1 },
		},
	},
	island_festival = {
		id = 'island_festival',
		name = 'Hatsushima Festival Stall',
		items = {
			{ id = 'dango', name = 'Hanami Dango', price = 0, amount = 1 },
			{ id = 'yakisoba', name = 'Festival Yakisoba', price = 0, amount = 1 },
			{ id = 'taiyaki', name = 'Warm Taiyaki', price = 0, amount = 1 },
			{ id = 'onigiri', name = 'Salmon Onigiri', price = 0, amount = 1 },
			{ id = 'ramune', name = 'Cold Ramune', price = 0, amount = 1 },
			{ id = 'matcha_tea', name = 'Iced Matcha Tea', price = 0, amount = 1 },
			{ id = 'sparkler_pack', name = 'Sparkler Pack', price = 0, amount = 1 },
		},
	},
}

Fishing.itemNames = {
	fishing_rod = 'Beginner Fishing Rod',
	worm_bait = 'Worm Bait',
	tackle_box = 'Small Tackle Box',
	vanilla_ice_cream = 'Vanilla Ice Cream',
	matcha_ice_cream = 'Matcha Ice Cream',
	apple_sorbet = 'Shinshu Apple Sorbet',
	dango = 'Hanami Dango',
	yakisoba = 'Festival Yakisoba',
	taiyaki = 'Warm Taiyaki',
	onigiri = 'Salmon Onigiri',
	ramune = 'Cold Ramune',
	matcha_tea = 'Iced Matcha Tea',
	sparkler_pack = 'Sparkler Pack',
	old_boot = 'Old Boot',
	empty_can = 'Empty Can',
}

return Fishing
