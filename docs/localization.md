# LOCALIZATION

## Suwa Life: Nihongo Days

**Bahasa awal (PRD §10):** Jepang (ja) · Indonesia (id) · Inggris (en)

**Format file:** `src/shared/data/localization/<lang>.json` (load server-agnostic, dipakai UI client).

**Key convention:** `domain.id.field` (contoh `item.onigiri.name`).

**Prioritas:** ja → en → id → (my, zh-CN, ne/hi berikutnya).

---

## Template per bahasa

```json
{
  "ui": {
    "app.title": "Suwa Life: Nihongo Days",
    "app.loading": "読み込み中... / Loading... / Memuat..."
  },
  "item": {
    "onigiri": {
      "name": "おにぎり / Onigiri / Onigiri",
      "desc": "..."
    }
  },
  "quest": {
    "intro": {
      "title": "...",
      "desc": "..."
    }
  },
  "class": {
    "start": "...",
    "quiz": "..."
  }
}
```

## Aturan

1. **Selalu** pakai key, jangan hardcode teks di script.
2. Dialog pendidikan **harus direview manual** (furigana & terjemahan benar).
3. Semua teks pemain yang tampil ke pemain lain melewati filtering Roblox (TextChatService).
4. Furigana & romaji sebagai setting per pemain (`settings.showFurigana`, `showRomaji`).
5. Bahasa default UI: dari `settings.preferredLanguage`, fallback en.

## Proses

1. AI generate draft JSON.
2. Reviewer manusia cek terjemahan & nuansa.
3. Commit ke `src/shared/data/localization/`.
4. UI re-load saat ganti bahasa (tanpa restart).
