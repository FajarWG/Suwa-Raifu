# QA Session 2026-08-18

## Scope

Fase aktif: Fase 0 (stabilitas fondasi vertical slice).

## Automated Gate Result

1. Build place: PASS
2. Lint (selene): PASS
3. Format check (stylua --check): PASS

Ringkasan exit code:

1. build_exit=0
2. selene_exit=0
3. stylua_check_exit=0

## Manual Human Playtest Checklist (Fase 0)

Isi kolom status dengan PASS/FAIL dan tambahkan catatan singkat.

| No  | Item                                                    | Status  | Catatan |
| --- | ------------------------------------------------------- | ------- | ------- |
| 1   | Join game 3x, profile ter-load normal (tidak nil)       | PENDING |         |
| 2   | Spawn konsisten di area plaza lakeside                  | PENDING |         |
| 3   | HUD tampil (Yen, XP, Level) setelah spawn               | PENDING |         |
| 4   | Tidak ada error spam di Output selama 10 menit          | PENDING |         |
| 5   | Remote dasar berjalan tanpa warning rate-limit abnormal | PENDING |         |

## Blocking Issues

1. Manual checklist belum dieksekusi.

## Decision

Fase 0 belum boleh ditutup. Fokus berikutnya:

1. Jalankan checklist manual sampai semua PASS.
