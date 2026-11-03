---
title: Tech Stack
description: Pilihan teknologi Whisker beserta versi acuan; masih draf sampai dibahas bersama user
status: draf
updated: 2026-11-03
---

# Tech Stack (draf)

Bagian **Sudah ditetapkan** berasal dari arahan user. Bagian **Perlu diputuskan** dibahas lewat
`superpowers:brainstorming` sebelum kode pertama; hasilnya dicatat di `docs/superpowers/specs/` lalu
guide ini diperbarui.

## Sudah ditetapkan

| lapisan | pilihan | versi acuan (cek ulang saat setup) |
| --- | --- | --- |
| Bahasa | Dart | 3.12.2 (ikut Flutter) |
| Klien | Flutter, satu codebase untuk Android, iOS, Web, macOS, Windows, Linux | ≥ 3.44.4 (syarat Serverpod 4) |
| UI kit | [Forui](https://forui.dev/docs) (gaya shadcn/ui, 50+ widget, prefix `F`) | `forui` 0.27.x |
| Server | [Serverpod](https://docs.serverpod.dev/) (endpoint Dart, model YAML, ORM, auth, stream, future call) | 4.1.x |
| Database | PostgreSQL (embedded saat dev oleh `serverpod start`) | ≥ 16 |
| Avatar & logo | [DiceBear](https://www.dicebear.com/) dengan style `whisker-critters` (remix Critters, CC0) | `@dicebear/core` 10.x |
| Integrasi AI | MCP server di Whisker + plugin Claude Code di `whisker-plugins` | spesifikasi MCP Streamable HTTP |
| CI & release | GitHub Actions | lihat [CI dan Release](CI-Release.md) |
| Proses kerja | Superpowers | lihat [Alur Pengembangan](Alur-Pengembangan.md) |

## Perlu diputuskan

1. **State management dan routing Flutter**: mis. Riverpod / Bloc / `forui_hooks`, dan `go_router`.
2. **Penyimpanan dokumen**: markdown di kolom Postgres saja, atau file di object storage (Serverpod
   mendukung S3/GCS/database).
3. **Pencarian**: full-text Postgres, `pgvector` untuk semantic search, atau keduanya.
4. **Editor markdown** di aplikasi (wikilink, frontmatter, Mermaid) dan rendering lintas platform.
5. **Offline & sinkronisasi**: database lokal Serverpod (SQLite) di klien atau online-only dulu.
6. **Auth**: provider yang diaktifkan (email, Google, GitHub, passkey) dan format personal access
   token untuk MCP.
7. **Hosting**: Serverpod Cloud atau self-host (Docker).
8. **Extension / plugin lintas platform**: **menunggu masukan dari agent Retail** (daftar package
   Flutter per platform yang perlu disiapkan). Jangan memilih sendiri sebelum daftar itu ada.
9. **Lisensi repo `whisker`**: `whisker-plugins` memakai AGPL-3.0-only; repo aplikasi belum punya lisensi.
