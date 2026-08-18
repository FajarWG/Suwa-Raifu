# IMPLEMENTATION STATUS

## Suwa Life: Nihongo Days

**Tanggal audit:** 2026-08-18  
**Sumber audit:** kode aktif di `src/`, runner, remotes, dan test specs.

---

## Ringkasan

Status implementasi saat ini adalah **vertical slice map-first**. Sebagian core loop sudah playable, tetapi beberapa fitur PRD masih berupa backlog dan belum layak dianggap selesai.

## Matriks status fitur

| Area                                                | Status              | Bukti kode                                                                                                                                     | Catatan                                                                                                  |
| --------------------------------------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| Server bootstrap & remote registry                  | Selesai             | `src/server/runner.server.lua`, `src/server/services/RemoteRegistryService.lua`, `src/shared/remotes.lua`                                      | Init ordering sudah jelas; terrain diprioritaskan sebelum service map lain.                              |
| Profile/DataStore fallback                          | Selesai (MVP)       | `src/server/services/ProfileService.lua`, `src/server/services/ProfileAPI.lua`                                                                 | Ada fallback Studio saat DataStore tidak tersedia; perlu validasi publish environment.                   |
| NPC dialog + starter quest                          | Selesai (MVP)       | `src/server/services/NPCDialogService.lua`, `src/server/services/QuestService.lua`, `src/server/services/SpawnService.lua`                     | Quest intro playable, tetapi reward masih langsung auto-complete dan ada TODO generalisasi starter item. |
| School lesson + quiz                                | Selesai (MVP)       | `src/server/services/SchoolService.lua`, `src/client/controllers/SchoolController.lua`                                                         | 5 lesson quiz berjalan; belum ada hasil quiz detail di UI setelah submit.                                |
| HUD + profile fetch + quest log                     | Selesai (MVP)       | `src/client/controllers/HUDController.lua`, `src/client/controllers/ProfileController.lua`                                                     | Sudah tampilkan Yen/XP/level/quest.                                                                      |
| Lakeside map generation                             | Selesai (map pass)  | `src/server/services/TerrainService.lua`, `src/server/services/LakesideParkService.lua`, `src/server/services/TownRoadService.lua`             | Fokus map-first berjalan, perlu regression pass rutin.                                                   |
| Bicycle rideable                                    | Selesai (MVP)       | `src/server/services/BicycleService.lua`                                                                                                       | Kontrol arcade server-side aktif.                                                                        |
| Boat rideable                                       | Selesai (MVP)       | `src/server/services/LakeActivityService.lua`                                                                                                  | Collision/shore guard ada, masih butuh balancing handling.                                               |
| Fishing + shop + inventory bag                      | Selesai (MVP+)      | `src/server/services/FishingGameService.lua`, `src/client/controllers/FishingController.lua`, `src/client/controllers/InventoryController.lua` | Loop cast/wait/bite/reel + belanja + equip item/fish berjalan.                                           |
| Fireworks festival                                  | Selesai (MVP)       | `src/server/services/FireworksFestivalService.lua`                                                                                             | Console event berjalan 10 menit/1 jam pada tanggal khusus.                                               |
| Wildlife ambience                                   | Selesai (pass awal) | `src/server/services/WorldWildlifeService.lua`                                                                                                 | Visual fauna ada untuk ambience.                                                                         |
| Time/day/season/weather gameplay                    | Prototype           | `src/server/services/TimeService.lua`                                                                                                          | Masih skeleton tick; belum dipakai mengendalikan sistem lain.                                            |
| Anti-exploit lanjutan (positional, area validation) | Parsial             | `src/server/services/RemoteRegistryService.lua`                                                                                                | Rate limit sudah ada, tapi validasi domain-specific belum menyeluruh.                                    |
| Arubaito loop non-fishing                           | Belum mulai         | tidak ada service aktif spesifik                                                                                                               | Masih di PRD/GDD, belum ada implementasi runtime.                                                        |
| Hiking loop                                         | Belum mulai         | tidak ada service aktif spesifik                                                                                                               | Masih backlog.                                                                                           |
| Multi-language runtime                              | Ditunda             | `src/shared/constants/Config.lua`, `src/shared/services/LocalizationService.lua`                                                               | Runtime masih English-only (`availableLocales = { 'en' }`).                                              |

## Status test

| Layer                          | Status           | Bukti                                                                                              |
| ------------------------------ | ---------------- | -------------------------------------------------------------------------------------------------- |
| Unit test logic util           | Ada              | `tests/specs/Math.spec.lua`, `tests/specs/QuestLogic.spec.lua`, `tests/specs/LessonLogic.spec.lua` |
| Integrasi service server       | Belum sistematis | Belum ada suite integrasi service-level                                                            |
| Manual playtest gate per fitur | Belum disiplin   | Checklist ada, tapi belum jadi gate wajib sebelum lanjut fitur berikutnya                          |

## Gap utama yang harus ditutup sebelum fitur baru

1. Gate manual test per fitur harus wajib lulus sebelum pindah fitur.
2. TimeService perlu diputuskan: dipakai nyata atau dibekukan sementara.
3. Validasi anti-exploit berbasis konteks fitur (lokasi interaksi, state machine) perlu ditambah.
4. Hasil quiz/quest feedback di UI perlu lebih eksplisit agar QA manual mudah verifikasi.
