# QA / TESTING PLAN

## Suwa Life: Nihongo Days

**Versi:** 0.1
**Status:** Draft

---

## 1. Jenis test

| Jenis | Tool | Kapan |
|---|---|---|
| Unit test (Luau) | TestEZ (`rojo test`) | tiap commit |
| Lint | Selene | tiap commit |
| Format | StyLua | tiap commit |
| Playtest manual | Roblox Studio | tiap fitur selesai |
| Playtest multiplayer | Roblox (server publik/private) | per milestone |
| Performance (mobile) | Studio device emulation | tiap phase visual |

## 2. Playtest checklist (per fitur)

- [ ] Fitur berjalan sesuai GDD.
- [ ] Tidak ada error di Output console (server & client).
- [ ] UI ok di PC & mobile (dimensi, font, touch).
- [ ] Save/load tidak corrupt (test disconnect, reconnect).
- [ ] Anti-exploit: tidak bisa spoof yen/XP dari client.
- [ ] Rate limit remote tidak meledakkan server.

## 3. Performance checklist

- [ ] FPS ≥ 30 di mobile kelas menengah.
- [ ] Loading pertama < 15 detik (koneksi wajar).
- [ ] Streaming aktif; tidak memuat seluruh map.
- [ ] Particle & VFX dibatasi (kembang api client-side).
- [ ] NPC aktif hanya dekat pemain.

## 4. Accessibility checklist

- [ ] Furigana bisa on/off.
- [ ] Romaji opsional.
- [ ] Subtitle audio.
- [ ] Volume kembang api terpisah.
- [ ] Reduced visual effects.
- [ ] Kontrol mobile nyaman.
- [ ] Warna bukan satu-satunya sinyal.

## 5. Regression checklist (MVP — PRD §22)

1. [ ] Spawn di sculpture plaza Sekicho-inspired dan menghadap ke danau.
2. [ ] Pergi ke sekolah.
3. [ ] Ikut 1 pelajaran.
4. [ ] Dapat Japanese XP.
5. [ ] Bekerja programmer.
6. [ ] Terima yen.
7. [ ] Beli makanan.
8. [ ] Memancing.
9. [ ] Pergi ke viewpoint.
10. [ ] Lihat kembang api.
11. [ ] Progress tersimpan.
12. [ ] 20 pemain stabil.
13. [ ] UI PC & mobile.
14. [ ] UI/dialog English; papan lokasi Jepang (multi-language ditunda).
15. [ ] Chat filtering.
16. [ ] Tanpa nama/logo/wajah nyata tanpa izin.

## 6. Bug triage flow

1. Player lapor (Roblox feedback / Discord).
2. Reproduce di Studio.
3. Tulis repro steps + severity.
4. Fix → unit test jika perlu → playtest → commit.
