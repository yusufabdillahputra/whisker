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

## Diputuskan saat brainstorming (2026-11-03)

Detail dan alasannya ada di `docs/superpowers/specs/2026-11-03-whisker-inti-hub-design.md`.

| topik | pilihan |
| --- | --- |
| State & routing | Riverpod + `go_router` |
| Editor | `appflowy_editor` + codec markdown Whisker (round-trip byte-identik) |
| Sumber kebenaran | Git-first: satu repo GitHub private per Hub; Postgres = indeks |
| Auth | login GitHub + GitHub App "Whisker" |
| Pencarian | full-text Postgres (semantic search menyusul di sub-proyek MCP) |
| Hosting | Docker di Cloud VPS IDCloudHost |
| Backup | `.zip` harian ke Object Storage IDCloudHost (S3-compatible), retensi 7 hari |

## Masih terbuka

1. **Extension / plugin lintas platform**: **menunggu masukan dari agent Retail**.
2. **Lisensi repo `whisker`**: `whisker-plugins` memakai AGPL-3.0-only; repo aplikasi belum punya lisensi.
