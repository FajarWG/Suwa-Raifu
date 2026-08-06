# HANDOFF — Suwa Life: Nihongo Days

**Tanggal:** 2026-08-06
**Repo:** https://github.com/FajarWG/Suwa-Raifu.git
**Branch:** `main`

Dokumen ini untuk meneruskan konteks kepada developer/AI berikutnya. Baca juga: `PRD.md`, `README.md`, dan `docs/`.

---

## 1. Status Proyek

Prototype Roblox (Luau + Rojo). Empat commit awal sudah di-push:

| Commit | Isi |
|---|---|
| `a5414cd` | Setup: dokumen, toolchain (Rokit/Rojo/Selene/StyLua/Wally), struktur Rojo, TestEZ |
| `bdf8cac` | Fitur 1: NPC dialog + starter quest + profile/ekonomi/inventori + DataStore |
| `5cf1ac7` | Map blockout asrama + SpawnLocation |
| `9693e93` | Fitur 2: kelas & quiz bahasa Jepang (5 lesson, 3 bahasa) |

## 2. Alur Gameplay Saat Ini (playable vertical slice)

1. Pemain spawn di asrama (SpawnLocation).
2. Dekati Teacher Sakura (NPC kotak + ProximityPrompt) → dialog → terima quest intro.
3. Quest selesai → dapat buku pelajaran + XP + Yen.
4. Buka tombol "School" di HUD → kerjakan quiz → dapat Japanese XP + attendance.
5. Progress tersimpan ke DataStore saat keluar.

## 3. Arsitektur

```
src/
├── shared/
│   ├── types/          # ProfileTypes, QuestTypes, NpcTypes, LessonTypes, ...
│   ├── constants/Config.lua
│   ├── data/           # Items (item/quest/lesson), NPCs, localization/{id,en,ja}
│   ├── services/       # LocalizationService
│   ├── util/           # Math, QuestLogic, LessonLogic (murni, di-unit-test)
│   └── remotes.lua     # registry nama RemoteEvent/Function (satu sumber kebenaran)
├── server/
│   ├── runner.server.lua   # init RemoteRegistryService dulu, lalu service lain
│   └── services/
│       ├── RemoteRegistryService  # buat remote + rate limit + register helper
│       ├── ProfileService         # DataStore, session lock, migrasi, retry
│       ├── EconomyService         # yen, Japanese XP, level
│       ├── InventoryService       # item add/remove/count
│       ├── QuestService           # state quest, progress objective, reward
│       ├── NPCDialogService       # serve dialog tree
│       ├── SchoolService          # check-in, lesson, quiz grading
│       ├── ProfileAPI             # hookup GetProfile/QuestAccept/QuestClaim/GetQuestLog
│       ├── SpawnService           # spawn NPC + ProximityPrompt
│       └── TimeService            # skeleton clock
└── client/
    ├── runner.client.lua
    └── controllers/
        ├── RemoteController       # wrapper fire/invoke/onEvent
        ├── ProfileController      # ambil profile + set locale
        ├── DialogController       # UI dialog branching
        ├── HUDController          # status yen/xp/level, quest log, tombol School
        └── SchoolController       # panel lesson + quiz
maps/
└── SuwaCentral.model.json         # baseplate + asrama blockout
tests/
├── TestRunner.server.lua          # TestEZ runner (butuh Roblox utk jalan)
└── specs/                         # Math, QuestLogic, LessonLogic spec
```

**Pola kunci:**
- Semua state otoritatif di server; client hanya kirim intent lewat remote.
- Logika murni dipisah ke `shared/util/*` supaya bisa di-unit-test (TestEZ).
- Semua remote terdaftar di `shared/remotes.lua`; server register via `RemoteRegistryService`.
- Semua teks pakai localization key (`shared/data/localization/`), fallback `en`.

## 4. Toolchain & Perintah

Tool di-install via Rokit (`rokit.toml`): Rojo 7.4.4, Selene 0.27.1, StyLua 2.0.2, Wally 0.3.2.
Binari: `%USERPROFILE%\.rokit\bin` (Windows).

```sh
rojo build default.project.json --output build/SuwaLife.rbxlx   # build
rojo serve default.project.json                                 # watch mode -> Studio
selene src                                                      # lint
stylua src                                                      # format
rojo build tests.project.json --output build/SuwaLife-Test.rbxlx  # build test place
```

> Catatan: `rojo test` dihapus di Rojo 7. Unit test TestEZ dijalankan lewat Roblox
> Studio (plugin TestEZ / `tests.project.json`), bukan dari CLI.

## 5. Konvensi Kode

- `--!strict` di semua file, tabs, single quotes (StyLua `AutoPreferSingle`).
- Server services: ModuleScript dengan `init()`, di-auto-load runner.
- Client controllers: ModuleScript dengan `init()`, di-auto-load runner.
- Return pattern service: `{ ok = true, data = ... }` / `{ ok = false, error = ... }`.
- Tambah remote baru = daftarkan di `shared/remotes.lua` (events/functions) + register di service.
- Tambah teks baru = tambahkan key di `shared/data/localization/{id,en,ja}.lua` (wajib, kalau cuma en, bahasa lain fallback).
- Logika bisnis murni → taruh di `shared/util/` + tulis spec di `tests/specs/`.

## 6. Hal yang Perlu Diperhatikan (Known Issues / TODO)

1. **NPC masih kotak polos** — belum pakai karakter rig/animasi. Cari aset Creator Store atau buat model sederhana.
2. **Posisi NPC hardcoded** di `SpawnService` (asrama). Nanti pakai konfigurasi per map/Place.
3. **ProfileService load async** — `GetProfile` bisa balik `nil` jika dipanggil terlalu cepat setelah join (client pakai task.spawn; masih aman tapi bisa lebih halus).
4. **Item starter quest hardcoded** (`Config.initialQuestId`/`textbookItemId`) — generalisasi nanti (giver memberikan item via def quest).
5. **TimeService masih skeleton** — belum dipakai untuk day/season/weather (memancing, hiking butuh ini).
6. **TestEZ tidak bisa dijalankan headless** tanpa Roblox/Rust. Pastikan test dijalankan di Studio sebelum merge fitur.
7. **Quest claim flow** — saat ini reward langsung saat quest selesai; belum ada UI "Claim" terpisah.
8. **Anti-exploit belum penuh** — rate limit ada di RemoteRegistryService, tapi belum ada validasi posisi/area (check-in kelas, interaksi NPC).

## 7. Roadmap Berikutnya (sesuai PRD §16 MVP)

Prioritas yang paling masuk akal untuk loop "menyenangkan":

1. **Arubaito programmer** (mini-game blok logika) — pakai pola SchoolService + LessonLogic.
2. **Shopping/economy** — supermarket fiktif, katalog item, beli/jual (ShopService).
3. **Memancing** — TimeService dipakai utk waktu/cuaca/musim, server RNG hasil tangkapan.
4. **Sepeda** — client prediction + server validation.
5. **Day/night + energy/hunger** — biarkan stamina turun, tidur untuk reset.
6. **Festival kembang api sederhana** — event + badge.

Setiap fitur ikuti alur:
`data def (shared) → pure logic (shared/util) + spec → service (server) → controller+UI (client) → lint/stylua/build → playtest di Studio → commit`.

## 8. Cara Melanjutkan

```sh
git clone https://github.com/FajarWG/Suwa-Raifu.git
cd Suwa-Raifu
rokit install                      # install toolchain
rojo build default.project.json --output build/SuwaLife.rbxlx
# buka build/SuwaLife.rbxlx di Roblox Studio, Play
```

Untuk fitur baru: buat branch `feature/<nama>`, ikuti konvensi §5, playtest, merge ke `main`.
