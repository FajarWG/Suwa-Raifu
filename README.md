# README

## Suwa Life: Nihongo Days (諏訪ライフ ～日本語学校の日々～)

Social life simulation Roblox: kehidupan siswa asing di Suwa, Nagano — belajar bahasa Jepang, arubaito, memancing, hiking, festival.

> Dokumentasi lengkap produk: **PRD.md** (root). Detail desain: **docs/**.

> Dokumen eksekusi aktif (wajib dibaca sebelum implementasi):
>
> - `docs/IMPLEMENTATION_FLOW.md`
> - `docs/IMPLEMENTATION_STATUS.md`

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

### Map Visual Pass 0.9 — Grounding, Wildlife, and Festival Polish

- Spawn berada di sculpture plaza yang terinspirasi Sekicho Park di dalam kawasan
  Suwa Lakeside Park.
- Urutan ruang utama: taman tepi danau → asrama generik → sekolah bahasa fiktif.
- Open-zone berisi danau Terrain Water yang luas, dual track lakeside, sungai/kanal, jalan utama, jembatan,
  permukiman, pepohonan, dan backdrop pegunungan.
- Air danau merupakan volume Terrain Water yang dapat direnangi, bukan part datar.
  Tiga belas shelf/teluk dangkal membentuk tepian melengkung; tiga genangan hujan kecil
  menambah variasi permukaan basah pada kantong rumput tanpa memotong trek utama.
- Koridor tepi danau mengikuti foto `assets/*.jpg`: trek jogging tartan marun di sisi air,
  jalur aspal sepeda/jalan bermarka putih, bangku menghadap Suwako, serta shoreline
  pasir/kerikil/rumput tanpa dinding beton kaku.
- Trek utama membentang sekitar 1.340 stud dalam rangkaian lengkung dan beda elevasi;
  cabang ramp, loop taman, serta lawn bertingkat memecah bentuk koridor lurus dan datar.
- Sepuluh dedalu dengan foliage menjuntai, shelter beratap Jepang, ashiyu berair biru, dermaga
  perahu bebek, lampu minimalis, dan papan kayu membentuk identitas taman.
- Zona inland mencakup plaza kerikil organik dengan alat fitness, toilet publik, vending
  machine, parkir mamachari beratap, serta display statis lokomotif uap D51 824.
- Model sekolah, asrama, dan sepeda dipisah agar mudah diiterasi lewat Rojo.
- Mamachari dinormalisasi langsung per-MeshPart ke panjang 2,35 stud dan rideable
  dengan kontrol W/S/A/D; parkir beratap menyediakan delapan unit aktif, collider padat,
  serta kursi bonceng.
- Area danau memiliki panggung open mic dan dua booth percakapan; proximity voice
  memakai sistem resmi Roblox untuk pemain yang memenuhi syarat.
- Lakeside park memiliki dual track, tiga dermaga/sembilan marker memancing,
  playground, rest shelter, dan ashiyu.
- Pulau Hatsushima-inspired diperbesar menjadi footprint organik sekitar 180 stud dan
  berkapasitas desain 20 pemain. Fondasi batu berada di bawah air; permukaan pulau
  memiliki pantai pasir menyatu, lawn festival terbuka,
  shrine, torii, enam pohon perimeter, jetty, toko festival, serta 12 launch point.
- Konsol festival menjalankan pertunjukan kembang api aman selama 10 menit; pada
  15 Agustus waktu Jepang durasinya otomatis menjadi 1 jam. Shell kecil dan besar
  memiliki tinggi, burst, cadence, serta positional launch/burst sound berbeda.
- Mamachari dinormalisasi ke panjang 2,35 stud berdasarkan sumbu horizontal sebenarnya;
  delapan sepeda taman ditempatkan pada slot terpisah di rak beratap. Bangku, vending
  machine, papan, alat fitness, dan D51 juga diaudit
  ulang terhadap tinggi avatar sekitar 5,5 stud.
- Dua duck pedal boat (6,2 stud) dan satu leisure boat (8,5 stud) tersedia dan dapat
  dikendalikan; lambung dan lantai cockpit berada di atas waterline sehingga interior
  tidak kemasukan air. Pemeriksaan haluan/sisi mencegah perahu menembus pulau dan
  shoreline. Setiap perahu memiliki dek padat yang dapat diinjak, kursi penumpang,
  dan suara gerak air. Air di luar kendaraan tetap dapat direnangi.
- Ashiyu memiliki basin batu cekung sedalam 4 stud, Terrain Water dan permukaan biru
  yang terlihat, tangga masuk, uap, serta tempat duduk fungsional;
  plaza kerikil dipindahkan dari playground agar ayunan tidak tertanam di pasir.
- Terrain memiliki pad fasilitas lokal yang rata tanpa menghilangkan kontur taman.
  Trek, bangku, lampu, pohon, toko, dan bangunan pulau memakai terrain raycast agar
  menyentuh tanah dan tidak melayang pada tanjakan/turunan.
- Danau memiliki 18 ikan visual yang berenang di sekitar tiga dermaga dan pulau,
  enam bebek yang mengapung, serta dua burung kuntul di pulau.
- Bangku, ashiyu, ayunan, jungkat-jungkit, dan slide dapat digunakan. Sepeda mengikuti
  permukaan melalui raycast dan berhenti pada lereng yang terlalu curam agar tidak menembus tanah.
- Tiga dermaga/sembilan titik memancing memakai state casting–waiting–bite–reeling,
  weighted catch, model ikan, modal hasil, level memancing, dan penyimpanan ke tas.
- Tas pemain, toko alat pancing, toko es krim, dan toko festival pulau sudah interaktif;
  item dapat dibeli, disimpan, dikeluarkan, dan consumable dapat digunakan.
- Fase map aktif dibatasi satu distrik lakeside/Kami-Suwa-inspired dengan grid jalan
  lokal, trotoar, jembatan kanal/sungai, 12 rumah 1–2 lantai, ryokan empat lantai, tiga
  toko, tiang/kabel listrik, drain grate, cermin tikungan, vending machine, lampu, dan crosswalk.
- Generator kota menghapus model skyline metropolitan/skyscraper yang tidak kompatibel;
  bangunan tinggi tidak menjadi bagian dari bahasa visual map.
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
rojo build tests.project.json --output build/SuwaLife-Test.rbxlx
# Jalankan TestEZ di Roblox Studio pada place test (tests.project.json)
```

## Git

- Branch `main` = kondisi terverifikasi (lolos playtest).
- Fitur baru → branch `feature/<nama>` → playtest → merge.
- Commit message bahasa deskriptif.

## Dokumen terkait

| Dokumen                         | Isi                                                     |
| ------------------------------- | ------------------------------------------------------- |
| `PRD.md`                        | Konsep produk, scope, roadmap                           |
| `docs/IMPLEMENTATION_FLOW.md`   | Urutan implementasi satu fitur per fase + gate manual   |
| `docs/IMPLEMENTATION_STATUS.md` | Status aktual fitur berdasarkan audit kode              |
| `docs/GDD.md`                   | Aturan gameplay & progression                           |
| `docs/TDD.md`                   | Arsitektur teknis, service, remote                      |
| `docs/style-guide.md`           | Art style, palet, skala                                 |
| `docs/data-schema.md`           | Struktur data pemain & defs                             |
| `docs/asset-list.md`            | Daftar aset & status                                    |
| `docs/map-layout.md`            | Layout map, skala, urutan perjalanan, dan batas privasi |
| `docs/localization.md`          | Sistem bahasa                                           |
| `docs/qa-plan.md`               | Rencana testing                                         |
