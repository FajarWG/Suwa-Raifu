# GAME DESIGN DOCUMENT

## Suwa Life: Nihongo Days

**Versi:** 0.2 (vertical slice)  
**Status:** Active design

Dokumen ini fokus ke desain gameplay yang **sudah playable** dan urutan fitur aktif.
Rencana jangka panjang tetap berada di `PRD.md` sebagai backlog.

---

## 1. Core loop playable saat ini

1. Spawn di kawasan lakeside.
2. Interaksi NPC guru untuk quest intro.
3. Buka panel school dan kerjakan quiz.
4. Eksplorasi area taman menggunakan jalan kaki, sepeda, atau perahu.
5. Memancing di spot dermaga, dapat hasil, simpan ke bag.
6. Belanja item pada toko lakeside.
7. Ikut event fireworks via console pulau.

## 2. Loop progression aktif

| Progression   | Sumber utama                              | Dampak                                        |
| ------------- | ----------------------------------------- | --------------------------------------------- |
| Japanese XP   | Quest intro + school quiz                 | Kenaikan level bahasa                         |
| Yen           | Reward quest + aktivitas ekonomi lakeside | Belanja item                                  |
| Fishing level | Aktivitas fishing                         | Akses hasil tangkap lebih baik (berat rarity) |
| Attendance    | School check-in                           | Tracking progress belajar                     |

## 3. Aturan desain fase saat ini

1. UI, dialog, dan sistem runtime tetap English-only.
2. Papan lokasi dunia menggunakan bahasa Jepang untuk konteks visual.
3. Fitur baru dilarang masuk sebelum fase aktif lulus QA gate.

## 4. Fase implementasi desain

1. Fase 0: stabilitas fondasi (spawn/profile/hud/map boot).
2. Fase 1: onboarding sekolah (quest + class).
3. Fase 2: mobilitas lakeside (sepeda + perahu).
4. Fase 3: fishing economy loop.
5. Fase 4: festival event.

Urutan detail dan gate ada di `docs/IMPLEMENTATION_FLOW.md`.

## 5. Backlog desain (dibekukan sementara)

1. Arubaito non-fishing.
2. Hiking gameplay.
3. Multi-language runtime (`ja`, `id`).
4. Ekspansi area map besar lintas distrik.

Backlog hanya dibuka setelah seluruh fase aktif stabil dan lolos playtest manual.
