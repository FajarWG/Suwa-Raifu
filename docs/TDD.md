# TECHNICAL DESIGN DOCUMENT

## Suwa Life: Nihongo Days

**Versi:** 0.2  
**Status:** Active design (sinkron dengan kode saat ini)

---

## 1. Arsitektur runtime

```
Client Controllers  <->  Remote Registry  <->  Server Services  <->  DataStore
        |                                                 |
        +---------------- Shared (types/data/util) -------+
```

Prinsip:

1. State gameplay otoritatif ada di server.
2. Client hanya mengirim intent, render UI, dan menampilkan feedback.
3. Semua nama remote terpusat di `src/shared/remotes.lua`.

## 2. Startup order server

Urutan init server (`src/server/runner.server.lua`):

1. `RemoteRegistryService`
2. `TerrainService`
3. Service lain (kecuali service yang perlu urutan khusus)
4. `BicycleService`
5. `ParkInteractionService`

Urutan ini menghindari asset map dibangun di elevasi yang belum final.

## 3. Service aktif di kode saat ini

| Service                  | Status   | Peran                                                           |
| ------------------------ | -------- | --------------------------------------------------------------- |
| RemoteRegistryService    | Aktif    | Membuat remotes + rate limit + register helper                  |
| ProfileService           | Aktif    | Load/save profile + fallback studio                             |
| ProfileAPI               | Aktif    | Remote `GetProfile`, `QuestAccept`, `QuestClaim`, `GetQuestLog` |
| EconomyService           | Aktif    | Operasi yen/xp level dasar                                      |
| InventoryService         | Aktif    | Item/fish snapshot dan mutasi server-side                       |
| QuestService             | Aktif    | Accept/progress/complete quest                                  |
| SchoolService            | Aktif    | Lesson list, quiz submit, reward xp                             |
| NPCDialogService         | Aktif    | Interaksi NPC dan dialog flow                                   |
| SpawnService             | Aktif    | Spawn NPC + prompt                                              |
| TerrainService           | Aktif    | Danau/terrain pondasi map                                       |
| LakesideParkService      | Aktif    | Elemen taman lakeside                                           |
| TownRoadService          | Aktif    | Grid jalan dan lingkungan kota kecil                            |
| BicycleService           | Aktif    | Kendaraan sepeda rideable                                       |
| LakeActivityService      | Aktif    | Boat rideable + aktivitas pulau                                 |
| FishingGameService       | Aktif    | Fishing state machine + shop + inventory action                 |
| FireworksFestivalService | Aktif    | Festival fireworks timered event                                |
| WorldWildlifeService     | Aktif    | Fauna visual ambience                                           |
| ParkInteractionService   | Aktif    | Interaksi duduk/playground                                      |
| TimeService              | Skeleton | Tick waktu dasar, belum jadi orchestrator sistem                |

## 4. Remote contract saat ini

Remote events utama:

1. `QuestAccept`, `QuestClaim`, `NPCInteract`
2. `SchoolCheckIn`, `QuizSubmit`
3. `FishCast`, `FishReel`, `FishingState`
4. `ShopBuy`, `OpenShop`, `ShopResult`
5. `InventoryAction`, `InventoryUpdated`

Remote functions utama:

1. `GetProfile`
2. `GetQuestLog`
3. `LessonGet`
4. `GetInventory`
5. `GetShopCatalog`
6. `NPCGetDialog`

Semua remote harus didaftarkan di `src/shared/remotes.lua` terlebih dahulu.

## 5. Testing strategy teknis

1. Pure logic ditempatkan di `src/shared/util` dan diuji via TestEZ specs.
2. Service gameplay diuji dengan playtest manual terstruktur per fase.
3. Regression minimal wajib dijalankan sebelum merge (lihat `docs/qa-plan.md`).

## 6. Ruang yang belum final

1. `TimeService` baru skeleton.
2. Validasi anti-exploit berbasis posisi/state machine masih perlu diperluas.
3. Integrasi test service-level belum ada automation lengkap.
