--!strict

-- Localization: Bahasa Indonesia (id).
-- Key yang belum diterjemahkan tampil apa adanya (fallback).

local STRINGS: { [string]: string } = {
	-- UI umum
	['ui.app.title'] = 'Suwa Life: Nihongo Days',
	['ui.questlog.title'] = 'Quest',
	['ui.questlog.empty'] = 'Belum ada quest aktif.',
	['ui.dialog.continue'] = 'Lanjutkan',
	['ui.dialog.close'] = 'Tutup',

	-- NPC
	['npc.teacher_sakura.name'] = 'Guru Sakura',
	['npc.teacher_sakura.title'] = 'Guru Bahasa Jepang',

	-- Dialog (key tunggal; jangan pakai format)
	['dialog.sakura.greet1'] = 'Selamat pagi! Kamu siswa baru ya?',
	['dialog.sakura.greet2'] = 'Selamat datang di sekolah bahasa Jepang.',
	['dialog.sakura.choice.intro'] = 'Boleh perkenalan?',
	['dialog.sakura.choice.bye'] = 'Sampai nanti.',
	['dialog.sakura.intro1'] = 'Senang bertemu denganmu!',
	['dialog.sakura.intro2'] = 'Namaku Sakura, guru bahasa Jepang.',
	['dialog.sakura.quest_offer'] = 'Bagaimana kalau kamu mulai belajar dengan buku ini?',
	['dialog.sakura.choice.accept'] = 'Terima quest!',
	['dialog.sakura.choice.decline'] = 'Belum dulu.',
	['dialog.sakura.quest_accepted'] = 'Bagus! Ambil buku pelajaranmu, ya.',
	['dialog.sakura.quest_completed'] = 'Hebat! Kamu dapat XP bahasa Jepang.',

	-- Item
	['item.onigiri.name'] = 'Onigiri',
	['item.textbook.name'] = 'Buku Pelajaran',
	['item.fishing_rod.name'] = 'Pancing',

	-- Quest
	['quest.intro.title'] = 'Kenalan dengan Guru',
	['quest.intro.desc'] = 'Bicaralah dengan Guru Sakura dan ambil buku pelajaranmu.',
}

return STRINGS
