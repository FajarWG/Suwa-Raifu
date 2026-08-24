--!strict

-- Localization: Bahasa Indonesia (id).
-- Key yang belum diterjemahkan tampil apa adanya (fallback).

local STRINGS: { [string]: string } = {
	-- UI umum
	['ui.app.title'] = 'Suwa Life: Nihongo Days',
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

	-- Item
	['item.onigiri.name'] = 'Onigiri',
	['item.fishing_rod.name'] = 'Pancing',
}

return STRINGS
