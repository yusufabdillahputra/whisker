# CLAUDE.md — Whisker

**Whisker** adalah aplikasi *knowledge base* terpusat (second brain lintas device dan lintas proyek),
dibangun dengan **Flutter** (klien), **Serverpod** (server Dart), dan **Forui** (UI kit), terinspirasi
dari [Hubzoid](https://github.com/hubzoid/hubzoid). Setiap proyek punya **Hub** sendiri di Whisker.
Contoh nyata isi sebuah Hub adalah vault `wiki-angkasa` (lihat [Konsep Hub](Guides/Konsep-Hub.md)).
MCP client seperti Claude Code mengakses Whisker lewat plugin di
[`whisker-plugins`](https://github.com/yusufabdillahputra/whisker-plugins).

> **Status: pra-implementasi.** Desain sub-proyek 1 (Inti Hub) ada di
> `docs/superpowers/specs/2026-11-03-whisker-inti-hub-design.md`. Sumber kebenaran Hub = repo git.

## Prinsip kerja

1. **Pikir dulu, baru kode.** Nyatakan asumsi. Bila ambigu, tanyakan; jangan memilih diam-diam.
2. **Sederhana dulu.** Kode dan dokumen minimum yang menyelesaikan masalah, tanpa abstraksi spekulatif.
3. **Perubahan bedah.** Sentuh hanya yang diminta; ikuti gaya dan konvensi yang sudah ada.
4. **Berorientasi tujuan.** Ubah tugas jadi kriteria sukses yang bisa diverifikasi, dan buktikan
   (test, screenshot, output perintah) sebelum mengklaim selesai.

## Alur pengembangan: Superpowers (wajib)

Semua pengembangan memakai skill **Superpowers** secara berurutan:
`brainstorming` → `writing-plans` → `using-git-worktrees` → `test-driven-development` →
`subagent-driven-development` / `executing-plans` → `requesting-code-review` →
`verification-before-completion` → `finishing-a-development-branch`. Bug selalu lewat
`systematic-debugging`. Spec dan plan disimpan di `docs/superpowers/`. Detail:
[Alur Pengembangan](Guides/Alur-Pengembangan.md).

## Bahasa

Dokumen, komentar penjelasan, dan balasan chat dalam **Bahasa Indonesia**. Tetap **Inggris** untuk
identifier kode, nama file/folder kode, kunci YAML/JSON/frontmatter, istilah teknis baku, dan prefix
commit (`feat:`, `fix:`, `docs:`, …).

## Struktur repo (rencana)

| path | isi |
| --- | --- |
| `whisker_server/` | server Serverpod: endpoint, model `.spy.yaml`, migrasi, MCP endpoint |
| `whisker_client/` | client Dart hasil generate Serverpod (**jangan diedit manual**) |
| `whisker_flutter/` | aplikasi Flutter + Forui (Android, iOS, Web, macOS, Windows, Linux) |
| `markdown_codec/` | paket Dart murni: parse/serialize markdown vault, dipakai server dan aplikasi |
| `design/` | design token, style DiceBear, logo, dan tool desain |
| `Guides/` | panduan detail tiap proses (baca sebelum mengerjakan proses itu) |
| `docs/superpowers/` | spec (`specs/`) dan plan (`plans/`) hasil Superpowers |

## Aturan inti

- **Kode generate tidak diedit manual** (`whisker_client/`, `lib/src/generated/`). Ubah `.spy.yaml`
  atau endpoint, lalu generate ulang.
- **Rahasia tidak pernah di-commit** (`config/passwords.yaml`, `.env`, token MCP).
- **Warna hanya dari token.** Jangan menulis hex di widget; pakai `context.theme.colors` dan token di
  `design/tokens/whisker.tokens.json`. Ubah token → jalankan `python3 design/tools/check-contrast.py`.
- **Logo dan avatar hanya dari style DiceBear** `design/dicebear/whisker-critters.json` (remix Critters); jangan
  menggambar ulang manual.
- **Git:** kerja di branch fitur, commit kecil dengan prefix Conventional Commits, masuk `main` lewat PR
  yang lolos CI.
- **CI dan release lewat GitHub Actions** untuk Android, iOS, Web, macOS, Windows, dan Linux.

## Guides: detail ada di sini

CLAUDE.md hanya memuat aturan inti. **Sebelum mengerjakan suatu proses, baca guide-nya dulu.**

| butuh detail tentang… | baca |
| --- | --- |
| apa itu Hub, isi Hub (pelajaran dari `wiki-angkasa`), inspirasi Hubzoid | [Konsep Hub](Guides/Konsep-Hub.md) |
| pilihan teknologi dan versinya (draf, menunggu diskusi) | [Tech Stack](Guides/Tech-Stack.md) |
| alur Superpowers, spec/plan, branch, commit, PR | [Alur Pengembangan](Guides/Alur-Pengembangan.md) |
| server: model, endpoint, migrasi, auth, test | [Serverpod](Guides/Serverpod.md) |
| aplikasi: struktur Flutter, tema Forui, aksesibilitas | [Flutter dan Forui](Guides/Flutter-Forui.md) |
| palet calico, design token, kontras WCAG | [Desain Warna](Guides/Desain-Warna.md) |
| logo dan avatar dengan DiceBear | [Logo DiceBear](Guides/Logo-DiceBear.md) |
| MCP server Whisker dan plugin Claude Code | [MCP dan Plugin](Guides/MCP-Plugin.md) |
| CI, build lintas platform, dan release | [CI dan Release](Guides/CI-Release.md) |
