---
title: Konsep Hub
description: Apa itu Hub di Whisker, isi Hub berdasarkan vault wiki-angkasa, dan apa yang diambil dari Hubzoid
updated: 2026-11-03
---

# Konsep Hub

## Ringkas

Whisker menyimpan pengetahuan **per proyek** dalam sebuah **Hub**. Satu Hub = satu "second brain"
proyek: knowledge yang tahan lama, pelacakan kerja, dan aturan main proyek itu. Hub dibaca dan ditulis
oleh manusia (aplikasi Flutter) dan oleh agent AI (lewat MCP, lihat [MCP dan Plugin](MCP-Plugin.md)).

## Pelajaran dari `wiki-angkasa` (contoh Hub nyata)

`Raw/wiki-angkasa.zip` adalah vault Obsidian untuk proyek ANGKASA (sistem konsolidasi keuangan) yang
dikelola bersama Claude Code. Strukturnya adalah cetak biru isi sebuah Hub Whisker:

| area | peran | catatan untuk Whisker |
| --- | --- | --- |
| `PKM/` | **knowledge**: `ADR/ API/ Architecture/ Business/ Database/ Domain/ Glosarium/` | inti Hub; satu-satunya yang diekspos sebagai konteks LLM |
| `PKM/_LLM-Wiki/` | mirror CommonMark polos untuk LLM/RAG | di Whisker **tidak perlu disimpan**: server merender markdown polos on-demand |
| `Features/<Track>/{Plan,Task}/` | tracking fitur per track | jadi entitas Plan/Task dengan status dan relasi |
| `Test/{Scenario,Run}/` | spec test dan eksekusinya | entitas Scenario/Run berpasangan |
| `Confirmation/` | keputusan terbuka, **human-gated** | status `open → confirmed/rejected`; hanya manusia yang boleh menutup |
| `Question/` | pertanyaan user bisnis + jawaban | entitas Question |
| `Dashboard/` | agregasi status (Obsidian Bases) | jadi layar dashboard di aplikasi |
| `Guides/` + `CLAUDE.md` | aturan main proyek | jadi "instruksi Hub" yang dikirim ke agent lewat MCP |
| `_Format/` | template tiap jenis note | jadi template bawaan per tipe dokumen |

Aturan vault yang harus menjadi **aturan server** (bukan sekadar hook di mesin user):

- **Dependensi satu arah:** tracking boleh menaut knowledge, knowledge tidak boleh bergantung pada tracking.
- **ADR immutable** setelah `accepted`; revisi lewat ADR baru yang men-*supersede*.
- **Human gate:** agent hanya boleh membuat Confirmation berstatus `open` dan menaikkan Task sampai `done`.
- **Komplain** atas Task tercatat dan bisa membuka ulang Task (`complaints: open/resolved`).
- **Dokumen terbaru menang** saat dua knowledge bentrok; tanggal dari metadata dokumen, bukan mtime.
- **Frontmatter + wikilink** tetap jadi format dokumen, supaya Hub bisa diimpor dari / diekspor ke
  vault Obsidian.

## Yang diambil dari Hubzoid

[Hubzoid](https://github.com/hubzoid/hubzoid) mengubah folder markdown menjadi agent: `AGENTS.md`,
`skills/<nama>/SKILL.md`, `knowledge/`, `raw_data/`, `schedule/`, `evals/`, akses per grup, gateway
multi-hub, dan server MCP Streamable HTTP di `/mcp` yang berjalan dengan identitas pemanggil.

Whisker **mengambil polanya, bukan kodenya** (Hubzoid Python/FastAPI; Whisker Dart/Serverpod):

| pola Hubzoid | padanan di Whisker |
| --- | --- |
| hub = folder markdown mandiri | Hub = ruang kerja per proyek di database, bisa impor/ekspor folder markdown |
| `knowledge/` + `read_knowledge` | area `PKM/` + tool MCP baca/cari knowledge |
| `skills/` dimuat on-demand | Guides + template Hub dimuat on-demand oleh agent |
| `raw_data/` + `grep_data` | lampiran mentah (BRD, dump) yang bisa dicari tapi bukan sumber kebenaran |
| `restricted/` + grup | peran per Hub (owner, editor, viewer, agent) yang ditegakkan server |
| `hubzoid gateway` | satu instance Whisker melayani banyak Hub dengan satu login |
| `MCP_SERVER=true` → `/mcp` | endpoint MCP di server Serverpod, token per pengguna |
| `audit` | log audit setiap aksi agent (siapa, tool, hasil) |
| `branding/` | logo DiceBear + token warna calico |

Belum diputuskan (dibahas di [Tech Stack](Tech-Stack.md)): penyimpanan dokumen (Postgres saja atau
plus object storage), pencarian (full-text Postgres atau vektor), dan sinkronisasi offline.
