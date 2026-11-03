---
title: MCP dan Plugin
description: Hubungan aplikasi Whisker dengan MCP client dan repo whisker-plugins
updated: 2026-11-03
---

# MCP dan Plugin

## Peran masing-masing repo

| repo | isi |
| --- | --- |
| `whisker` (repo ini) | aplikasi + **MCP server** (endpoint di server Serverpod) |
| [`whisker-plugins`](https://github.com/yusufabdillahputra/whisker-plugins) | marketplace plugin Claude Code `whisker`: koneksi ke MCP server (URL + personal access token lewat `userConfig`, token `sensitive`) dan **skill umum** pemakaian tool MCP |

Skill di plugin bersifat **umum untuk semua proyek** (ambil konteks dari Hub, simpan knowledge, catat
kerja ke tracking). Aturan khusus satu proyek datang dari **Hub proyek itu** lewat MCP, bukan dari plugin.

## Rancangan MCP server (awal, belum final)

Meniru pola Hubzoid (`/mcp` Streamable HTTP, dijalankan dengan identitas pemanggil, diaudit):

- Endpoint `POST /mcp` di web server Relic milik Serverpod.
- Auth: personal access token per pengguna (dibuat di aplikasi), dipetakan ke peran per Hub.
- Setiap panggilan tool dicatat di log audit (pengguna, Hub, tool, hasil).
- Calon tool (dirinci saat brainstorming): daftar Hub, baca instruksi Hub, cari/baca knowledge,
  tulis knowledge (dengan validasi aturan Hub), buat/ubah Plan/Task, buat Confirmation (`open` saja),
  catat Question.
- Aturan Hub (ADR immutable, human gate, dependensi satu arah) **ditegakkan server**, sehingga berlaku
  untuk semua MCP client, bukan hanya Claude Code yang memasang hook.

## Kontrak antar-repo

Nama dan skema tool MCP adalah **kontrak**. Perubahan tool di repo ini harus diikuti pembaruan skill di
`whisker-plugins` pada PR pasangan, dan disebut di deskripsi kedua PR.
