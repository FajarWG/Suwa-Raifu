# README

## Suwa Life: Nihongo Days (諏訪ライフ ～日本語学校の日々～)

Social life simulation Roblox: kehidupan siswa asing di Suwa, Nagano — belajar bahasa Jepang, arubaito, memancing, hiking, festival.

> Dokumentasi lengkap produk: **PRD.md** (root). Detail desain: **docs/**.

## Setup

### 1. Toolchain

Terinstall via Rokit (`rokit.toml`): **Rojo 7.4.4**, **Selene 0.27.1**, **StyLua 2.0.2**, **Wally 0.3.2**.

```sh
rokit install          # install toolchain
rojo --version
```

Binari berada di `%USERPROFILE%\.rokit\bin` (Windows) atau `~/.rokit/bin` (macOS/Linux).

### 2. Roblox Studio

- Pastikan plugin **Rojo** terpasang di Studio (Tools > Plugins).
- Atau jalankan server sync otomatis: `rojo serve` lalu hubungkan dari Studio.

### 3. Dev flow

```sh
rojo build default.project.json --output SuwaLife.rbxlx   # build sekali
rojo serve default.project.json                           # watch mode (rekomendasi)
```

Saat `rojo serve` aktif, edit di `src/` langsung tersinkron ke Studio.

## Fitur

### Fitur 1 — Interaksi NPC & Starter Quest

- NPC Teacher Sakura di-spawn server-side dengan ProximityPrompt.
- Pemain mendekat → prompt → dialog branching (localization id/en/ja).
- Quest intro: bicara dengan guru → terima quest → dapat buku pelajaran → reward Japanese XP + Yen.
- HUD menampilkan Yen, Japanese XP, level, dan quest aktif.
- Data tersimpan ke DataStore (profile dengan versioning & retry).

### Fitur 2 — Kelas & Quiz Bahasa Jepang

- Tombol "School" di HUD membuka panel daftar 5 lesson (id/en/ja).
- Klik lesson → quiz pilihan ganda (vocab Jepang).
- Server menilai jawaban (60% lulus), beri Japanese XP + attendance.
- Lesson yang selesai ditandai di daftar; progress tersimpan.
- Logika grading di shared `LessonLogic` (testable) + unit test.

## Struktur

```
src/
├── shared/    # types, constants, data defs, remotes, util, localization, services
├── server/    # services (Profile, Economy, Quest, NPC, Spawn), runner.server.lua
└── client/    # controllers (Remote, Profile, Dialog, HUD), runner.client.lua
docs/          # GDD, TDD, style guide, data schema, asset list, localization, QA plan
```

## Lint & format

```sh
selene src        # lint
stylua src        # format (ubah file)
stylua --check src  # cek format (CI)
```

## Test

```sh
rojo build default.project.json --output build/test.rbxlx
rojo test         # menjalankan unit test TestEZ
```

## Git

- Branch `main` = kondisi terverifikasi (lolos playtest).
- Fitur baru → branch `feature/<nama>` → playtest → merge.
- Commit message bahasa deskriptif.

## Dokumen terkait

| Dokumen | Isi |
|---|---|
| `PRD.md` | Konsep produk, scope, roadmap |
| `docs/GDD.md` | Aturan gameplay & progression |
| `docs/TDD.md` | Arsitektur teknis, service, remote |
| `docs/style-guide.md` | Art style, palet, skala |
| `docs/data-schema.md` | Struktur data pemain & defs |
| `docs/asset-list.md` | Daftar aset & status |
| `docs/localization.md` | Sistem bahasa |
| `docs/qa-plan.md` | Rencana testing |
