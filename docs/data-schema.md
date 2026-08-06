# DATA SCHEMA

## Suwa Life: Nihongo Days

**Versi:** 1
**Status:** Draft

---

## 1. Player Profile (DataStore)

```json
{
  "version": 1,
  "playerId": 123456,
  "profile": {
    "displayName": "Fathur",
    "homeCountry": "ID",
    "preferredLanguage": "id"
  },
  "progress": {
    "japaneseXp": 1200,
    "japaneseLevel": 4,
    "workReputation": 12,
    "explorationRank": 3,
    "fishingLevel": 2,
    "hikingLevel": 1,
    "cookingLevel": 1,
    "reputation": 0,
    "happiness": 75,
    "energy": 80,
    "hunger": 40
  },
  "economy": { "yen": 18500 },
  "inventory": {
    "items": { "onigiri": 2 },
    "clothing": { "uniform": 1 },
    "furniture": {},
    "fish": { "koi": 1 }
  },
  "school": {
    "attendance": 18,
    "completedLessons": ["lesson_01"],
    "examResults": {}
  },
  "quests": {
    "active": [],
    "completed": ["quest_intro"]
  },
  "friendship": { "teacher_sakura": 30 },
  "bike": { "owned": false, "upgrades": {} },
  "settings": {
    "showFurigana": true,
    "showRomaji": false,
    "translationLanguage": "id"
  },
  "lastSaved": "2026-08-06T00:00:00Z"
}
```

## 2. Item definition

```json
{
  "id": "onigiri",
  "nameKey": "item.onigiri",
  "category": "food",
  "price": 150,
  "stackable": true,
  "consumable": true,
  "effects": { "hunger": -30, "energy": 5 },
  "icon": "rbxassetid://0000",
  "tags": ["food", "japanese"]
}
```

## 3. Quest definition

```json
{
  "id": "quest_intro",
  "titleKey": "quest.intro.title",
  "descKey": "quest.intro.desc",
  "giverNpcId": "teacher_sakura",
  "requirements": { "japaneseLevel": 1 },
  "objectives": [
    { "type": "talk", "target": "teacher_sakura", "count": 1 },
    { "type": "collect", "target": "item_textbook", "count": 1 }
  ],
  "rewards": { "xp": 100, "yen": 0, "items": ["item_textbook"] }
}
```

## 4. Dialogue schema

```json
{
  "npcId": "teacher_sakura",
  "level": "N5",
  "intent": "greeting",
  "japanese": "おはようございます。きょうもがんばりましょう。",
  "reading": "おはようございます。きょうも がんばりましょう。",
  "romaji": "Ohayou gozaimasu. Kyou mo ganbarimashou.",
  "translations": {
    "id": "Selamat pagi. Mari berusaha hari ini juga.",
    "en": "Good morning. Let's do our best today too."
  }
}
```

## 5. Localization keys

- Format key: `[domain].[id].[field]`, contoh `item.onigiri.name`, `quest.intro.title`.
- File: `src/shared/data/localization/*.json` per bahasa (`ja`, `en`, `id`).
- UI membaca dari tabel lokal; server tidak bergantung pada teks.

## 6. Catatan migrasi

- `profile.version` selalu dicek saat load.
- Tambah migrator: `migrations[fromVersion] = function(profile) -> profile` (chain ke versi terbaru).
- Jangan simpan data sensitif (percakapan, info pribadi).
