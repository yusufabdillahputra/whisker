# markdown_codec Implementation Plan (Inti Hub · rencana 1 dari 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Paket Dart murni `markdown_codec` yang mem-parse markdown vault menjadi dokumen berblok dan menyerialisasinya kembali **byte-identik** bila tidak diedit, plus ekstraksi judul, wikilink, tag, dan klasifikasi area/tipe.

**Architecture:** Dokumen = frontmatter (teks mentah + map YAML) + daftar blok. Setiap blok menyimpan `source` verbatim; serialisasi menggabungkan `source` blok yang tidak diedit, dan hanya blok yang diedit yang dirender ulang. Ekstraksi (wikilink, judul, tag) dan klasifikasi bekerja di atas model ini, sehingga server (`index`) dan aplikasi (editor, rencana 3) memakai parser yang sama.

**Tech Stack:** Dart ≥ 3.12, `package:yaml`, `package:test`, `package:lints`.

**Spec:** `docs/superpowers/specs/2026-11-03-whisker-inti-hub-design.md` (bagian 3 "Aplikasi", 5 "Model data", 6 "Codec markdown", 8 "Testing").

**Urutan rencana Inti Hub:** (1) `markdown_codec` — dokumen ini; (2) server: git, index, doc/commit, webhook, backup; (3) aplikasi Flutter: tiga panel, editor `appflowy_editor` (konversi blok ↔ node editor), dialog commit, `local_sync`. Rencana 2 dan 3 ditulis setelah rencana 1 selesai, karena keduanya memakai API dari sini.

## Global Constraints

- Lokasi paket: `markdown_codec/` di root repo `whisker`; nama paket `markdown_codec`; `environment: sdk: ^3.12.0`.
- Paket **tidak boleh** bergantung pada Flutter atau `appflowy_editor` (harus bisa dipakai server).
- Dependensi runtime hanya `yaml`; dev: `test`, `lints`.
- Round-trip: `MdDocument.parse(s).serialize() == s` untuk **setiap** string `s` (termasuk CRLF, tanpa newline akhir, file kosong).
- Konten vault klien (`wiki-angkasa`) **tidak di-commit** ke repo; test korpus membacanya dari env `WHISKER_FIXTURE_VAULT` dan di-skip bila tidak diset.
- Komentar dan dokumentasi dalam Bahasa Indonesia; identifier dalam Inggris.
- Commit memakai Conventional Commits (`feat(codec): …`, `test(codec): …`).

## Review Focus

1. **File CRLF** (`\r\n`): batas blok dan frontmatter harus dikenali, dan serialisasi tetap `\r\n` → test `crlf_roundtrip` di Task 2 dan Task 3.
2. **Fence tak tertutup** (```` ``` ```` tanpa penutup sampai EOF): sisa file menjadi satu blok `fence`, tidak melempar error → test `unclosed_fence_consumes_rest` di Task 3.
3. **Frontmatter YAML tidak valid**: tidak melempar; `frontmatter` kosong, `frontmatterError` terisi, round-trip tetap identik → test `invalid_yaml_keeps_raw` di Task 2.
4. **Wikilink di dalam kode** (fence atau `` `inline` ``) tidak dihitung sebagai tautan → test `ignores_links_in_code` di Task 5.
5. **File hanya frontmatter / file kosong / tanpa newline akhir** tetap round-trip dan judul jatuh ke nama file → test `empty_and_frontmatter_only` di Task 3 dan `title_fallback_to_stem` di Task 5.

---

### Task 1: Kerangka paket

**Files:**
- Create: `markdown_codec/pubspec.yaml`, `markdown_codec/analysis_options.yaml`, `markdown_codec/lib/markdown_codec.dart`, `markdown_codec/README.md`, `markdown_codec/test/smoke_test.dart`

**Interfaces:**
- Produces: library `package:markdown_codec/markdown_codec.dart` yang meng-export `src/` (diisi task berikutnya).

- [ ] **Step 1: Tulis `pubspec.yaml`** dengan `name: markdown_codec`, `environment: sdk: ^3.12.0`, `dependencies: yaml: ^3.1.0`, `dev_dependencies: test: ^1.25.0, lints: ^5.0.0`; `analysis_options.yaml` meng-include `package:lints/recommended.yaml`.
- [ ] **Step 2: Tulis test smoke** `test/smoke_test.dart`: `test('library loads', () => expect(markdownCodecVersion, '0.1.0'));`
- [ ] **Step 3: Jalankan** `cd markdown_codec && dart pub get && dart test` → FAIL (`markdownCodecVersion` belum ada).
- [ ] **Step 4: Tambah** `const markdownCodecVersion = '0.1.0';` di `lib/markdown_codec.dart`; README satu paragraf (tujuan + cara test + env `WHISKER_FIXTURE_VAULT`).
- [ ] **Step 5: Jalankan** `dart test && dart analyze` → PASS, `No issues found!`
- [ ] **Step 6: Commit** `chore(codec): kerangka paket markdown_codec`

### Task 2: Pemisahan frontmatter

**Files:**
- Create: `markdown_codec/lib/src/frontmatter.dart`, `markdown_codec/test/frontmatter_test.dart`

**Interfaces:**
- Produces:
  - `class FrontmatterSplit { final String raw; final Map<String, Object?> data; final String? error; final String body; }` — `raw` = teks dari `---` pembuka sampai baris `---` penutup **termasuk** newline-nya (string kosong bila tak ada); `raw + body == input`.
  - `FrontmatterSplit splitFrontmatter(String input)`
  - `String detectNewline(String input)` → `'\r\n'` bila baris pertama berakhir `\r\n`, selain itu `'\n'`.

- [ ] **Step 1: Tulis test gagal** di `frontmatter_test.dart`:
  - `no_frontmatter`: `splitFrontmatter('# A\n')` → `raw == ''`, `body == '# A\n'`, `data` kosong.
  - `basic`: input `'---\ntype: adr\ntags: [a, b]\n---\n# T\n'` → `raw == '---\ntype: adr\ntags: [a, b]\n---\n'`, `data['type'] == 'adr'`, `data['tags'] == ['a','b']`, `body == '# T\n'`.
  - `crlf_roundtrip`: input sama dengan `\r\n` → `raw + body == input`, `data['type'] == 'adr'`.
  - `invalid_yaml_keeps_raw`: `'---\nkey: [unclosed\n---\nisi\n'` → `data` kosong, `error != null`, `raw + body == input`.
  - `dashes_not_at_start`: `'teks\n---\nbukan: fm\n---\n'` → `raw == ''`.
  - `unclosed_frontmatter`: `'---\na: 1\n'` (tanpa penutup) → `raw == ''`, `body == input`.
- [ ] **Step 2: Jalankan** `dart test test/frontmatter_test.dart` → FAIL (fungsi belum ada).
- [ ] **Step 3: Implementasi** di `src/frontmatter.dart`: frontmatter hanya bila input diawali `---` + newline dan ada baris yang persis `---` (boleh diikuti `\r`) setelahnya; YAML di-parse dengan `loadYaml`, dikonversi ke `Map<String,Object?>`/`List` Dart biasa; error parse → `data = {}`, `error = e.toString()`. Export dari `lib/markdown_codec.dart`.
- [ ] **Step 4: Jalankan** test → PASS.
- [ ] **Step 5: Commit** `feat(codec): pemisahan frontmatter yang menjaga teks asli`

### Task 3: Segmentasi blok + `MdDocument` round-trip

**Files:**
- Create: `markdown_codec/lib/src/block.dart`, `markdown_codec/lib/src/document.dart`, `markdown_codec/test/document_test.dart`, `markdown_codec/test/fixtures/` (fixture sintetis, lihat Step 1)

**Interfaces:**
- Consumes: `splitFrontmatter`, `detectNewline` (Task 2).
- Produces:
  - `enum MdBlockKind { heading, paragraph, list, fence, blockquote, callout, table, thematicBreak, html, blank }`
  - `class MdBlock { final MdBlockKind kind; final String source; final int? level; /* heading */ final String? info; /* fence: info string, mis. 'mermaid' */ final String text; /* isi tanpa penanda: heading tanpa '#', fence tanpa pagar, callout tanpa '> ' */ final bool edited; }`
  - `MdBlock MdBlock.edit(MdBlock original, String newText)` → blok `edited: true`, `source` dirender ulang dari `newText` memakai penanda asli (level heading, info fence, prefix `> `/`> [!type]`) dan newline dokumen.
  - `List<MdBlock> parseBlocks(String body)` — invariant: `parseBlocks(b).map((x) => x.source).join() == b`.
  - `class MdDocument { final FrontmatterSplit frontmatter; final List<MdBlock> blocks; final String newline; static MdDocument parse(String input); String serialize(); MdDocument replaceBlock(int index, MdBlock block); }`

- [ ] **Step 1: Tulis fixture sintetis** di `test/fixtures/`: `adr.md` (frontmatter + heading + paragraf + tabel + callout `> [!note]`), `mermaid.md` (fence ```` ```mermaid ```` berisi baris `---` dan `# bukan heading`), `lists.md` (list `-`, `*`, bernomor, bersarang, checklist `- [ ]`), `crlf.md` (versi CRLF dari `adr.md`, ditulis dari test lewat `replaceAll('\n','\r\n')` — jangan simpan file CRLF di git), `noeol.md` (tanpa newline akhir), `embeds.md` (`![[gambar.png]]`, `[[A#Bagian|alias]]`, HTML `<details>`).
- [ ] **Step 2: Tulis test gagal** di `document_test.dart`:
  - `roundtrip_fixtures`: untuk setiap file di `test/fixtures/` dan versi CRLF-nya, `MdDocument.parse(s).serialize() == s`.
  - `crlf_roundtrip`: `MdDocument.parse(crlf).newline == '\r\n'`.
  - `kinds_mermaid`: blok fence di `mermaid.md` punya `kind == fence`, `info == 'mermaid'`, dan tidak ada blok `heading` dengan teks `bukan heading`.
  - `unclosed_fence_consumes_rest`: `'a\n\n```js\nx\n# y\n'` → blok terakhir `fence` dengan `source == '```js\nx\n# y\n'`.
  - `empty_and_frontmatter_only`: `''`, `'---\na: 1\n---\n'`, `'tanpa newline'` → round-trip identik; blocks berturut-turut `[]`, `[]`, `[paragraph]`.
  - `edit_heading_only_changes_that_block`: parse `adr.md`, `replaceBlock(i, MdBlock.edit(heading, 'Judul Baru'))`, serialize → sama dengan input kecuali baris heading itu menjadi `# Judul Baru`.
  - `edit_callout_keeps_marker`: edit teks callout → baris pertama tetap `> [!note]`, setiap baris isi diawali `> `.
- [ ] **Step 3: Jalankan** `dart test test/document_test.dart` → FAIL.
- [ ] **Step 4: Implementasi `parseBlocks`** sebagai pemindai baris (line scanner) yang menyimpan newline tiap baris: baris kosong berurutan → `blank`; ```` ``` ```` / `~~~` → `fence` sampai pagar penutup dengan karakter & panjang ≥ pembuka (atau EOF); `#`–`######` + spasi → `heading`; `> [!` → `callout`, `>` lain → `blockquote` (berlanjut selama baris diawali `>`); baris diawali `|` → `table`; penanda list (`-`,`*`,`+`,`\d+[.)]`) beserta baris lanjutan ter-indent → `list`; `---`/`***`/`___` sendirian → `thematicBreak`; baris diawali `<` tag blok → `html` sampai baris kosong; sisanya → `paragraph` sampai baris kosong atau awal blok lain.
- [ ] **Step 5: Implementasi `MdDocument`** (`parse` = `splitFrontmatter` + `parseBlocks(body)`; `serialize` = `frontmatter.raw` + gabungan `source`) dan `MdBlock.edit` (render ulang hanya blok itu, newline dokumen, pertahankan newline penutup blok asli).
- [ ] **Step 6: Jalankan** test → PASS.
- [ ] **Step 7: Commit** `feat(codec): segmentasi blok dengan round-trip byte-identik`

### Task 4: Test korpus vault nyata (opsional via env)

**Files:**
- Create: `markdown_codec/test/corpus_test.dart`

**Interfaces:**
- Consumes: `MdDocument.parse/serialize` (Task 3).

- [ ] **Step 1: Tulis test** `corpus_roundtrip`: bila `Platform.environment['WHISKER_FIXTURE_VAULT']` kosong → `markTestSkipped('WHISKER_FIXTURE_VAULT tidak diset')`; selain itu untuk setiap `*.md` (rekursif, lewati `.git/`, `.obsidian/`) baca sebagai UTF-8, `expect(MdDocument.parse(s).serialize(), s, reason: path)`. Hitung dan cetak jumlah file yang diuji.
- [ ] **Step 2: Jalankan** dengan vault: `WHISKER_FIXTURE_VAULT=/path/ke/wiki-angkasa dart test test/corpus_test.dart` → PASS dengan 240 file (ukuran korpus `wiki-angkasa` per 2026-11-03). Bila gagal, perbaiki `parseBlocks`, tambahkan potongan minimal penyebabnya ke `test/fixtures/` sebagai regresi (tanpa isi bisnis klien), lalu ulangi.
- [ ] **Step 3: Jalankan tanpa env** `dart test` → test korpus `skipped`, sisanya PASS.
- [ ] **Step 4: Commit** `test(codec): round-trip korpus vault lewat WHISKER_FIXTURE_VAULT`

### Task 5: Ekstraksi judul, wikilink, tag

**Files:**
- Create: `markdown_codec/lib/src/extract.dart`, `markdown_codec/test/extract_test.dart`

**Interfaces:**
- Consumes: `MdDocument`, `MdBlockKind` (Task 3).
- Produces:
  - `class WikiLink { final String target; final String? heading; final String? alias; final bool embed; }` — `[[A#B|C]]` → target `A`, heading `B`, alias `C`; `![[x.png]]` → `embed: true`; `[[#Bagian]]` → target `''` (tautan ke dokumen sendiri).
  - `List<WikiLink> extractWikilinks(MdDocument doc)`
  - `String extractTitle(MdDocument doc, String path)` — urutan: frontmatter `title` → heading level 1 pertama (teks tanpa `#`) → nama file tanpa `.md`.
  - `List<String> extractTags(MdDocument doc)` — dari frontmatter `tags` (list atau string dipisah koma/spasi), di-trim, tanpa `#`, unik, urutan asli.

- [ ] **Step 1: Tulis test gagal**:
  - `parses_parts`: `'[[A#B|C]] dan ![[x.png]] dan [[#Sub]]'` → tiga `WikiLink` sesuai definisi di atas.
  - `ignores_links_in_code`: wikilink di dalam fence dan di dalam `` `[[x]]` `` tidak diambil; wikilink di paragraf sebelahnya diambil.
  - `links_in_lists_tables_callouts`: wikilink di list, sel tabel, dan callout diambil.
  - `title_order`: frontmatter `title: X` → `X`; tanpa itu dengan `# ADR-003 — Autentikasi` → `ADR-003 — Autentikasi`; tanpa keduanya, path `PKM/ADR/ADR-001 - Offload.md` → `ADR-001 - Offload`.
  - `title_fallback_to_stem`: dokumen kosong → nama file.
  - `tags_forms`: `tags: [a, b]` → `['a','b']`; `tags: "#a, b c"` → `['a','b','c']`; tidak ada → `[]`.
- [ ] **Step 2: Jalankan** `dart test test/extract_test.dart` → FAIL.
- [ ] **Step 3: Implementasi**: lewati blok `fence`/`html`; di blok lain buang segmen `` `…` `` dulu, lalu regex `(!)?\[\[([^\]\|#]*)(?:#([^\]\|]*))?(?:\|([^\]]*))?\]\]`.
- [ ] **Step 4: Jalankan** test → PASS.
- [ ] **Step 5: Commit** `feat(codec): ekstraksi judul, wikilink, dan tag`

### Task 6: Klasifikasi area dan tipe dokumen

**Files:**
- Create: `markdown_codec/lib/src/classify.dart`, `markdown_codec/test/classify_test.dart`

**Interfaces:**
- Produces:
  - `enum DocArea { knowledge, tracking, guide, other }`
  - `class DocClass { final DocArea area; final String? type; }`
  - `DocClass classifyPath(String path, Map<String, Object?> frontmatter)` — frontmatter `type` (string) selalu menang untuk `type`.

- [ ] **Step 1: Tulis test gagal** `classify_table` dengan tabel kasus (path → area, type):
  - `PKM/ADR/ADR-001 - X.md` → knowledge, `adr`; `PKM/API/…` → knowledge, `api`; `PKM/Architecture/…` → knowledge, `architecture`; `PKM/Business/…` → knowledge, `business`; `PKM/Database/…` → knowledge, `entity`; `PKM/Domain/…` → knowledge, `domain`; `PKM/Glosarium/…` → knowledge, `glossary`
  - `Features/Backend/Plan/01 - X Plan.md` → tracking, `plan`; `Features/Frontend/Task/02 - Y.md` → tracking, `task`; `Test/Scenario/…` → tracking, `scenario`; `Test/Run/…` → tracking, `run`; `Confirmation/03 - Z.md` → tracking, `confirmation`; `Question/01 - Q.md` → tracking, `question`; `Dashboard/Dashboard.md` → tracking, `dashboard`
  - `Guides/PKM.md` → guide, `null`; `CLAUDE.md` → guide, `null`; `README.md` → other, `null`
  - `PKM/_LLM-Wiki/adr/x.md` → other, `mirror`; `Features/_Format/Template - Task.md` → other, `template`
  - `frontmatter_wins`: path `PKM/ADR/x.md` dengan frontmatter `type: note` → knowledge, `note`.
- [ ] **Step 2: Jalankan** `dart test test/classify_test.dart` → FAIL.
- [ ] **Step 3: Implementasi** `classifyPath` dengan pencocokan segmen path (pisah `/`, case-sensitive sesuai konvensi vault); `_LLM-Wiki` dan `_Format` di mana pun di path menang atas area folder induknya.
- [ ] **Step 4: Jalankan** `dart test && dart analyze` → semua PASS, `No issues found!`
- [ ] **Step 5: Commit** `feat(codec): klasifikasi area dan tipe dokumen dari konvensi vault`

### Task 7: Integrasi repo

**Files:**
- Modify: `CLAUDE.md` (baris struktur repo `markdown_codec/` → tambahkan perintah test), `Guides/Alur-Pengembangan.md` (tabel "Bukti selesai": baris `codec` → `cd markdown_codec && dart test`)

- [ ] **Step 1: Perbarui kedua dokumen** sesuai Files di atas.
- [ ] **Step 2: Jalankan** `cd markdown_codec && dart test && dart analyze` → PASS, `No issues found!`
- [ ] **Step 3: Commit** `docs: perintah verifikasi markdown_codec`
