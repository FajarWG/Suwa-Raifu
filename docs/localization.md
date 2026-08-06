# LOCALIZATION

## Suwa Life: Nihongo Days

**Bahasa aktif prototype:** Inggris (`en`) saja.

Papan lokasi di dunia menggunakan bahasa Jepang untuk konteks lingkungan. Resource
`ja` dan `id` lama tetap disimpan sebagai bahan phase localization, tetapi tidak
ditawarkan dan tidak dipilih oleh runtime saat ini.

**Format file:** `src/shared/data/localization/<lang>.lua` (load server-agnostic, dipakai UI client).

**Key convention:** `domain.id.field` (contoh `item.onigiri.name`).

**Prioritas saat ini:** en. Multi-language dipindahkan ke phase berikutnya.

---

## Template per bahasa

```json
{
  "ui": {
    "app.title": "Suwa Life: Nihongo Days",
    "app.loading": "Loading..."
  },
  "item": {
    "onigiri": {
      "name": "Onigiri",
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

1. UI/dialog memakai key English; jangan menambah pilihan bahasa baru pada prototype.
2. Papan dunia boleh hardcode bahasa Jepang karena merupakan bagian dari environment.
3. Dialog pendidikan Jepang **harus direview manual** sebelum phase localization diaktifkan.
4. Semua teks pemain yang tampil ke pemain lain melewati filtering Roblox (TextChatService).
5. Voice menggunakan voice chat resmi Roblox; tidak membuat voice/audio custom tanpa filter.
6. Runtime mengabaikan locale profile lama dan selalu fallback ke `en` selama prototype.

## Proses

1. Tulis dan review copy English.
2. Tambahkan papan Jepang langsung pada model environment.
3. Setelah map/core loop stabil, audit ulang resource `ja` dan `id`.
4. Aktifkan locale tambahan satu per satu lewat `Config.availableLocales`.
