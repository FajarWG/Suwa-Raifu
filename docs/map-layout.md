# SUWA CENTRAL — MAP LAYOUT

## Suwa Life: Nihongo Days

**Versi:** Lakeside visual pass 0.9
**Status:** Photo-led Suwa Lakeside Park environment dan aktivitas interaktif

---

## 1. Arah desain

Map mengambil karakter visual langsung dari foto lapangan `assets/*.jpg`: taman rumput
terbuka, trek tartan marun, jalur aspal bermarka putih, dedalu di shoreline alami,
dermaga kayu, jalan kota kecil, dan pegunungan hijau di seberang Suwako. Susunan lokasi
tetap memadatkan jarak untuk gameplay dan tidak menyalin denah tempat tinggal privat.

Tujuannya:

- menjaga privasi lokasi tempat tinggal;
- menghindari penyalinan identitas NICC sebelum ada izin tertulis;
- membuat perjalanan taman–asrama–sekolah nyaman untuk gameplay;
- menyediakan koridor sepeda dan ruang ekspansi fitur berikutnya.

### Batas fase lakeside town

Fase map aktif mencakup satu distrik lakeside/Kami-Suwa-inspired yang lebar: taman spawn,
promenade melengkung, lawn bertingkat, area D51, fasilitas publik, Route 50 versi fiktif,
kanal/sungai, grid jalan lokal, blok perumahan, asrama sementara, sekolah sementara, dan
venue sosial. Skala taman sengaja diperluas agar tidak terbaca sebagai satu kotak kecil,
namun rute panjang menuju lokasi privat tetap tidak direplikasi.

## 2. Layout top-down

```text
                               UTARA
┌─────────────────────────────────────────────────────────────────────┐
│  DANAU SUWAKO — PULAU FESTIVAL 20 PEMAIN + TOKO + KEMBANG API     │
├╮ shoreline alami ╭── trek merah bergelombang ──╮ dedalu ─────────┤
│╰── D51 + loop ───╯── jalur aspal melengkung ───╯── dermaga ─────│
│ plaza fitness   lawn bertingkat   ashiyu/rest   sculpture lawn   │
│ OPEN MIC + booth (inland)              toilet + parkir sepeda     │
│  ───────────────────── Route 50 ───────────═────────────────────     │
│                                            ║ sungai                 │
│     SEKOLAH FIKTIF                         ║       ASRAMA           │
│     + halaman                              ║       + parkir          │
│     + parkir sepeda                        ║       + sepeda          │
│                                            ║                        │
│  ───────────────────── kanal selatan ───────────────────────────     │
│                                                                     │
│                    PEGUNUNGAN / HILLS BACKDROP                     │
└─────────────────────────────────────────────────────────────────────┘
                               SELATAN
```

Urutan perjalanan awal: **Suwa Lakeside Park / Sekicho-inspired spawn → asrama →
sekolah bahasa fiktif**.

## 3. Skala gameplay

| Elemen | Ukuran/posisi prototype | Tujuan |
|---|---:|---|
| Batas terrain aktif | ±1500 × 500 stud | Distrik taman dan kota kecil yang lebar |
| Sekolah → asrama | ±445 stud | Jalan kaki singkat / cocok untuk sepeda |
| Jalan utama | 540 × 22 stud | Koridor perjalanan utama |
| Trek tartan merah | ±1340 × 9 stud | Jalur jogging terluar, melengkung dan naik-turun dekat air |
| Jalur aspal sepeda/jalan | ±1340 × 13 stud | Koridor mamachari/pejalan kaki melengkung dan bermarka putih |
| Shoreline alami | ±1400 stud | Kantong pasir, pebble, rumput air, dan dedalu tanpa seawall beton |
| Kedalaman zona taman | ±260 stud | Trek, loop, lawn, plaza, fasilitas, dan cabang jalur inland |
| Danau Terrain Water | 1900 × 1140 stud | Volume dalam yang swimmable, boat, dan fishing |
| Shore-water transition | 13 teluk dangkal | Tepian air melengkung tanpa batas blok lurus |
| Genangan hujan | 3 area dangkal | Detail atmosfer di kantong rumput, tidak menghalangi trek |
| Pulau festival | pusat (0, -610), footprint ±180 stud | Kapasitas desain 20 pemain; pasir, lawn, shrine, torii, pohon, jetty, toko, dan 12 launch point |
| Mamachari | panjang target 4 stud | Skala compact sesuai hasil playtest avatar; satu unit parkir di rak taman |
| Duck pedal boat | panjang target 6,2 stud | Pedal boat proporsional terhadap avatar; cockpit di atas waterline |
| Leisure boat | panjang target 8,5 stud | Perahu rekreasi kecil proporsional terhadap avatar |
| D51 824 | panjang visual ±59 stud | Display lokomotif sesuai skala avatar, bukan miniatur |
| Waterline kendaraan | dasar Y 1,15 | Mencegah Terrain Water tampak di cockpit |

Skala mengikuti prinsip PRD §8: bentuk landmark tetap mudah dikenali, tetapi jarak
antarlokasi dipadatkan. Angka ini dapat dituning setelah playtest pergerakan karakter.

## 4. File model

| File | Isi |
|---|---|
| `maps/SuwaCentral.model.json` | Tanah, spawn park, jalan, sungai, kanal, jembatan, dan lawn dasar |
| `maps/LanguageAcademy.model.json` | Sekolah bahasa fiktif dua lantai, halaman, jalur masuk, rak sepeda |
| `maps/Dormitory.model.json` | Asrama generik dua lantai, balkon, tangga luar, dan parkir |
| `maps/Bicycles.model.json` | Tiga mesh sumber mamachari; BicycleService membuat delapan unit rideable di parkir taman |
| `maps/LakeCrafts.model.json` | Dua duck pedal boat mesh dan satu leisure boat mesh |
| `maps/LakesideOpenMic.model.json` | Panggung open mic, bangku penonton, booth percakapan, dan papan Jepang |
| `maps/LakesideActivities.model.json` | Tiga dermaga, sembilan marker memancing, playground, footbath, dan food stall |
| `src/server/services/LakesideParkService.lua` | Dual track melengkung, shoreline, lawn bertingkat, plaza fitness, D51 824, toilet, parkir sepeda, shelter, dock, lampu, papan, dan golden hour |
| `src/server/services/TownRoadService.lua` | Rumah rendah, ryokan empat lantai, tiang/kabel listrik, drain grate, cermin tikungan, dan vending machine |
| `src/server/services/FireworksFestivalService.lua` | Pertunjukan aman 10 menit dan mode 1 jam pada 15 Agustus JST |
| `src/server/services/FishingGameService.lua` | Toko, tas, state memancing, algoritma hasil, dan visual tangkapan |
| `src/server/services/ParkInteractionService.lua` | Tempat duduk, ayunan, jungkat-jungkit, dan slide fungsional |
| `src/server/services/WorldWildlifeService.lua` | Ikan visual, bebek, dan burung pulau dengan gerak ringan |

Visual kendaraan tetap `Anchored`, tetapi `BicycleService` dan `LakeActivityService`
menggerakkan model dengan kontrol arcade server-side. Panggung dan booth mendukung proximity voice Roblox secara spasial;
tidak ada sistem audio custom atau voice tanpa filter. Bangunan belum memiliki interior
agar iterasi bentuk kota lebih cepat.

`VoiceChatService.EnableDefaultVoice` sudah aktif pada place build. Pemilik Experience
tetap harus mengaktifkan **Enable Microphone** melalui Experience Settings dan publish;
voice hanya tersedia untuk akun yang memenuhi syarat Roblox.

## 5. Referensi geografis yang dipakai

- Titik awal mengambil inspirasi dari Sekicho Park yang berada di dalam kawasan Suwa
  Lakeside Park: ruang hijau terbuka, sculpture, promenade, dan pemandangan danau.
- Dari taman, rute game bergerak ke asrama di sisi timur lalu ke sekolah di sisi barat.
- Koridor nyata sekolah–asrama sekitar 1,6–1,7 km melalui jalan prefektur dan sebuah
  jembatan; di dalam game koridor tersebut dipadatkan menjadi sekitar 445 stud.
- Nama publik di game tetap **Nagano International Language Academy** sampai ada izin.

Jangan menambahkan nomor kamar, denah interior nyata, papan nama asli, logo, atau wajah
orang nyata ke model publik.

## 6. Urutan iterasi map berikutnya

1. Playtest seluruh lengkung trek, tanjakan, turunan, cabang jalur, dan lawn dengan avatar serta mamachari.
2. Verifikasi clearance bangku, dedalu, D51, dermaga, toilet, parkir sepeda, dan panggung inland.
3. Ganti foliage primitive dengan mesh LOD dedalu yang tetap mempertahankan siluet foto.
4. Tambahkan interior publik sekolah yang fiktif; jangan membuat interior asrama nyata.
5. Tambahkan supermarket dan convenience store fiktif.
6. Setelah distrik lakeside disetujui, susun koridor ekspansi ke ryou lalu NICC.

### Status aktivitas map

- Berjalan kaki: siap untuk playtest greybox.
- Jalur sepeda: tersambung di promenade; tiga mamachari dapat dinaiki dengan W/S/A/D.
- Memancing: casting, waktu tunggu acak, bite window, reeling, weighted catch, bentuk ikan,
  modal hasil, level, dan penyimpanan ikan/barang ke tas aktif.
- Air: volume danau memakai Terrain Water yang dapat direnangi; 13 teluk dangkal
  menyambungkan danau ke shoreline, dengan tiga genangan hujan dekoratif di rumput.
- Kendaraan air: dua duck pedal boat dan satu leisure boat dapat dinaiki/dikendalikan.
- Playground: slide, dua ayunan, dan jungkat-jungkit fungsional; plaza kerikil tidak lagi
  menumpuk di bawah area bermain.
- Lakeside extras: toko pancing, toko es krim, ashiyu air biru dengan seating, toilet,
  parkir sepeda, dan toko festival pulau.
- Pulau: footprint ±180 stud untuk 20 pemain, pantai pasir, lawn, pohon, shrine, jetty,
  12 launch point, fauna, dan konsol kembang api kecil/besar bersuara selama 10 menit
  atau 1 jam pada 15 Agustus JST.
- Open mic: venue dan proximity voice tersedia; mikrofon tidak menyiarkan ke seluruh map.

## 7. Bahasa prototype

- UI, dialog, tombol, tutorial, dan pesan sistem: **English only**.
- Papan lokasi di dunia: **bahasa Jepang**.
- Resource Indonesia/Jepang lama disimpan tetapi dinonaktifkan sampai phase localization.
- Papan yang digunakan sekarang: `諏訪湖畔公園`, `オープンマイク`,
  `すわ学生寮`, dan `すわ国際日本語学院`.
