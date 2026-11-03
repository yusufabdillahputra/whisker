---
title: Serverpod
description: Konvensi server Whisker dengan Serverpod 4 — setup, model .spy.yaml, endpoint, database, migrasi, test
updated: 2026-11-03
---

# Serverpod

Sumber: <https://docs.serverpod.dev/> (versi 4.1.0). Cek ulang dokumentasi bila versi berubah.

## Setup

```bash
flutter doctor                 # Serverpod 4 butuh Flutter ≥ 3.44.4 (Dart 3.12.2)
dart install serverpod_cli     # versi lama via `dart pub global activate`? deactivate dulu
serverpod version
serverpod create whisker       # menghasilkan whisker_server/, whisker_client/, whisker_flutter/
```

## Loop harian

```bash
serverpod start
```

Perintah ini men-generate kode, menjalankan server dengan **PostgreSQL embedded** (tanpa Docker),
membuka app Flutter, dan hot reload saat file disimpan. Di terminalnya: **R** = hot restart (wajib
setelah menambah endpoint atau mengubah tipe return), **M** = buat dan terapkan migrasi database.

## Konvensi

- **Per fitur satu folder**: `whisker_server/lib/src/<fitur>/` berisi endpoint, model, dan logika.
- **Model** di `*.spy.yaml` di bawah `lib/`. Tambah `table: <nama_jamak_snake_case>` bila disimpan di
  database. Beri komentar `###` pada class dan field (jadi dokumentasi kode generate).

  ```yaml
  ### Dokumen knowledge dalam sebuah Hub
  class: Note
  table: notes
  fields:
    ### Judul dokumen
    title: String
    ### Isi markdown (dengan frontmatter)
    body: String
    updatedAt: DateTime
  ```

- **Endpoint**: class `<Nama>Endpoint extends Endpoint`, parameter pertama selalu `Session session`,
  return `Future<T>` atau `Stream<T>`. Di klien menjadi `client.<nama>.<method>(...)`.
- **ORM**: `Note.db.insertRow(session, note)`, `Note.db.find(session, where: ..., orderBy: ...)`.
  Jangan menulis SQL mentah kecuali ada alasan terukur (catat di spec).
- **Aturan Hub ditegakkan di server** (ADR immutable, human gate, peran per Hub), bukan di klien.
  Lihat [Konsep Hub](Konsep-Hub.md).
- **Rahasia** di `whisker_server/config/passwords.yaml` (di-gitignore), dibaca lewat
  `session.passwords['<kunci>']`.
- **Migrasi** di-generate dan di-commit bersama perubahan model pada commit yang sama.
- **Fitur bawaan yang dipakai dulu sebelum membuat sendiri**: auth module (email, Google, Apple,
  GitHub, Microsoft, passkey), stream WebSocket, upload file, future call terjadwal, cache, dan web
  server Relic (untuk endpoint MCP/REST/webhook).

## Modul server Whisker

| folder `lib/src/` | isi |
| --- | --- |
| `hub/` | `Hub`, `HubMember`, `HubService` (data dir, antrean per Hub, cek anggota), endpoint `hub` (list, create, importVault, reindex, watch) |
| `doc/` | `HubDocument`, `DocumentLink`, DTO, endpoint `doc` (tree, read, search, backlinks, history, commit), tabel FTS `document_fts` |
| `git/` | `GitRepo` (membungkus `git` sistem), `HubLocks` |
| `github/` | GitHub App (token instalasi), verifikasi tanda tangan webhook |
| `index/` | indexer markdown → Postgres memakai paket `markdown_codec` |
| `sync/` | siaran `HubChange`, sinkron dari remote, webhook `POST /webhooks/github`, rekonsiliasi 5 menit |
| `backup/` | backup zip harian 02.00 WIB ke Object Storage S3-compatible, retensi 7 hari |

Clone kerja tiap Hub ada di `$WHISKER_DATA_DIR/hubs/<hubId>` (default `.data/`, di Docker `/data`).

## Kunci `passwords.yaml` Whisker

Semua opsional; fitur terkait mati bila kuncinya tidak ada.

| kunci | dipakai untuk |
| --- | --- |
| `githubClientId`, `githubClientSecret` | login GitHub (OAuth App / GitHub App) |
| `githubAppId`, `githubAppPrivateKey` | token instalasi untuk clone/push repo Hub |
| `githubWebhookSecret` | verifikasi webhook `push` |
| `s3Endpoint`, `s3AccessKey`, `s3SecretKey`, `s3Bucket`, `s3Region` | backup ke Object Storage IDCloudHost |

Tanpa kunci GitHub App, server memakai `remoteUrl` Hub apa adanya (path lokal atau kredensial helper git).

## Test

Test endpoint memakai test tools Serverpod di `whisker_server/test/` dan dijalankan dengan `dart test`.
Ikuti TDD ([Alur Pengembangan](Alur-Pengembangan.md)): tulis test endpoint dulu, lihat gagal, baru implementasi.
Remote GitHub di test diganti **repo bare lokal** di temp dir.

Postgres embedded menolak berjalan sebagai root. Bila perlu memakai Postgres eksternal:

```bash
SERVERPOD_DATABASE_DATA_PATH=" " SERVERPOD_DATABASE_PORT=5433 \
SERVERPOD_DATABASE_PASSWORD=<pw> dart test
```
