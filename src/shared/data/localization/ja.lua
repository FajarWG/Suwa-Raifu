--!strict

-- Localization: Bahasa Jepang (ja).

local STRINGS: { [string]: string } = {
	-- UI umum
	['ui.app.title'] = 'Suwa Life: Nihongo Days',
	['ui.questlog.title'] = 'クエスト',
	['ui.questlog.empty'] = '進行中のクエストはありません。',
	['ui.dialog.continue'] = 'つづける',
	['ui.dialog.close'] = 'とじる',

	-- NPC
	['npc.teacher_sakura.name'] = 'さくら先生',
	['npc.teacher_sakura.title'] = '日本語の先生',

	-- Dialog
	['dialog.sakura.greet1'] = 'おはようございます！新入生ですか？',
	['dialog.sakura.greet2'] = '日本語学校へようこそ。',
	['dialog.sakura.choice.intro'] = 'じこしょうかいしてもいいですか？',
	['dialog.sakura.choice.bye'] = 'またあとで。',
	['dialog.sakura.intro1'] = 'はじめまして！',
	['dialog.sakura.intro2'] = 'さくらです。日本語の先生です。',
	['dialog.sakura.quest_offer'] = 'このきょうかしょでべんきょうをはじめませんか？',
	['dialog.sakura.choice.accept'] = 'クエストをうける！',
	['dialog.sakura.choice.decline'] = 'まだいいです。',
	['dialog.sakura.quest_accepted'] = 'いいですね！きょうかしょをとってください。',
	['dialog.sakura.quest_completed'] = 'よくできました！日本語XPをゲット。',

	-- Item
	['item.onigiri.name'] = 'おにぎり',
	['item.textbook.name'] = 'きょうかしょ',
	['item.fishing_rod.name'] = 'つりざお',

	-- Quest
	['quest.intro.title'] = '先生にあいさつしよう',
	['quest.intro.desc'] = 'さくら先生とはなして、きょうかしょをゲットしよう。',

	-- School
	['ui.school.title'] = 'レッスン',
	['ui.school.open'] = 'がっこう',
	['lesson.01.title'] = 'あいさつ',
	['lesson.01.q1'] = '「おはよう」はどういういみ？',
	['lesson.01.q1.a'] = 'こんばんは',
	['lesson.01.q1.b'] = 'おはよう（あさのあいさつ）',
	['lesson.01.q1.c'] = 'おやすみ',
	['lesson.01.q2'] = '「ありがとう」はどういういみ？',
	['lesson.01.q2.a'] = 'ありがとう（かんしゃ）',
	['lesson.01.q2.b'] = 'ごめんなさい',
	['lesson.01.q2.c'] = 'さようなら',
	['lesson.02.title'] = 'すうじ',
	['lesson.02.q1'] = '「いち」はいくつ？',
	['lesson.02.q1.a'] = 'に',
	['lesson.02.q1.b'] = 'さん',
	['lesson.02.q1.c'] = 'いち（1）',
	['lesson.03.title'] = 'たべもの',
	['lesson.03.q1'] = '「たべる」はどういういみ？',
	['lesson.03.q1.a'] = 'のむ',
	['lesson.03.q1.b'] = 'たべる',
	['lesson.03.q1.c'] = 'りょうりする',
	['lesson.04.title'] = 'ばしょ',
	['lesson.04.q1'] = '「がっこう」はどういういみ？',
	['lesson.04.q1.a'] = 'がっこう（スクール）',
	['lesson.04.q1.b'] = 'えき',
	['lesson.04.q1.c'] = 'びょういん',
	['lesson.05.title'] = 'まいにちのどうし',
	['lesson.05.q1'] = '「いく」はどういういみ？',
	['lesson.05.q1.a'] = 'くる',
	['lesson.05.q1.b'] = 'ねる',
	['lesson.05.q1.c'] = 'いく（いく）',
}

return STRINGS
