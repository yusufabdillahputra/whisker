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

## Test

Test endpoint memakai test tools Serverpod di `whisker_server/test/` dan dijalankan dengan `dart test`.
Ikuti TDD ([Alur Pengembangan](Alur-Pengembangan.md)): tulis test endpoint dulu, lihat gagal, baru implementasi.
