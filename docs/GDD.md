# GAME DESIGN DOCUMENT

## Suwa Life: Nihongo Days

**Versi:** 0.1 (prototype)
**Status:** Draft
**Referensi:** PRD.md v0.1

---

## 1. Player Loop (dari PRD)

Daily loop: bangun → mandi → siapkan makanan → cek cuaca → ke sekolah → kelas → arubaito/eksplorasi → pulang → tidur.

## 2. Sistem Progression

### Statistik inti (server-authoritative)

| Stat | Rentang | Sumber XP | Fungsi |
|---|---|---|---|
| Japanese XP | 0–10.000 | quiz, speaking, homework | Buka dialog & kelas baru |
| Yen | 0–∞ | arubaito, menjual ikan | Belanja |
| Energy | 0–100 | tidur (full), makanan | Batasi aktivitas harian |
| Hunger | 0–100 | makanan | Turun seiring waktu |
| Friendship | per NPC 0–100 | interaksi, hadiah, quest | Buka quest & dialog |
| Work Reputation | 0–100 | arubaito | Buka job & gaji lebih tinggi |
| Exploration Rank | 0–50 | foto viewpoint, collectible | Buka jalur & lokasi rahasia |
| Attendance | 0–hari sekolah | check-in kelas | Hasil sekolah |

### Level bahasa

| Level | Rentang XP | Setara |
|---|---|---|
| Beginner 1 | 0–999 | Pre-N5 |
| Beginner 2 | 1.000–2.499 | N5 |
| Elementary | 2.500–4.999 | N4 |
| Intermediate | 5.000–7.499 | N3 |
| Advanced | 7.500–10.000 | N2/N1 (konten panjang) |

## 3. Sistem Mini-game (rules ringkas)

### Kelas
1. Check-in di meja.
2. Duduk (seat enabled) sebelum kelas mulai.
3. Ikuti lesson (1–5 menit).
4. Quiz: 3–5 soal (pilihan ganda / susun kalimat / kanji-match).
5. Reward: Japanese XP + attendance + stamp.

### Arubaito programmer
1. Terima task di meja.
2. Mini-game per level:
   - Beginner: sambungkan blok logika (drag node).
   - Intermediate: temukan 1 baris salah.
   - Advanced: pilih desain API/database.
3. Reward: Yen + Programmer Reputation.

### Arubaito umum (supermarket/restoran)
- Cashier: scan & hitung kembalian (timed).
- Stocking: letakkan barang ke shelf kosong.
- Server: antar pesanan benar.
- Dish washing: tap-to-clean timed.
- 2–5 menit per sesi.

### Memancing
- Cast di spot valid (pilih spot by ikon).
- Timing: tap saat bar di zona.
- Hasil ikan tergantung waktu/cuaca/musim/umpan/level.
- Ikan: jual / masak / koleksi / hadiah NPC / quest.

### Hiking
- Beli/sewa perlengkapan.
- Pilih jalur → stamina bar → obstacle (jalan licin, climb).
- Foto viewpoint → collectible → kembali sebelum malam.
- Time trial & group expedition opsional.

### Festival
- Countdown event → yukata → stall (ring toss, goldfish-inspired) → dance emote → fireworks → group reward → badge limited.

## 4. Struktur Quest

```text
QuestDef:
  id, titleKey, descKey, giverNpcId,
  requirements (level, item, quest-lain),
  objectives[] (type, target, count, current),
  rewards (xp, yen, itemId, reputation),
  dialogFlowId
```

## 5. NPC

- Setiap NPC: id, displayName, schedule (waktu+tempat), dialogue set, friendship.
- Interaksi: ProximityPrompt → dialog tree (branching) → quest trigger.
- Dialogue level-gated (Japanese Level menentukan kalimat).

## 6. Ekonomi

- Semua perubahan Yen diproses server (anti-cheat).
- Sumber: arubaito, jual ikan, quest.
- Sink: makanan, pakaian, peralatan, dekorasi, sepeda upgrade.
- Logging transaksi (audit).

## 7. Day/Time System

- 1 hari game = X menit real (default 20 menit, tuning).
- Fase: pagi (6–10), siang (10–16), sore (16–19), malam (19–24), larut (24–6).
- Cuaca: cerah / hujan / salju (musiman), memengaruhi memancing & hiking.
- Musim: semi / panas / gugur / dingin (rotasi mingguan atau event).

## 8. Antisipasi Anti-Exploit

- Rate limit RemoteEvent per detik.
- Validasi server untuk: hasil pekerjaan, memancing, belanja, quest.
- Teleport & check-in divalidasi posisi.
