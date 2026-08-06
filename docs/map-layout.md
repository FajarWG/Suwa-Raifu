# SUWA CENTRAL — MAP LAYOUT

## Suwa Life: Nihongo Days

**Versi:** Greybox 0.3  
**Status:** Map-first blockout, basic traversal interaktif

---

## 1. Arah desain

Map mengambil karakter umum kawasan Suwa: taman di tepi danau, dataran kota,
kanal/sungai, jembatan, jalan lokal, dan pegunungan di kejauhan. Susunan lokasi
terinspirasi hubungan geografis kawasan nyata, tetapi nama, bentuk bangunan, dan jarak
sengaja dibuat fiktif.

Tujuannya:

- menjaga privasi lokasi tempat tinggal;
- menghindari penyalinan identitas NICC sebelum ada izin tertulis;
- membuat perjalanan taman–asrama–sekolah nyaman untuk gameplay;
- menyediakan koridor sepeda dan ruang ekspansi fitur berikutnya.

### Batas fase compact town

Fase map aktif hanya mencakup satu kotak lakeside/Kami-Suwa-inspired: taman spawn,
promenade, Route 50 versi fiktif, kanal/sungai, grid jalan lokal, blok perumahan, asrama
sementara, sekolah sementara, dan venue sosial. Rute panjang ke NICC serta ryou tidak
dibangun pada fase ini dan tidak boleh membuat ukuran kotak aktif melebar.

## 2. Layout top-down

```text
                               UTARA
┌─────────────────────────────────────────────────────────────────────┐
│        DANAU SUWAKO LUAS — HATSUSHIMA-INSPIRED ISLET               │
├────────────────────── PROMENADE / TAMAN TEPI DANAU ────────────────┤
│ playground  OPEN MIC + booth     rest area  SPAWN / SCULPTURE PARK│
│  dermaga       dermaga                       dermaga                │
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
| Batas tanah | 760 × 520 stud | Compact open-zone |
| Sekolah → asrama | ±445 stud | Jalan kaki singkat / cocok untuk sepeda |
| Jalan utama | 540 × 22 stud | Koridor perjalanan utama |
| Promenade | 760 × 34 stud | Eksplorasi tepi danau |
| Danau Terrain Water | 1900 × 1200 stud | Landmark luas, berenang, boat, fishing |
| Pulau kecil | pusat sekitar (0, -610) | Torii, pohon, jetty, launch point kembang api |
| Mamachari | 5 × 3,3 studs | Proporsional terhadap avatar ±5,5 studs |
| Duck pedal boat | panjang 6,5 studs | Kendaraan air satu pemain |
| Leisure boat | panjang 6 studs | Kendaraan air compact satu pemain |
| Waterline kendaraan | dasar Y 0,75; floor Y 1,4 | Mencegah Terrain Water tampak di cockpit |

Skala mengikuti prinsip PRD §8: bentuk landmark tetap mudah dikenali, tetapi jarak
antarlokasi dipadatkan. Angka ini dapat dituning setelah playtest pergerakan karakter.

## 4. File model

| File | Isi |
|---|---|
| `maps/SuwaCentral.model.json` | Tanah, danau, spawn park, promenade, jalan, sungai, kanal, jembatan, permukiman, pohon, bukit |
| `maps/LanguageAcademy.model.json` | Sekolah bahasa fiktif dua lantai, halaman, jalur masuk, rak sepeda |
| `maps/Dormitory.model.json` | Asrama generik dua lantai, balkon, tangga luar, dan parkir |
| `maps/Bicycles.model.json` | Tiga mesh mamachari di taman, asrama, dan sekolah |
| `maps/LakeCrafts.model.json` | Dua duck pedal boat mesh dan satu leisure boat mesh |
| `maps/LakesideOpenMic.model.json` | Panggung open mic, bangku penonton, booth percakapan, dan papan Jepang |
| `maps/LakesideActivities.model.json` | Jalur sepeda/jalan kaki, tiga dermaga, sembilan marker memancing, playground, rest area, footbath, food stall |

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

1. Verifikasi komposisi dan collision di Roblox Studio.
2. Tambahkan jalan lingkungan, trotoar, guardrail, lampu, dan marka yang lebih rapi.
3. Bentuk shoreline dan terrain pegunungan dengan Terrain Editor.
4. Tambahkan interior publik sekolah yang fiktif; jangan membuat interior asrama nyata.
5. Tambahkan supermarket dan convenience store fiktif.
6. Setelah map compact disetujui, susun koridor ekspansi ke ryou lalu NICC.

### Status aktivitas map

- Berjalan kaki: siap untuk playtest greybox.
- Jalur sepeda: tersambung di promenade; tiga mamachari dapat dinaiki dengan W/S/A/D.
- Memancing: tiga dermaga dan sembilan prompt `Fish` aktif; hasil masih prototype sederhana.
- Air: Terrain Water dapat direnangi; playtest mengembalikan state humanoid `Swimming`.
- Kendaraan air: dua duck pedal boat dan satu leisure boat dapat dinaiki/dikendalikan.
- Playground: slide, dua ayunan, dan jungkat-jungkit masih prop statis.
- Lakeside extras: food stall dan footbath-inspired seating; launch point kembang api
  dipindahkan ke pulau Hatsushima-inspired.
- Open mic: venue dan proximity voice tersedia; mikrofon tidak menyiarkan ke seluruh map.

## 7. Bahasa prototype

- UI, dialog, tombol, tutorial, dan pesan sistem: **English only**.
- Papan lokasi di dunia: **bahasa Jepang**.
- Resource Indonesia/Jepang lama disimpan tetapi dinonaktifkan sampai phase localization.
- Papan yang digunakan sekarang: `諏訪湖畔公園`, `オープンマイク`,
  `すわ学生寮`, dan `すわ国際日本語学院`.
