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

### Perubahan working tree setelah handoff awal

- Prioritas pengembangan diubah menjadi **map-first**; arubaito dan fitur interaktif baru ditunda.
- Blockout kamar kecil diganti compact outdoor world bertema Suwa.
- Spawn dipindah ke plaza tepi danau yang terinspirasi Sekicho Park di dalam kawasan
  Suwa Lakeside Park.
- Ditambahkan danau, promenade, sungai/kanal, jalan utama versi fiktif, jembatan,
  taman, permukiman, pepohonan, dan backdrop pegunungan.
- Sekolah bahasa fiktif, asrama generik, dan tiga sepeda mamachari dibuat sebagai model terpisah.
- Area danau memiliki panggung open mic, tempat duduk, dan dua booth percakapan.
- Ditambahkan bike lane, walking lane, tiga dermaga, sembilan marker memancing,
  playground, rest shelter, dan sepeda ketiga di dekat spawn.
- Food stall dan footbath-inspired area sudah berupa greybox; launch point kembang api
  kemudian dipindahkan dari barge ke pulau kecil.
- Pass visual kedua memperbaiki komposisi yang gagal di build awal: pohon besar tidak lagi
  menutup spawn, pemain menghadap danau, shoreline memakai segmen pasir/batu, backdrop
  dipindah ke seberang danau, dan opening camera menampilkan overview tiga-perempat.
- Audit melalui Roblox Studio MCP menemukan akar kerusakan build: properti `Position`
  tidak diserialisasi oleh Rojo sehingga 288 instance menumpuk di `(0, 0, 0)`. Semua map
  JSON sekarang memakai `CFrame` dan tervalidasi lewat Studio.
- Danau, shoreline, dan pegunungan Part telah diganti oleh TerrainService (terrain water,
  pasir, bukit rock/grass). Tiga sepeda primitive diganti mesh mamachari hasil Studio.
- Build terbaru untuk pemeriksaan adalah `build/SuwaLife-WaterproofBoats-v8.rbxlx`; tekan Play
  agar layanan terrain, kota, sepeda, dan aktivitas danau aktif.
- Scope map fase ini dikunci satu kotak compact lakeside/Kami-Suwa-inspired. TownRoadService
  menambahkan grid jalan lokal, trotoar, kanal/river bridges, 12 rumah beratap, tiga toko,
  lampu, dan crosswalk. Koridor ke NICC dan ryou sengaja ditunda ke fase berikutnya.
- UI/dialog dikunci English-only; papan environment memakai bahasa Jepang.
- Suwako sekarang berupa Terrain Water luas (1900 × 1200 studs), bukan strip Part. Karakter
  tervalidasi masuk state `Swimming`; tidak ada `LakeWater` Part yang menjadi lantai keras.
- Pulau kecil Hatsushima-inspired ditambahkan di tengah danau dengan pohon, torii, jetty,
  dan tiga titik peluncur kembang api. Barge lama di tepi danau dihapus.
- Tiga mamachari dinormalisasi terhadap avatar (5 studs panjang, sekitar 3,3 studs tinggi)
  dan sekarang rideable dengan prompt
  `Ride bicycle` serta kontrol W/S/A/D. Dua duck pedal boat mesh dan satu leisure boat mesh
  juga dapat dinaiki/dikendarai; panjangnya dinormalisasi menjadi 6,5 dan 6 studs.
- Lambung kendaraan air dinaikkan ke waterline `Y = 0,75` dan setiap cockpit memiliki
  lantai solid pada `Y = 1,4`, sehingga Terrain Water tidak terlihat menembus interior.
- Sembilan marker dermaga sekarang mempunyai prompt `Fish` dengan hasil prototype
  Wakasagi/Carp/gagal berupa BillboardGui.
- Bug penting runner diperbaiki: server runner sekarang memuat ModuleScript dari folder
  `src/server/services`, sehingga semua service map benar-benar berjalan saat Play.
- Layout dan aturan privasi ada di `docs/map-layout.md`.

## 2. Alur Gameplay Saat Ini (playable vertical slice)

1. Pemain spawn di sculpture plaza tepi danau (SpawnLocation).
2. Pemain mengikuti koridor taman → asrama → sekolah.
3. Dekati Teacher Sakura (NPC kotak + ProximityPrompt) → dialog → terima quest intro.
4. Quest selesai → dapat buku pelajaran + XP + Yen.
5. Buka tombol "School" di HUD → kerjakan quiz → dapat Japanese XP + attendance.
6. Progress tersimpan ke DataStore saat keluar.

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
│       ├── TerrainService         # Suwako Terrain Water, shoreline, hills, island mound
│       ├── TownRoadService        # grid jalan compact town
│       ├── BicycleService         # skala, seat, dan kontrol mamachari
│       ├── LakeActivityService    # pulau, fishing, duck boat/leisure boat controls
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
├── SuwaCentral.model.json         # environment + spawn park
├── LanguageAcademy.model.json     # sekolah bahasa fiktif
├── Dormitory.model.json           # asrama generik
├── Bicycles.model.json            # tiga mesh mamachari rideable via BicycleService
├── LakeCrafts.model.json          # dua duck pedal boat + satu leisure boat mesh
├── LakesideOpenMic.model.json     # panggung dan booth percakapan
└── LakesideActivities.model.json  # jalur, dermaga, playground, rest area
tests/
├── TestRunner.server.lua          # TestEZ runner (butuh Roblox utk jalan)
└── specs/                         # Math, QuestLogic, LessonLogic spec
```

**Pola kunci:**
- Semua state otoritatif di server; client hanya kirim intent lewat remote.
- Logika murni dipisah ke `shared/util/*` supaya bisa di-unit-test (TestEZ).
- Semua remote terdaftar di `shared/remotes.lua`; server register via `RemoteRegistryService`.
- UI/dialog prototype memakai English. Resource ja/id disimpan tetapi tidak aktif.
- Papan environment memakai bahasa Jepang.

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
- Tambah teks UI/dialog baru = tambahkan key English di `shared/data/localization/en.lua`.
- Jangan aktifkan locale tambahan sebelum phase localization berikutnya.
- Logika bisnis murni → taruh di `shared/util/` + tulis spec di `tests/specs/`.

## 6. Hal yang Perlu Diperhatikan (Known Issues / TODO)

0. **Build v1/v2 DITOLAK; gunakan v8** — visual loop wajib memakai Roblox Studio MCP:
   `screen_capture`, inspeksi data model, dan playtest langsung. Jangan menilai kesiapan map
   hanya dari keberhasilan build Rojo.
1. **DataStore pada file lokal** menghasilkan warning sampai place dipublish; service map
   tetap berhasil dimuat. Uji profile/economy penuh setelah publish atau aktifkan Studio API access.
2. **NPC masih kotak polos** — belum pakai karakter rig/animasi. Cari aset Creator Store atau buat model sederhana.
3. **Posisi NPC hardcoded** di `SpawnService` (depan sekolah). Nanti pakai konfigurasi per map/Place.
4. **ProfileService load async** — `GetProfile` bisa balik `nil` jika dipanggil terlalu cepat setelah join (client pakai task.spawn; masih aman tapi bisa lebih halus).
5. **Item starter quest hardcoded** (`Config.initialQuestId`/`textbookItemId`) — generalisasi nanti (giver memberikan item via def quest).
6. **TimeService masih skeleton** — belum dipakai untuk day/season/weather (memancing, hiking butuh ini).
7. **TestEZ tidak bisa dijalankan headless** tanpa Roblox/Rust. Pastikan test dijalankan di Studio sebelum merge fitur.
8. **Quest claim flow** — saat ini reward langsung saat quest selesai; belum ada UI "Claim" terpisah.
9. **Anti-exploit belum penuh** — rate limit ada di RemoteRegistryService, tapi belum ada validasi posisi/area (check-in kelas, interaksi NPC).
10. **Voice chat perlu setting Experience** — `EnableDefaultVoice` aktif di build, tetapi pemilik harus mengaktifkan Enable Microphone lalu publish. Hanya akun eligible yang dapat memakai voice.

## 7. Roadmap Berikutnya (map-first)

Prioritas saat ini adalah menyelesaikan kualitas ruang sebelum fitur baru:

1. **Review visual build v8 di Studio** — collision, spawn, skala karakter, jarak tempuh.
2. **Polish shoreline Suwako** — bebatuan dangkal, reeds, variasi kontur, dan siluet gunung.
3. **Polish rute compact town** — guardrail, lampu, marka, dan hubungan taman–jalan lokal.
4. **Playtest social venue** — jarak proximity voice, kapasitas bangku, akses booth.
5. **Bangunan kota fiktif** — supermarket dan convenience store sebagai exterior blockout.
6. **Interior sekolah fiktif** — kelas/lobi generik setelah exterior disetujui.
7. **Fase ekspansi berikutnya** — rencanakan koridor dari taman ke ryou lalu NICC; jangan
   memperluas map compact aktif sebelum review v8 selesai.

Arubaito, shopping, serta fishing/boat progression yang lengkap tetap ada di roadmap PRD,
tetapi ditunda sampai fondasi map disetujui. Fishing v6 hanya interaction prototype.

## 8. Cara Melanjutkan

```sh
git clone https://github.com/FajarWG/Suwa-Raifu.git
cd Suwa-Raifu
rokit install                      # install toolchain
rojo build default.project.json --output build/SuwaLife.rbxlx
# buka build/SuwaLife.rbxlx di Roblox Studio, Play
```

Untuk fitur baru: buat branch `feature/<nama>`, ikuti konvensi §5, playtest, merge ke `main`.
