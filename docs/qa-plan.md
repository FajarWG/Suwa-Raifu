# QA / TESTING PLAN

## Suwa Life: Nihongo Days

**Versi:** 0.2  
**Status:** Aktif (mengikuti flow implementasi bertahap)

Dokumen ini mengikuti `docs/IMPLEMENTATION_FLOW.md`. Tujuan QA sekarang adalah
menahan scope agar fitur selesai satu per satu, playable, dan aman.

---

## 1. Gate utama sebelum pindah fitur

Setiap fitur hanya boleh dinyatakan selesai jika semua ini lulus:

1. Build place sukses.
2. Tidak ada error berulang di Output Studio selama sesi test.
3. Alur utama fitur berhasil dijalankan minimal 3 kali berturut-turut.
4. Data profile/economy/inventory konsisten jika fitur menyentuh persistence.
5. Tidak ada bug `High` atau `Critical` terbuka pada fitur tersebut.

## 2. Command QA standar

```sh
rojo build default.project.json --output SuwaLife.rbxlx
rojo serve default.project.json
selene src
stylua --check src
rojo build tests.project.json --output build/SuwaLife-Test.rbxlx
```

Catatan: TestEZ dijalankan dari Roblox Studio pada place test, bukan `rojo test`.

## 3. Checklist regresi minimum (wajib setiap merge)

1. Spawn berada di area plaza lakeside.
2. HUD menampilkan Yen/XP/Level.
3. Dialog NPC terbuka dan quest intro bisa di-accept.
4. School panel terbuka dan quiz bisa di-submit.
5. Bag UI terbuka, inventory tampil, dan shop bisa beli item.
6. Fishing flow menghasilkan state valid (waiting/bite/reel/caught/failed).
7. Sepeda bisa dinaiki dan dituruni tanpa softlock.
8. Perahu bisa dikendarai tanpa menembus shoreline.
9. Fireworks console bisa start dan berhenti normal.
10. Keluar-masuk game tidak merusak profile.

## 4. Checklist anti-exploit minimum

1. Remote spam terkena rate limit (`RemoteRegistryService`).
2. Tidak ada perubahan Yen/XP langsung dari client tanpa validasi server.
3. Aksi fishing/shop/inventory invalid tidak mengubah state profile.

## 5. Prioritas test per fase

1. Fase 0: bootstrap, profile load, map load sequence.
2. Fase 1: onboarding quest + school.
3. Fase 2: mobilitas sepeda/perahu.
4. Fase 3: fishing economy loop.
5. Fase 4: festival event.

Fase berikutnya tidak boleh dimulai sebelum fase aktif lulus gate.

## 6. Bug triage

1. Catat repro step yang jelas (map, posisi, input, expected, actual).
2. Label severity: `Critical`, `High`, `Medium`, `Low`.
3. `Critical` dan `High` wajib ditutup sebelum pindah fase.
4. Setelah fix, ulang regression minimum.
