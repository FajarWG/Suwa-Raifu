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
				choices = { 'lesson.01.q1.a', 'lesson.01.q1.b', 'lesson.01.q1.c' },
				answer = 1,
			},
			{
				promptKey = 'lesson.01.q2',
				choices = { 'lesson.01.q2.a', 'lesson.01.q2.b', 'lesson.01.q2.c' },
				answer = 0,
			},
		},
	},
	lesson_02 = {
		id = 'lesson_02',
		titleKey = 'lesson.02.title',
		level = 'beginner1',
		quiz = {
			{
				promptKey = 'lesson.02.q1',
				choices = { 'lesson.02.q1.a', 'lesson.02.q1.b', 'lesson.02.q1.c' },
				answer = 2,
			},
		},
	},
	lesson_03 = {
		id = 'lesson_03',
		titleKey = 'lesson.03.title',
		level = 'beginner1',
		quiz = {
			{
				promptKey = 'lesson.03.q1',
				choices = { 'lesson.03.q1.a', 'lesson.03.q1.b', 'lesson.03.q1.c' },
				answer = 1,
			},
		},
	},
	lesson_04 = {
		id = 'lesson_04',
		titleKey = 'lesson.04.title',
		level = 'beginner1',
		quiz = {
			{
				promptKey = 'lesson.04.q1',
				choices = { 'lesson.04.q1.a', 'lesson.04.q1.b', 'lesson.04.q1.c' },
				answer = 0,
			},
		},
	},
	lesson_05 = {
		id = 'lesson_05',
		titleKey = 'lesson.05.title',
		level = 'beginner1',
		quiz = {
			{
				promptKey = 'lesson.05.q1',
				choices = { 'lesson.05.q1.a', 'lesson.05.q1.b', 'lesson.05.q1.c' },
				answer = 2,
			},
		},
	},
}

return {
	ITEMS = ITEMS,
	QUESTS = QUESTS,
	LESSONS = LESSONS,
}
