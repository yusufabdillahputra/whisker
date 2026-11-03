# Whisker App (Inti Hub 3/3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Aplikasi Flutter + Forui untuk membaca, mencari, mengedit (WYSIWYG `appflowy_editor`) dan meng-commit dokumen Hub, dengan layout tiga panel, mode ponsel, dan sinkron folder lokal di desktop.

**Architecture:** Lapisan data `WhiskerApi` (antarmuka; implementasi Serverpod + palsu untuk test/demo) dibungkus provider Riverpod; `HubChange` dari `hub.watch` meng-invalidate provider. Editor memetakan blok `MdDocument` ke node `appflowy_editor`: heading/paragraf/list/quote yang round-trip-nya stabil menjadi node WYSIWYG, sisanya (fence/Mermaid, callout, tabel, HTML, konstruksi lossy) menjadi **raw block** yang disunting sebagai teks. Saat simpan, blok yang tidak berubah memakai `source` asli sehingga file tanpa edit byte-identik.

**Tech Stack:** Flutter 3.47.9, `forui` ^0.27.7, `flutter_riverpod` ^3.4.3, `go_router` ^18.1.2, `appflowy_editor` (git, commit `01eccc6`, kompatibel Flutter 3.47), `shared_preferences`, `file_selector`, `flutter_svg`, `markdown_codec`, `whisker_client`.

**Spec:** `docs/superpowers/specs/2026-11-03-whisker-inti-hub-design.md`

## Global Constraints

- Warna hanya dari token `design/tokens/whisker.tokens.json` (via `lib/app/tokens.g.dart` hasil generator); tidak ada hex di widget.
- Logo hanya dari `design/logo/*.svg` (hasil style DiceBear `whisker-critters`).
- Light/dark mengikuti sistem; WCAG 2.2 AA; target sentuh ≥ 44 dp (`touch: true` di Android/iOS); ikon tanpa teks punya `Semantics`.
- Breakpoint: ≥ 1100 px tiga panel; 700–1099 px pohon + editor, inspector lewat sheet; < 700 px bottom nav **Beranda/Dokumen/Cari/Tracking** (Tracking = "Segera hadir").
- Dokumen yang dibuka lalu disimpan tanpa edit menghasilkan file byte-identik.
- Dialog **Commit changes**: pesan default `docs(<area>): update <judul>`, deskripsi opsional.
- Draf disimpan lokal per (`hubId`, `path`) dan tetap ada saat konflik.
- `whisker_flutter` diresolusi terpisah dari workspace pub (appflowy_editor bentrok win32 dengan Serverpod server).
- Teks UI Bahasa Indonesia.

## Review Focus

1. **Enter di tengah paragraf/heading** membuat node baru yang mungkin mewarisi atribut blok asal: hasil simpan harus tetap memisahkan paragraf dengan baris kosong → test `split_node_keeps_blank_line` di Task 3.
2. **Edit list bertanda `-`**: appflowy menulis `*`; hasil simpan memakai penanda asli → test `edited_list_keeps_marker` di Task 3.
3. **Konflik saat commit**: draf tidak hilang; dialog menampilkan isi terbaru dan pilihan muat ulang → test `conflict_keeps_draft` di Task 5.
4. **Dokumen baca saja (ADR accepted, `_Format`)**: editor tidak bisa diketik dan tombol commit nonaktif, tetapi frontmatter `status` tetap bisa diubah → test `readonly_banner_and_status_edit` di Task 6.
5. **Folder lokal dengan perubahan belum di-push**: `local_sync` tidak menyentuhnya dan melapor status → test `local_changes_untouched` di Task 8.

---

### Task 1: Fondasi aplikasi — token, tema, data, router

**Files:**
- Create: `design/tools/gen-dart-tokens.py` → `whisker_flutter/lib/app/tokens.g.dart`; `lib/app/theme.dart`, `lib/app/app.dart`, `lib/data/whisker_api.dart`, `lib/data/serverpod_api.dart`, `lib/data/fake_api.dart`, `lib/data/providers.dart`; ubah `lib/main.dart`
- Delete: `lib/screens/greetings_screen.dart`, `test/spike_test.dart`
- Test: `test/theme_test.dart`, `test/providers_test.dart`

**Interfaces:**
- `class WhiskerTokens` (generated): `static const Color` per token `fur50`…`nose950`, dan `class WhiskerSemantic { background, foreground, primary, …, input, ring, success, successForeground, brand }` dengan `static const light`/`dark`.
- `FThemeData whiskerTheme(Brightness b, {required bool touch})`.
- `abstract class WhiskerApi { Future<List<Hub>> hubs(); Future<Hub> createHub(String name, {String? githubRepo, String? remoteUrl, int? installationId}); Future<Hub> importVault(int hubId, Uint8List zip); Future<List<DocSummary>> tree(int hubId); Future<DocContent> read(int hubId, String path); Future<List<SearchHit>> search(int hubId, String q); Future<List<DocSummary>> backlinks(int hubId, String path); Future<List<HistoryEntry>> history(int hubId, String path); Future<CommitResult> commit(CommitRequest r); Stream<HubChange> watch(int hubId); }`
- `FakeWhiskerApi` (memori, isi contoh sintetis, `commit` mensimulasikan `ok`/`conflict` dengan `baseSha`).
- Provider: `apiProvider`, `hubsProvider`, `treeProvider(int)`, `docProvider((int, String))`, `backlinksProvider((int, String))`, `historyProvider((int, String))`, `hubWatchProvider(int)` (mendengar `watch`, meng-invalidate tree/doc/backlinks/history untuk path yang berubah).
- Router: `/` → daftar Hub; `/hub/:hubId?doc=<path>` → workspace. `--dart-define=WHISKER_DEMO=true` → `FakeWhiskerApi` dan lewati login.

- [ ] **Step 1: Tulis test gagal**: `theme_test` (`whiskerTheme(light).colors.primary == WhiskerSemantic.light.primary` dan nilainya `#A75001`; dark pakai `WhiskerSemantic.dark`); `providers_test` (`treeProvider` dengan `FakeWhiskerApi` → path terurut; event `HubChange` pada `watch` membuat `treeProvider` dimuat ulang).
- [ ] **Step 2:** Jalankan `flutter test` → FAIL. **Step 3:** Implementasi. **Step 4:** `flutter test` + `flutter analyze` → PASS / bersih.
- [ ] **Step 5: Commit** `feat(app): fondasi tema calico, lapisan data, dan router`

### Task 2: Jembatan blok di `markdown_codec`

**Files:**
- Create: `markdown_codec/lib/src/assemble.dart`, `markdown_codec/test/assemble_test.dart`

**Interfaces:**
- `class BodyPiece { final int? blockIndex; final String? markdown; }` — `blockIndex` + `markdown == null` = blok asli tak berubah; `blockIndex` + `markdown` = blok asli diedit (tanpa newline akhir); `blockIndex == null` = blok baru.
- `String assembleBody(MdDocument doc, List<BodyPiece> pieces)` — blok asli membawa baris kosong pendahulunya; blok baru dipisah satu baris kosong; baris kosong di akhir dokumen asli dipertahankan; newline dokumen dipakai untuk teks baru.
- `List<int> contentBlockIndexes(MdDocument doc)` — indeks blok non-`blank`.

- [ ] **Step 1: Tulis test gagal**: `identity_for_all_fixtures` (semua fixture + CRLF: pieces = semua blok non-blank tanpa edit → `frontmatter.raw + assembleBody == input`), `edit_middle_block`, `delete_block_drops_its_leading_blank`, `append_new_block_after_noeol` (dokumen tanpa newline akhir + blok baru → dipisah `\n\n`), `crlf_new_text_uses_crlf`.
- [ ] **Step 2–4:** FAIL → implementasi → PASS.
- [ ] **Step 5: Commit** `feat(codec): rakit ulang body dari potongan blok editor`

### Task 3: Codec editor appflowy + raw block

**Files:**
- Create: `whisker_flutter/lib/features/editor/editor_codec.dart`, `lib/features/editor/raw_block.dart`
- Test: `whisker_flutter/test/editor_codec_test.dart`

**Interfaces:**
- `const rawBlockType = 'whisker_raw'`; atribut node: `wb` (indeks blok asli, int), `source` (teks raw), `label` (mis. `Mermaid`, `Callout note`, `Tabel`, `HTML`, `Fence <info>`).
- `Document editorDocumentFrom(MdDocument doc)` — tiap blok non-blank: jenis `heading|paragraph|list|blockquote` yang lolos `isStableForEditor(source)` → node hasil `markdownToDocument`, semua diberi atribut `wb`; selain itu satu node raw.
- `bool isStableForEditor(String source)` — `documentToMarkdown(markdownToDocument(s))` sama dengan `s` setelah normalisasi penanda list (`-`/`+` → `*`) dan trim akhir.
- `String bodyFromEditor(MdDocument original, Document edited)` — kelompokkan node berurutan menurut `wb`; kelompok yang markdown-nya sama dengan snapshot saat dimuat → `BodyPiece(i)`; berubah → `BodyPiece(i, markdown)` (list: join `\n` dan penanda dikembalikan ke penanda asli; lainnya join `\n\n`); node tanpa `wb` → blok baru; lalu `assembleBody`.
- `RawBlockComponentBuilder` — label + `TextField` monospace yang menulis `source` lewat transaksi editor.

- [ ] **Step 1: Tulis test gagal**: `fixtures_roundtrip_without_edit` (fixture `markdown_codec/test/fixtures/*` → `bodyFromEditor(doc, editorDocumentFrom(doc)) == doc.frontmatter.body`), `edit_heading_changes_one_line`, `mermaid_is_raw_and_editable`, `split_node_keeps_blank_line`, `edited_list_keeps_marker`, `new_paragraph_appended`.
- [ ] **Step 2–4:** FAIL → implementasi → PASS.
- [ ] **Step 5: Commit** `feat(app): codec editor appflowy dengan raw block byte-identik`

### Task 4: Shell, daftar Hub, dan pohon dokumen

**Files:**
- Create: `lib/features/shell/workspace_page.dart` (responsif tiga panel / sheet / bottom nav), `lib/features/hubs/hubs_page.dart` (daftar Hub, dialog **Hub baru**, tombol **Impor vault** `.zip` via `file_selector`), `lib/features/hub_tree/hub_tree.dart` (folder bisa dilipat, ikon per area, dokumen aktif disorot), `lib/features/auth/sign_in_page.dart` (bungkus `SignInWidget` Serverpod bertema Forui, logo `whisker-mark.svg`)
- Test: `test/hub_tree_test.dart`, `test/workspace_layout_test.dart`

- [ ] **Step 1: Tulis test gagal**: `tree_groups_folders` (`PKM/ADR/a.md`, `PKM/API/b.md`, `README.md` → folder `PKM` berisi `ADR`, `API`; tap dokumen memanggil `onOpen(path)`), `layout_breakpoints` (1280 px: tiga panel; 900 px: dua panel + tombol inspector; 390 px: bottom nav 4 item, label `Tracking`).
- [ ] **Step 2–4:** FAIL → implementasi → PASS.
- [ ] **Step 5: Commit** `feat(app): shell responsif, daftar Hub, dan pohon dokumen`

### Task 5: Panel editor, draf, dan dialog commit

**Files:**
- Create: `lib/features/editor/editor_pane.dart`, `lib/data/drafts.dart` (`DraftStore` di `shared_preferences`: `save(hubId, path, content, baseSha)`, `load`, `clear`), `lib/features/commit/commit_dialog.dart`, `lib/features/commit/conflict_dialog.dart`
- Test: `test/commit_flow_test.dart`

**Interfaces:**
- `EditorPane(hubId, path)`: memuat `docProvider`, membangun `EditorState`, menandai kotor saat `bodyFromEditor + frontmatter != content`, menyimpan draf (debounce 800 ms), tombol **Commit changes** (nonaktif bila bersih atau baca saja).
- `Future<CommitResult?> showCommitDialog(context, {required String defaultMessage})` → field Pesan (terisi default) + Deskripsi.
- Hasil `conflict` → `ConflictDialog` menampilkan isi terbaru, pilihan **Muat ulang (buang draf)** / **Tetap pakai draf saya** (draf tetap; `baseSha` diganti `latestSha` agar commit berikutnya menimpa secara sadar); `rejected` → toast alasan.

- [ ] **Step 1: Tulis test gagal**: `commit_sends_default_message` (edit → Commit → dialog terisi `docs(knowledge): update …` → kirim → `FakeWhiskerApi` menerima isi baru dan draf dihapus), `conflict_keeps_draft`, `rejected_shows_reason`.
- [ ] **Step 2–4:** FAIL → implementasi → PASS.
- [ ] **Step 5: Commit** `feat(app): editor dengan draf lokal dan dialog commit bergaya GitHub`

### Task 6: Inspector — Properties, Backlinks, Riwayat — dan baca saja

**Files:**
- Create: `lib/features/inspector/inspector.dart`
- Modify: `lib/features/editor/editor_pane.dart` (banner baca saja)
- Test: `test/inspector_test.dart`

**Interfaces:**
- Properties: daftar kunci frontmatter + editor YAML mentah (`FTextField` multiline) yang ikut di-commit; Backlinks: daftar dokumen (tap → buka); Riwayat: pesan, author, tanggal relatif.
- Dokumen dengan `readOnlyReason`: banner berisi alasan, editor `editable = false`; untuk ADR accepted, Properties tetap bisa diedit dan tombol commit aktif bila frontmatter berubah.

- [ ] **Step 1: Tulis test gagal**: `backlinks_and_history_listed`, `readonly_banner_and_status_edit`.
- [ ] **Step 2–4:** FAIL → implementasi → PASS.
- [ ] **Step 5: Commit** `feat(app): inspector properties, backlinks, riwayat, dan mode baca saja`

### Task 7: Palet pencarian `Ctrl K`

**Files:**
- Create: `lib/features/search/search_palette.dart`
- Test: `test/search_test.dart`

- [ ] **Step 1: Tulis test gagal**: `ctrl_k_opens_and_navigates` (Ctrl+K → ketik `kucing` → hasil berisi judul + snippet → Enter membuka dokumen pertama), `mobile_search_tab` (tab **Cari** di ponsel menampilkan palet yang sama).
- [ ] **Step 2–4:** FAIL → implementasi (debounce 250 ms) → PASS.
- [ ] **Step 5: Commit** `feat(app): palet pencarian Ctrl K`

### Task 8: `local_sync` desktop

**Files:**
- Create: `lib/features/local_sync/local_sync.dart` (`LocalSync { LocalSync(String root); Future<SyncStatus> syncHub(Hub hub); }`, `enum SyncState { cloned, updated, upToDate, localChanges, error }`), `lib/features/local_sync/local_sync_panel.dart` (pilih folder via `file_selector`, status per Hub; hanya `!kIsWeb && (Platform.isMacOS || isWindows || isLinux)`)
- Test: `test/local_sync_test.dart` (tanpa widget; dua clone + satu remote bare)

**Interfaces:**
- `syncHub`: folder `<root>/<hub.slug>` belum ada → `git clone hub.remoteUrl`; ada → `git status --porcelain` atau `git rev-list @{u}..HEAD` tidak kosong → `localChanges` (tidak menyentuh apa pun); selain itu `git pull --ff-only` → `updated`/`upToDate`. Dipanggil saat aplikasi dibuka dan saat `HubChange` diterima.

- [ ] **Step 1: Tulis test gagal**: `clones_then_fast_forwards`, `local_changes_untouched` (file lokal belum di-commit dan commit lokal belum di-push → status `localChanges`, isi tetap).
- [ ] **Step 2–4:** FAIL → implementasi → PASS.
- [ ] **Step 5: Commit** `feat(app): sinkron folder lokal Hub di desktop`

### Task 9: Verifikasi ujung ke ujung dan screenshot

**Files:**
- Create: `whisker_flutter/tool/screenshots.mjs` (Playwright: build web demo, tangkap light/dark × ponsel 390×844 / desktop 1440×900), `whisker_server/tool/e2e_check.dart` (skrip: daftar akun email dev, buat Hub dari repo bare, impor zip contoh, tree, search, commit, konflik — terhadap server dev yang berjalan)
- Modify: `Guides/Flutter-Forui.md` (generator token, struktur fitur, mode demo), `CLAUDE.md` (status)

- [ ] **Step 1:** `flutter build web --dart-define=WHISKER_DEMO=true` → jalankan `tool/screenshots.mjs` → 4 PNG di `docs/screenshots/`.
- [ ] **Step 2:** Jalankan server dev + `dart run tool/e2e_check.dart` → semua langkah `OK`.
- [ ] **Step 3:** `flutter analyze` bersih, `flutter test` hijau, `dart test` server & codec hijau.
- [ ] **Step 4: Commit** `docs(app): screenshot, verifikasi e2e, dan panduan aplikasi`
