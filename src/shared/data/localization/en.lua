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

	-- School
	['ui.school.title'] = 'Lessons',
	['ui.school.open'] = 'School',
	['lesson.01.title'] = 'Greetings',
	['lesson.01.q1'] = 'What does "おはよう" mean?',
	['lesson.01.q1.a'] = 'Good evening',
	['lesson.01.q1.b'] = 'Good morning',
	['lesson.01.q1.c'] = 'Good night',
	['lesson.01.q2'] = 'What does "ありがとう" mean?',
	['lesson.01.q2.a'] = 'Thank you',
	['lesson.01.q2.b'] = 'Sorry',
	['lesson.01.q2.c'] = 'Goodbye',
	['lesson.02.title'] = 'Numbers',
	['lesson.02.q1'] = 'What is いち (ichi)?',
	['lesson.02.q1.a'] = 'Two',
	['lesson.02.q1.b'] = 'Three',
	['lesson.02.q1.c'] = 'One',
	['lesson.03.title'] = 'Food',
	['lesson.03.q1'] = 'What does たべる (taberu) mean?',
	['lesson.03.q1.a'] = 'To drink',
	['lesson.03.q1.b'] = 'To eat',
	['lesson.03.q1.c'] = 'To cook',
	['lesson.04.title'] = 'Places',
	['lesson.04.q1'] = 'What does がっこう (gakkou) mean?',
	['lesson.04.q1.a'] = 'School',
	['lesson.04.q1.b'] = 'Station',
	['lesson.04.q1.c'] = 'Hospital',
	['lesson.05.title'] = 'Daily Verbs',
	['lesson.05.q1'] = 'What does いく (iku) mean?',
	['lesson.05.q1.a'] = 'To come',
	['lesson.05.q1.b'] = 'To sleep',
	['lesson.05.q1.c'] = 'To go',
}

return STRINGS
