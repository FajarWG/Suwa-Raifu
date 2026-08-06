--!strict

-- Data definitions statis (single source of truth untuk item/quest/lesson).
-- Referensi tipe: shared/types/Definitions.lua (ItemDef),
-- shared/types/QuestDefTypes.lua (QuestDef).

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
	-- Quest pembuka: kenalan dengan guru & dapatkan buku pelajaran.
	quest_intro = {
		id = 'quest_intro',
		titleKey = 'quest.intro.title',
		descKey = 'quest.intro.desc',
		giverNpcId = 'teacher_sakura',
		requirements = { japaneseLevel = 1 },
		objectives = {
			{ id = 'talk_sakura', type = 'talk', target = 'teacher_sakura', requiredCount = 1 },
			{ id = 'get_textbook', type = 'collect', target = 'textbook', requiredCount = 1 },
		},
		rewards = {
			xp = 100,
			yen = 500,
			items = {},
		},
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
