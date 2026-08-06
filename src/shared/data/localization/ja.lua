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
}

return STRINGS
