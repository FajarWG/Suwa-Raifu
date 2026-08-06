# TECHNICAL DESIGN DOCUMENT

## Suwa Life: Nihongo Days

**Versi:** 0.1
**Status:** Draft
**Referensi:** PRD.md §13 (Arsitektur Teknis)

---

## 1. Arsitektur

```
Client (LocalScript / UI)  <--Remote-->  Server (ModuleScript / Script)  <--> DataStoreService
        |                                        |
        +-------- Shared (types, defs) ----------+
```

- Semua state otoritatif di **server**.
- **Client** hanya mengirim intent, menerima state yang sudah divalidasi.

## 2. Struktur folder (Rojo)

```
src/
├── shared/
│   ├── types/            # TypeScript-like type definition
│   ├── constants/
│   ├── data/             # Item, quest, dialogue, lesson definitions
│   ├── remotes.lua       # Definisi & API RemoteEvent/Function
│   └── util/
├── server/
│   ├── services/         # ModuleScript: Profile, Economy, Inventory, Quest, School...
│   ├── runner.server.lua # Entry point server
│   └── util/
└── client/
    ├── controllers/      # ModuleScript UI/input controller
    ├── runner.client.lua # Entry point client
    └── util/
```

## 3. Service (server)

| Service | Tanggung jawab | Dependensi |
|---|---|---|
| ProfileService | Load/save profile ke DataStore, session lock, migrasi versi | DataStoreService |
| EconomyService | Saldo Yen, transaksi, log | ProfileService |
| InventoryService | Item, clothing, furniture | ProfileService |
| QuestService | State quest aktif/selesai, objective progress | ProfileService |
| SchoolService | Attendance, kelas, quiz, XP | ProfileService |
| WorkService | Arubaito session & reward | ProfileService |
| FishingService | Hasil memancing (server RNG) | ProfileService |
| ShopService | Katalog, beli, jual | InventoryService, EconomyService |
| TimeService | Day/season/weather (server clock) | — |
| NPCService | NPC state & schedule | TimeService |
| EventService | Festival state, countdown, badge | TimeService |

## 4. Remote contracts

Semua remote didefinisikan di `shared/remotes.lua` (satu sumber kebenaran). Nama remote dibatasi regex `^[A-Z][A-Za-z0-9]*$`.

```
RemoteEvent (client -> server):
  WorkRequest(action)
  FishCast(position)
  FishReel()
  ShopBuy(itemId, qty)
  QuestAccept(questId)
  QuestClaim(questId)
  NPCInteract(npcId)
  SchoolCheckIn()
  QuizAnswer(lessonId, answers)
  BikeRequest(action)

RemoteFunction (client -> server):
  GetProfile() -> Profile
  GetShopCatalog() -> Catalog
  GetQuestLog() -> Quests
  GetTimeInfo() -> TimeInfo
```

Semua remote dilindungi rate limit di server (mis. maks N call/detik per pemain).

## 5. DataStore schema

- Key: `player_<userId>` di scope game.
- Struct: lihat `docs/data-schema.md`.
- Migrasi: `profile.version` diincrement → ProfileService punya migrator table.
- Retry: DataStore dengan retry (bounded) + session lock (`Attempt` data) untuk anti double-save.

## 6. Konvensi kode

- Luau, selene + stylua standar.
- ModuleScript di `server/services` sebagai singleton: `return ServiceModule` dengan method `ServiceModule.init()`.
- Error handling: return `{ ok = true, data = ... }` / `{ ok = false, error = ... }` dari service.
- Tidak ada `task.wait` panjang di server selain TimeService (pakai scheduler).

## 7. Sumber kebenaran konfigurasi

- Item, quest, dialog, lesson, shop, fish → file data di `src/shared/data/*` (bukan hardcode di script).
