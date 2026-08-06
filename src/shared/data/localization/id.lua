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

	-- School
	['ui.school.title'] = 'Pelajaran',
	['ui.school.open'] = 'Sekolah',
	['lesson.01.title'] = 'Sapaan',
	['lesson.01.q1'] = 'Apa arti "おはよう"?',
	['lesson.01.q1.a'] = 'Selamat malam',
	['lesson.01.q1.b'] = 'Selamat pagi',
	['lesson.01.q1.c'] = 'Selamat tidur',
	['lesson.01.q2'] = 'Apa arti "ありがとう"?',
	['lesson.01.q2.a'] = 'Terima kasih',
	['lesson.01.q2.b'] = 'Maaf',
	['lesson.01.q2.c'] = 'Selamat tinggal',
	['lesson.02.title'] = 'Angka',
	['lesson.02.q1'] = 'Berapa いち (ichi)?',
	['lesson.02.q1.a'] = 'Dua',
	['lesson.02.q1.b'] = 'Tiga',
	['lesson.02.q1.c'] = 'Satu',
	['lesson.03.title'] = 'Makanan',
	['lesson.03.q1'] = 'Apa arti たべる (taberu)?',
	['lesson.03.q1.a'] = 'Minum',
	['lesson.03.q1.b'] = 'Makan',
	['lesson.03.q1.c'] = 'Memasak',
	['lesson.04.title'] = 'Tempat',
	['lesson.04.q1'] = 'Apa arti がっこう (gakkou)?',
	['lesson.04.q1.a'] = 'Sekolah',
	['lesson.04.q1.b'] = 'Stasiun',
	['lesson.04.q1.c'] = 'Rumah sakit',
	['lesson.05.title'] = 'Kata Kerja Sehari-hari',
	['lesson.05.q1'] = 'Apa arti いく (iku)?',
	['lesson.05.q1.a'] = 'Datang',
	['lesson.05.q1.b'] = 'Tidur',
	['lesson.05.q1.c'] = 'Pergi',
}

return STRINGS
