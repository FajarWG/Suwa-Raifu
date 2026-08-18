# IMPLEMENTATION FLOW

## Suwa Life: Nihongo Days

Flow ini dibuat agar tim menyelesaikan fitur **satu per satu** sampai playable aman, baru lanjut ke fitur berikutnya.

---

## Aturan eksekusi utama

1. Hanya boleh ada **1 fitur aktif** pada satu waktu.
2. Fitur dianggap selesai hanya jika semua gate di bagian "Definition of Done" lolos.
3. Tidak mulai fitur baru jika masih ada bug `High` atau `Critical` pada fitur aktif.
4. Semua perubahan fitur aktif wajib melalui playtest manual manusia.

## Definition of Done (wajib)

Sebuah fitur boleh ditandai selesai hanya jika:

1. Build place sukses (`rojo build default.project.json --output SuwaLife.rbxlx`).
2. Tidak ada error berulang di Output Studio selama 10 menit playtest.
3. Alur utama fitur bisa dijalankan minimal 3 kali berturut-turut tanpa gagal.
4. Data penting fitur tersimpan benar (jika menyentuh profile/economy/inventory).
5. Checklist QA fitur ditandatangani manual (pass/fail + catatan bug).

## Urutan implementasi aktif (wajib berurutan)

### Fase 0: Stabilitas fondasi vertical slice

**Tujuan:** menjaga spawn, profile, remote, HUD, dan map boot tetap stabil.  
**Ruang lingkup:** runner, RemoteRegistry, ProfileService, HUD, map load sequence.

Gate manual:

1. Join game 3x dan profile tidak nil setelah beberapa detik.
2. Spawn konsisten di area benar.
3. HUD menampilkan Yen/XP/Level.
4. Tidak ada error spam remote/require.

### Fase 1: Onboarding sekolah (quest + class)

**Tujuan:** pemain baru bisa menyelesaikan alur pembuka belajar.

Alur lulus:

1. Interaksi Teacher Sakura.
2. Accept quest intro.
3. Quest progression terselesaikan.
4. Buka panel school.
5. Submit quiz dan dapat XP.

Gate manual:

1. Alur di atas berhasil 3x pada karakter baru.
2. Quest log UI sinkron sesudah accept/complete.
3. Tidak bisa double-complete quest yang sama.

### Fase 2: Mobilitas lakeside (sepeda + perahu)

**Tujuan:** traversal utama map stabil untuk eksplorasi sosial.

Gate manual:

1. Sepeda bisa dinaiki, belok, berhenti, turun tanpa softlock.
2. Perahu tidak menembus shoreline/pulau saat dikendarai normal.
3. Pemain tidak terjebak collision pada dock/launch area.

### Fase 3: Loop fishing economy

**Tujuan:** pemain punya aktivitas repeatable yang menghasilkan progres.

Alur lulus:

1. Cast di spot valid.
2. Timing reel bekerja (berhasil/gagal).
3. Hasil masuk bag.
4. Item shop bisa dibeli dengan Yen.
5. Inventory action (take out) bekerja.

Gate manual:

1. 10 percobaan fishing: state machine stabil.
2. Yen berkurang saat belanja, item bertambah sesuai pembelian.
3. Tidak ada duplikasi item dari spam input.

### Fase 4: Festival event aman

**Tujuan:** event kembang api aktif tanpa merusak gameplay lain.

Gate manual:

1. Console memulai event dan selesai otomatis.
2. Tidak ada damage gameplay/physics yang memblokir pemain.
3. FPS dan audio tetap playable saat event aktif.

## Backlog yang dibekukan (jangan dikerjakan dulu)

1. Arubaito non-fishing.
2. Hiking system.
3. Multi-language runtime (`ja`, `id`).
4. Ekspansi map besar di luar distrik aktif.

Backlog hanya boleh dibuka setelah Fase 0 sampai Fase 4 lulus penuh.

## Workflow kerja harian

1. Pilih satu fase aktif.
2. Buat branch fokus: `feature/<fase>-<tujuan-singkat>`.
3. Implementasi kecil bertahap (maks 1 behavior per commit).
4. Jalankan lint/format/unit test yang relevan.
5. Playtest manual manusia pakai checklist fase.
6. Jika gagal gate: perbaiki di fase yang sama, dilarang loncat fase.

## Command kerja standar

```sh
rokit install
rojo build default.project.json --output SuwaLife.rbxlx
rojo serve default.project.json
selene src
stylua --check src
rojo build tests.project.json --output build/SuwaLife-Test.rbxlx
```
