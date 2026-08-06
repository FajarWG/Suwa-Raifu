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

### 4. Voice chat

Build mengaktifkan default proximity voice pada `VoiceChatService`. Agar berfungsi pada
Experience yang dipublish, buka **File → Experience Settings → Communication**, aktifkan
**Enable Microphone**, lalu publish. Fitur hanya tersedia untuk pemain yang memenuhi
syarat Roblox; mikrofon panggung tidak membuat jalur audio custom.

## Fitur

### Fitur 1 — Interaksi NPC & Starter Quest

- NPC Teacher Sakura di-spawn server-side dengan ProximityPrompt.
- Pemain mendekat → prompt → dialog branching. UI prototype memakai English.
- Quest intro: bicara dengan guru → terima quest → dapat buku pelajaran → reward Japanese XP + Yen.
- HUD menampilkan Yen, Japanese XP, level, dan quest aktif.
- Data tersimpan ke DataStore (profile dengan versioning & retry).

### Fitur 2 — Kelas & Quiz Bahasa Jepang

- Tombol "School" di HUD membuka panel daftar 5 lesson (id/en/ja).
- Klik lesson → quiz pilihan ganda (vocab Jepang).
- Server menilai jawaban (60% lulus), beri Japanese XP + attendance.
- Lesson yang selesai ditandai di daftar; progress tersimpan.
- Logika grading di shared `LessonLogic` (testable) + unit test.

### Map Greybox 0.3 — Compact Suwa Lakeside

- Spawn berada di sculpture plaza yang terinspirasi Sekicho Park di dalam kawasan
  Suwa Lakeside Park.
- Urutan ruang utama: taman tepi danau → asrama generik → sekolah bahasa fiktif.
- Compact world berisi danau Terrain Water yang luas, promenade, sungai/kanal, jalan utama, jembatan,
  permukiman, pepohonan, dan backdrop pegunungan.
- Model sekolah, asrama, dan sepeda dipisah agar mudah diiterasi lewat Rojo.
- Tiga mamachari dinormalisasi terhadap ukuran avatar (5 studs panjang) dan rideable
  dengan kontrol W/S/A/D.
- Area danau memiliki panggung open mic dan dua booth percakapan; proximity voice
  memakai sistem resmi Roblox untuk pemain yang memenuhi syarat.
- Promenade memiliki jalur sepeda, jalur jalan kaki, tiga dermaga/sembilan marker
  memancing, playground, dan rest shelter.
- Pulau Hatsushima-inspired memiliki pohon, torii, jetty, dan launch point kembang api.
- Dua duck pedal boat (6,5 studs) dan satu leisure boat (6 studs) tersedia dan dapat
  dikendalikan; lambung dan lantai cockpit berada di atas waterline sehingga interior
  tidak kemasukan air. Air di luar kendaraan tetap dapat direnangi.
- Food stall dan footbath-inspired seating tetap tersedia sebagai greybox.
- Sembilan titik dermaga mempunyai interaksi memancing prototype.
- Fase map aktif dibatasi satu kotak compact lakeside/Kami-Suwa-inspired dengan grid jalan
  lokal, trotoar, jembatan kanal/sungai, 12 rumah, tiga toko, lampu, dan crosswalk.
- Koridor panjang menuju NICC dan ryou ditunda ke fase map berikutnya.
- Papan dunia memakai bahasa Jepang, sementara UI/dialog prototype memakai English.
- Detail layout: `docs/map-layout.md`.

## Struktur

```
src/
├── shared/    # types, constants, data defs, remotes, util, localization, services
├── server/    # services (Profile, Economy, Quest, NPC, Spawn), runner.server.lua
└── client/    # controllers (Remote, Profile, Dialog, HUD), runner.client.lua
maps/
├── SuwaCentral.model.json         # environment kota, danau, jalan, sungai
├── LanguageAcademy.model.json     # sekolah bahasa fiktif
├── Dormitory.model.json           # asrama generik
├── Bicycles.model.json            # mesh mamachari rideable
├── LakeCrafts.model.json          # duck pedal boat + leisure boat mesh
├── LakesideOpenMic.model.json     # panggung dan booth percakapan
└── LakesideActivities.model.json  # trail, dermaga, playground, rest area
docs/          # GDD, TDD, map layout, style guide, data schema, asset list, QA
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
| `docs/map-layout.md` | Layout map, skala, urutan perjalanan, dan batas privasi |
| `docs/localization.md` | Sistem bahasa |
| `docs/qa-plan.md` | Rencana testing |
