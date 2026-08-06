--!strict

-- Localization: Bahasa Inggris (en) — fallback utama.

local STRINGS: { [string]: string } = {
	-- UI umum
	['ui.app.title'] = 'Suwa Life: Nihongo Days',
	['ui.questlog.title'] = 'Quests',
	['ui.questlog.empty'] = 'No active quests.',
	['ui.dialog.continue'] = 'Continue',
	['ui.dialog.close'] = 'Close',

	-- NPC
	['npc.teacher_sakura.name'] = 'Teacher Sakura',
	['npc.teacher_sakura.title'] = 'Japanese Language Teacher',

	-- Dialog
	['dialog.sakura.greet1'] = 'Good morning! You must be the new student.',
	['dialog.sakura.greet2'] = 'Welcome to the Japanese language school.',
	['dialog.sakura.choice.intro'] = 'Could you introduce yourself?',
	['dialog.sakura.choice.bye'] = 'See you later.',
	['dialog.sakura.intro1'] = 'Nice to meet you!',
	['dialog.sakura.intro2'] = "I'm Sakura, your Japanese teacher.",
	['dialog.sakura.quest_offer'] = 'How about you start learning with this textbook?',
	['dialog.sakura.choice.accept'] = 'Accept quest!',
	['dialog.sakura.choice.decline'] = 'Not yet.',
	['dialog.sakura.quest_accepted'] = "Great! Don't forget to pick up your textbook.",
	['dialog.sakura.quest_completed'] = 'Well done! You earned Japanese XP.',

	-- Item
	['item.onigiri.name'] = 'Onigiri',
	['item.textbook.name'] = 'Textbook',
	['item.fishing_rod.name'] = 'Fishing Rod',

	-- Quest
	['quest.intro.title'] = 'Meet Your Teacher',
	['quest.intro.desc'] = 'Talk to Teacher Sakura and pick up your textbook.',
}

return STRINGS
