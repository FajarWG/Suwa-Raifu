--!strict

-- Data definitions statis. Nanti diganti file data (JSON) atau isi dari sini.
-- Katalog contoh untuk skeleton.

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
	textbook = {
		id = 'textbook',
		nameKey = 'item.textbook.name',
		category = 'school',
		price = 800,
		stackable = false,
		consumable = false,
		effects = {},
		icon = '',
		tags = { 'school' },
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

local QUESTS = {
	quest_intro = {
		id = 'quest_intro',
		titleKey = 'quest.intro.title',
		descKey = 'quest.intro.desc',
		giverNpcId = 'teacher_sakura',
		requirements = { japaneseLevel = 1 },
		objectives = {
			{ type = 'talk', target = 'teacher_sakura', count = 1 },
		},
		rewards = { xp = 100, yen = 0, items = { 'textbook' } },
	},
}

local LESSONS = {
	lesson_01 = {
		id = 'lesson_01',
		titleKey = 'lesson.01.title',
		level = 'beginner1',
		quiz = {
			{
				promptKey = 'lesson.01.q1',
				choices = { 'a', 'b', 'c' },
				answer = 1,
			},
		},
	},
}

return {
	ITEMS = ITEMS,
	QUESTS = QUESTS,
	LESSONS = LESSONS,
}
