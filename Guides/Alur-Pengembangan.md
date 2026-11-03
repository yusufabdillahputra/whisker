---
title: Alur Pengembangan
description: Alur Superpowers dari ide sampai merge, lokasi spec/plan, aturan branch, commit, dan PR
updated: 2026-11-03
---

# Alur Pengembangan

Whisker dikembangkan dengan skill **Superpowers** ([obra/superpowers](https://github.com/obra/superpowers)).
Skill dipanggil lewat tool `Skill` sebelum langkahnya dikerjakan; bila ada skill yang relevan, wajib dipakai.

## Urutan per fitur

| # | skill | hasil |
| --- | --- | --- |
| 1 | `superpowers:brainstorming` | tanya-jawab satu per satu sampai desain disetujui user → `docs/superpowers/specs/YYYY-MM-DD-<topik>-design.md` |
| 2 | `superpowers:writing-plans` | plan bertahap (tugas kecil, file yang disentuh, test dulu) → `docs/superpowers/plans/YYYY-MM-DD-<topik>.md` |
| 3 | `superpowers:using-git-worktrees` | worktree/branch terisolasi untuk fitur |
| 4 | `superpowers:test-driven-development` | test merah → kode minimum → hijau → refactor, untuk setiap tugas |
| 5 | `superpowers:subagent-driven-development` (atau `executing-plans`) | eksekusi plan per tugas, review di antara tugas |
| 6 | `superpowers:requesting-code-review` | review terhadap spec dan plan sebelum merge |
| 7 | `superpowers:verification-before-completion` | jalankan perintah verifikasi dan tunjukkan output sebelum klaim selesai |
| 8 | `superpowers:finishing-a-development-branch` | pilih merge/PR, bersihkan worktree |

Bug, test gagal, atau perilaku aneh: **selalu** mulai dari `superpowers:systematic-debugging`
(cari akar masalah dulu, baru perbaiki). Masukan review diproses dengan
`superpowers:receiving-code-review` (verifikasi dulu, jangan langsung setuju).

## Bukti "selesai"

| jenis perubahan | bukti minimum |
| --- | --- |
| codec | `cd markdown_codec && dart test && dart analyze` hijau; round-trip korpus nyata dengan `WHISKER_FIXTURE_VAULT=<path-vault>` |
| server | `dart test` di `whisker_server/` hijau, migrasi ter-generate bila model berubah |
| aplikasi | `flutter analyze` bersih, `flutter test` hijau |
| UI | screenshot **light dan dark**, minimal satu ukuran ponsel dan satu desktop |
| warna | `python3 design/tools/check-contrast.py` tanpa `GAGAL` |
| logo/avatar | `npm run logo` di `design/tools/` dan cek `design/logo/preview.png` |

## Branch, commit, PR

- Branch dari `main`: `feat/<topik>`, `fix/<topik>`, `docs/<topik>`, `chore/<topik>`.
- Commit kecil dan fokus, prefix [Conventional Commits](https://www.conventionalcommits.org/):
  `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`. Deskripsi boleh Bahasa Indonesia.
- Satu PR = satu fitur/plan. Deskripsi PR menaut spec dan plan di `docs/superpowers/`.
- PR masuk `main` hanya setelah CI hijau (lihat [CI dan Release](CI-Release.md)).
- Keputusan arsitektur penting dicatat di spec (bagian "Keputusan") supaya tidak hilang di chat.
