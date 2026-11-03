# Whisker Server (Inti Hub 2/3) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Server Serverpod Whisker yang memegang clone git tiap Hub, mengindeks markdown ke Postgres, melayani baca/cari/commit dokumen, menerima webhook push, menyiarkan perubahan, dan membuat backup harian.

**Architecture:** Git-first. Repo remote (GitHub private, atau path/URL lain lewat `remoteUrl`) adalah kebenaran; server memegang clone kerja di `<dataDir>/hubs/<hubId>` dan menjalankan satu operasi git per Hub sekaligus. Postgres hanya indeks turunan (`document`, `document_link`, tabel FTS) yang bisa dibangun ulang. Parsing memakai paket `markdown_codec` (plan 1).

**Tech Stack:** Dart 3.12+, Serverpod 4.1.0 (`serverpod_auth_idp_server` GitHub + email), PostgreSQL 16 (FTS `simple`), `git` sistem, `markdown_codec`, `archive` ^4.6.0, `crypto` ^3.0.8, `http` ^1.6.0, `dart_jsonwebtoken` ^3.4.1, `minio` ^3.5.8.

**Spec:** `docs/superpowers/specs/2026-11-03-whisker-inti-hub-design.md`

## Global Constraints

- Kode generate (`whisker_client/`, `whisker_server/lib/src/generated/`, `test/integration/test_tools/`) tidak diedit manual; ubah `.spy.yaml`/endpoint lalu `serverpod generate`.
- `config/passwords.yaml` tidak pernah di-commit; kunci baru didokumentasikan di `Guides/Serverpod.md`.
- Isi markdown **tidak** disimpan di Postgres; dibaca dari clone kerja. Riwayat file dari `git log -- <path>`.
- Satu operasi git per Hub sekaligus (antrean per Hub).
- Commit dari aplikasi: author = user, committer = `Whisker <bot@whisker.local>`.
- Pesan commit default: `docs(<area>): update <judul>`.
- Full-text: konfigurasi `simple`, bobot judul (A) > tag (B) > isi (C).
- Backup: `backups/<hub-slug>/<YYYY-MM-DD>.zip`, 02.00 WIB (19.00 UTC), hapus objek > 7 hari **hanya bila backup hari ini sukses**, gagal → coba ulang tiap jam.
- Rekonsiliasi `ls-remote` vs `headSha` setiap 5 menit.
- Saat impor buang `.obsidian/`, `.git/`, `.claude/settings.local.json`, dan file yang cocok `.gitignore` vault.
- Aturan Hub: ADR `status: accepted` hanya boleh mengubah `status` dan `superseded_by`; path berisi segmen `_LLM-Wiki` atau `_Format` tidak bisa diedit.
- Commit message dan komentar dalam Bahasa Indonesia; identifier Inggris.

## Review Focus

1. **Dua commit bersamaan ke Hub yang sama** (dua perangkat menekan Commit hampir bersamaan): antrean per Hub menyerialkan; commit kedua berbasis `baseSha` lama untuk file yang sama → `conflict`, bukan menimpa → test `concurrent_commits_serialized` di Task 8.
2. **Path berbahaya** (`../x.md`, path absolut, bukan `.md`): ditolak sebelum menyentuh disk → test `rejects_unsafe_paths` di Task 8.
3. **Zip impor dengan entri `../` (zip-slip) atau folder akar tunggal** (`wiki-angkasa/…`): entri jahat diabaikan, folder akar tunggal di-strip → test `import_strips_root_and_blocks_zip_slip` di Task 7.
4. **Webhook dengan tanda tangan salah / repo tak dikenal**: ditolak 401 / diabaikan 202 tanpa sinkron → test `webhook_rejects_bad_signature` di Task 9.
5. **Push ditolak karena remote maju di file lain**: rebase lalu push ulang sekali, hasil `ok` dan file lain tetap → test `remote_advanced_other_file_rebases` di Task 8.

## Lingkungan test lokal

`serverpod_test` memakai Postgres embedded (butuh user non-root). Bila dijalankan sebagai root atau dengan Postgres eksternal, set:
`SERVERPOD_DATABASE_DATA_PATH=" " SERVERPOD_DATABASE_PORT=<port> SERVERPOD_DATABASE_PASSWORD=<pw>`.
Perintah test server di plan ini ditulis `dart test` dari `whisker_server/` dengan env tersebut bila perlu.

---

### Task 1: Kerangka Serverpod di repo

**Files:**
- Create: `pubspec.yaml` (workspace: `markdown_codec`, `whisker_client`, `whisker_server`, `whisker_flutter`), `whisker_server/`, `whisker_client/`, `whisker_flutter/` dari `serverpod create whisker --database --auth --no-redis --no-webapp --no-website --ide none`
- Modify: `markdown_codec/pubspec.yaml` (`resolution: workspace`), `.gitignore`
- Delete: contoh `greetings/` beserta test-nya, `AGENTS.md`, `.github/workflows/deploy.yml` hasil scaffold (CI = sub-proyek 4; workflow lain ikut dihapus)
- Test: `whisker_server/test/integration/smoke_test.dart`

**Interfaces:**
- Produces: paket `whisker_server` yang bergantung pada `markdown_codec` (path `../markdown_codec`), `archive`, `crypto`, `http`, `dart_jsonwebtoken`, `minio`.

- [ ] **Step 1:** Generate scaffold di direktori sementara, salin tiga paket + root `pubspec.yaml` ke repo; tambah `markdown_codec` ke workspace; pastikan `config/passwords.yaml` dan `.serverpod/` ter-ignore.
- [ ] **Step 2:** Hapus contoh greeting, `serverpod generate`, `serverpod create-migration`.
- [ ] **Step 3: Tulis test** `smoke_test.dart`: `withServerpod('smoke', ...)` → `expect(await Hub.db.count(session), 0)` (setelah Task 3 ada; di task ini cukup `session.db.unsafeQuery('select 1')` mengembalikan 1 baris).
- [ ] **Step 4: Jalankan** `cd whisker_server && dart test` → PASS; `dart analyze` → `No issues found!`
- [ ] **Step 5: Commit** `chore(server): kerangka Serverpod 4.1 dalam workspace`

### Task 2: Aturan Hub di `markdown_codec`

**Files:**
- Create: `markdown_codec/lib/src/rules.dart`, `markdown_codec/test/rules_test.dart`

**Interfaces:**
- Produces: `String? checkHubRules(String path, String? oldContent, String newContent)` → `null` bila boleh, selain itu alasan berbahasa Indonesia. `String? readOnlyReason(String path, String content)` → alasan dokumen dibuka baca saja (dipakai aplikasi dan endpoint `read`).

- [ ] **Step 1: Tulis test gagal**:
  - `protected_paths`: `PKM/_LLM-Wiki/a.md` dan `Features/_Format/T.md` → non-null; `PKM/ADR/a.md` baru → null.
  - `accepted_adr_only_status`: ADR lama `type: adr`, `status: accepted`; ubah body → non-null; ubah `status: superseded` + tambah `superseded_by: ADR-010` dengan body sama → null.
  - `draft_adr_free`: `status: proposed` → body bebas diubah → null.
  - `read_only_reason`: ADR accepted → mengandung `ADR`; `_Format` → non-null; dokumen biasa → null.
- [ ] **Step 2: Jalankan** `dart test test/rules_test.dart` → FAIL.
- [ ] **Step 3: Implementasi**: ADR terdeteksi dari `classifyPath(...).type == 'adr'`; bandingkan `frontmatter.data` tanpa kunci `status`/`superseded_by` dan `body` (setelah frontmatter) lama vs baru.
- [ ] **Step 4: Jalankan** `dart test` → PASS.
- [ ] **Step 5: Commit** `feat(codec): aturan Hub untuk ADR terkunci dan path terlindungi`

### Task 3: Model data dan skema full-text

**Files:**
- Create: `whisker_server/lib/src/hub/hub.spy.yaml`, `hub_member.spy.yaml`, `whisker_server/lib/src/doc/document.spy.yaml`, `document_link.spy.yaml`, `whisker_server/lib/src/backup/backup_record.spy.yaml`, DTO di `whisker_server/lib/src/doc/dto/*.spy.yaml`, `whisker_server/lib/src/doc/search_schema.dart`, migrasi hasil generate
- Test: `whisker_server/test/integration/models_test.dart`

**Interfaces:**
- Produces (tabel):
  - `Hub` (`hub`): `name String`, `slug String` (unik), `githubRepo String?` (`owner/name`), `remoteUrl String`, `installationId int?`, `defaultBranch String` (default `main`), `headSha String?`, `lastIndexedAt DateTime?`, `ownerId UuidValue`.
  - `HubMember` (`hub_member`): `hubId int`, `userId UuidValue`, `role String` (`owner`|`editor`|`viewer`); unik (`hubId`,`userId`).
  - `Document` (`document`): `hubId int`, `path String` (unik per Hub), `title String`, `area String`, `type String?`, `status String?`, `frontmatter String` (JSON), `tags List<String>`, `blobSha String`, `lastCommitSha String?`, `updatedAt DateTime`.
  - `DocumentLink` (`document_link`): `fromDocId int`, `toPath String`, `toDocId int?`.
  - `BackupRecord` (`backup`): `hubId int`, `objectKey String`, `sizeBytes int`, `createdAt DateTime`, `status String` (`ok`|`failed`), `error String?`.
- Produces (DTO, tanpa tabel): `DocSummary {path, title, area, type?, status?}`, `DocContent {path, content, blobSha, baseSha, readOnlyReason?}`, `SearchHit {path, title, snippet, rank double}`, `HistoryEntry {sha, message, authorName, date}`, `CommitRequest {hubId, path, content, message, description?, baseSha?}`, `CommitResult {status ('ok'|'conflict'|'rejected'), newSha?, latestContent?, latestSha?, reason?}`, `HubChange {hubId, headSha, paths List<String>}`.
- Produces: `Future<void> ensureSearchSchema(Session s)` — `CREATE TABLE IF NOT EXISTS document_fts (document_id bigint primary key references document(id) on delete cascade, hub_id bigint not null, vec tsvector not null)` + indeks GIN `document_fts_vec_idx`. (Kolom `tsvector` tidak didukung model Serverpod; tabel ini turunan, dibuat idempoten saat start.)

- [ ] **Step 1: Tulis test** `models_test.dart`: insert `Hub` + `HubMember` + `Document` → bisa dibaca kembali; `ensureSearchSchema` dua kali tidak error; insert `Document` path sama di Hub sama → melempar.
- [ ] **Step 2:** Tulis `.spy.yaml`, `serverpod generate`, `serverpod create-migration`; jalankan test → PASS (test pertama gagal sebelum model ada).
- [ ] **Step 3: Commit** `feat(server): model Hub, dokumen, tautan, dan backup`

### Task 4: Lapisan git dan antrean per Hub

**Files:**
- Create: `whisker_server/lib/src/git/git_repo.dart`, `whisker_server/lib/src/git/hub_locks.dart`
- Test: `whisker_server/test/unit/git_repo_test.dart` (tanpa DB; remote = repo bare di temp dir)

**Interfaces:**
- Produces:
  - `class GitIdentity { final String name; final String email; }`
  - `class GitRepo { GitRepo(String dir); static Future<GitRepo> clone(String url, String dir, {String? branch}); Future<void> initEmpty(String url, String branch); Future<String?> head(); Future<void> fetch(String url, String branch); Future<String?> remoteHead(String url, String branch) /* ls-remote */; Future<String?> blobAt(String rev, String path); Future<String?> show(String rev, String path); Future<String?> lastCommitFor(String path); Future<void> writeFile(String path, String content); Future<String> commitAll(String message, {required GitIdentity author, required GitIdentity committer}); Future<bool> push(String url, String branch); Future<bool> rebaseOnto(String rev); Future<void> resetHard(String rev); Future<List<String>> changedPaths(String? from, String to); Future<List<String>> listFiles(); Future<List<HistoryEntry>> log(String path, {int limit = 50}); Future<List<int>> archiveZip(); }`
  - `class HubLocks { Future<T> run<T>(int hubId, Future<T> Function() action); }` — antrean FIFO per hubId.
- Semua perintah `git` lewat `Process.run('git', [...], workingDirectory: dir)`; error → `GitException(command, stderr)`. URL dengan token tidak pernah dicetak di pesan error (ganti `//x-access-token:…@` dengan `//***@`).

- [ ] **Step 1: Tulis test gagal**: `clone_commit_push` (clone bare kosong lewat `initEmpty`, tulis file, commit, push → `remoteHead == head`), `blob_and_show`, `changed_paths` (add/modify/delete), `push_rejected_then_rebase` (clone kedua push dulu → push pertama `false` → `rebaseOnto('origin/main')` `true` → push `true`), `log_for_path`, `archive_zip_has_files`, `hub_locks_serializes` (dua aksi pada hubId sama tidak tumpang tindih; hubId berbeda boleh paralel), `error_hides_token`.
- [ ] **Step 2: Jalankan** `dart test test/unit/git_repo_test.dart` → FAIL.
- [ ] **Step 3: Implementasi** sesuai Interfaces.
- [ ] **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): pembungkus git dan antrean per Hub`

### Task 5: Akses remote dan GitHub App

**Files:**
- Create: `whisker_server/lib/src/github/remote_access.dart`, `whisker_server/lib/src/github/github_app.dart`, `whisker_server/lib/src/github/webhook_signature.dart`
- Test: `whisker_server/test/unit/github_app_test.dart`

**Interfaces:**
- Produces:
  - `abstract class RemoteAccess { Future<String> urlFor(Hub hub); }`
  - `class PlainRemoteAccess implements RemoteAccess` → `hub.remoteUrl`.
  - `class GitHubAppRemoteAccess implements RemoteAccess { GitHubAppRemoteAccess({required String appId, required String privateKeyPem, http.Client? client, DateTime Function()? now}); Future<String> installationToken(int installationId); }` → `https://x-access-token:<token>@github.com/<githubRepo>.git` bila `installationId != null`, selain itu `hub.remoteUrl`. JWT RS256 `{iat: now-60, exp: now+540, iss: appId}`; token di-cache sampai `expires_at - 60s`.
  - `bool verifyWebhookSignature(String secret, List<int> body, String? header)` — `sha256=<hex HMAC>` dibandingkan waktu-konstan.
  - `RemoteAccess remoteAccessFromPasswords(Map<String,String> pw)` — GitHub App bila `githubAppId` + `githubAppPrivateKey` ada, selain itu Plain.

- [ ] **Step 1: Tulis test gagal**: `jwt_claims_and_header` (kunci RSA dibuat saat test via `openssl genrsa 2048`; verifikasi dengan kunci publik), `token_cached_until_expiry` (fake `http.Client` dihitung; panggilan kedua sebelum kedaluwarsa tidak memanggil HTTP; setelah lewat memanggil lagi), `url_uses_token`, `plain_uses_remote_url`, `signature_ok_and_bad`.
- [ ] **Step 2: Jalankan** → FAIL. **Step 3: Implementasi.** **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): akses remote lewat GitHub App dan verifikasi webhook`

### Task 6: Indexer

**Files:**
- Create: `whisker_server/lib/src/index/indexer.dart`
- Test: `whisker_server/test/integration/indexer_test.dart`

**Interfaces:**
- Consumes: `GitRepo` (Task 4); `MdDocument`, `extractTitle`, `extractTags`, `extractWikilinks`, `classifyPath` (plan 1).
- Produces: `Future<List<String>> indexHub(Session s, Hub hub, GitRepo repo, {String? fromSha})` — bila `fromSha == null` indeks penuh (hapus dokumen yang tidak ada lagi), selain itu hanya `changedPaths(fromSha, head)`; hanya file `.md`; menulis `Document`, `DocumentLink` (re-resolve `toDocId` seluruh Hub: target cocok bila sama dengan nama file tanpa `.md` atau path tanpa `.md`), dan `document_fts` dengan `setweight(to_tsvector('simple', title),'A') || setweight(to_tsvector('simple', tags),'B') || setweight(to_tsvector('simple', body),'C')`; set `hub.headSha`, `hub.lastIndexedAt`. Mengembalikan path yang berubah.

- [ ] **Step 1: Tulis test gagal**: `full_index` (repo berisi `PKM/ADR/ADR-001 - A.md` ber-frontmatter `type: adr`, `status: accepted`, `tags: [x]`, dan `B.md` yang menautkan `[[ADR-001 - A]]` → 2 dokumen; area/type/status benar; link `toDocId` terisi), `incremental_index` (ubah B, hapus A → A terhapus, link `toDocId` null), `fts_row_written` (`select count(*) from document_fts` == jumlah dokumen).
- [ ] **Step 2: Jalankan** → FAIL. **Step 3: Implementasi.** **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): indeks dokumen, tautan, dan full-text`

### Task 7: HubEndpoint — buat, impor, indeks ulang, daftar

**Files:**
- Create: `whisker_server/lib/src/hub/hub_service.dart` (data dir, `HubLocks` tunggal, `RemoteAccess` tunggal, `GitRepo repoFor(Hub)`, `requireMember(Session, hubId, {bool write})`), `whisker_server/lib/src/hub/hub_endpoint.dart`, `whisker_server/lib/src/hub/vault_import.dart`
- Test: `whisker_server/test/integration/hub_endpoint_test.dart`

**Interfaces:**
- Produces (endpoint `hub`, `requireLogin = true`):
  - `Future<List<Hub>> list(Session)` — Hub tempat user jadi member.
  - `Future<Hub> create(Session, String name, {String? githubRepo, String? remoteUrl, int? installationId, String defaultBranch = 'main'})` — slug dari nama (huruf kecil, `-`); `remoteUrl` default `https://github.com/<githubRepo>.git`; clone (atau `initEmpty` bila remote kosong); member `owner`; indeks penuh.
  - `Future<Hub> importVault(Session, int hubId, ByteData zip)` — ekstrak (`archive`) ke clone kerja dengan aturan buang di Global Constraints, strip folder akar tunggal, abaikan entri yang keluar dari folder; commit `chore: impor vault`; push; indeks penuh; broadcast.
  - `Future<Hub> reindex(Session, int hubId)`.
- `HubService.dataDir` dari env `WHISKER_DATA_DIR`, default `.data`.
- Non-member → `NotAuthorizedException` (exception Serverpod `.spy.yaml` `WhiskerException {message}`).

- [ ] **Step 1: Tulis test gagal** (remote = repo bare temp, `remoteUrl` = path): `create_lists_for_owner_only`, `import_vault_commits_and_indexes` (zip berisi `.obsidian/x`, `a.md`, `.gitignore` berisi `secret.md` + `secret.md` → hanya `a.md` & `.gitignore` di remote; commit `chore: impor vault`), `import_strips_root_and_blocks_zip_slip`, `non_member_rejected`.
- [ ] **Step 2: Jalankan** → FAIL. **Step 3: Implementasi** + `serverpod generate`. **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): endpoint Hub untuk buat, impor vault, dan indeks ulang`

### Task 8: DocEndpoint — pohon, baca, cari, backlink, riwayat, commit

**Files:**
- Create: `whisker_server/lib/src/doc/doc_endpoint.dart`, `whisker_server/lib/src/doc/commit_service.dart`, `whisker_server/lib/src/doc/safe_path.dart`
- Test: `whisker_server/test/integration/doc_endpoint_test.dart`

**Interfaces:**
- Consumes: `HubService`, `GitRepo`, `indexHub`, `checkHubRules`, `readOnlyReason`.
- Produces (endpoint `doc`, `requireLogin = true`):
  - `tree(Session, int hubId) → List<DocSummary>` urut path.
  - `read(Session, int hubId, String path) → DocContent` (`baseSha` = `lastCommitFor(path)`).
  - `search(Session, int hubId, String query, {int limit = 20}) → List<SearchHit>` — `websearch_to_tsquery('simple', q)`, `ts_rank`, snippet `ts_headline` dari judul+tag (isi tidak disimpan di DB) — snippet isi diambil dari file di clone: baris pertama yang memuat salah satu kata kueri, maks 160 karakter.
  - `backlinks(Session, int hubId, String path) → List<DocSummary>`.
  - `history(Session, int hubId, String path) → List<HistoryEntry>`.
  - `commit(Session, CommitRequest req) → CommitResult` — alur spec 4.2 di dalam `HubLocks.run`: fetch → `blobAt('origin/<branch>', path)` vs `blobAt(baseSha, path)` (file baru: keduanya null) → beda: `conflict` + `latestContent`/`latestSha`; sama: `resetHard(origin/<branch>)`, cek `checkHubRules` (gagal → `rejected` + `reason`), tulis, commit (pesan = `message` + `\n\n` + `description` bila ada; kosong → `docs(<area>): update <judul>`), push; ditolak → `rebaseOnto` + push sekali lagi; gagal lagi → `resetHard(origin)` + `WhiskerException`; sukses → `indexHub(fromSha: lama)`, broadcast, `ok` + `newSha`.
  - `safePath(String path)` → lempar bila absolut, mengandung segmen `..`, atau tidak berakhiran `.md`.
- Author commit: nama/email dari profil pengguna auth Serverpod (`UserProfile`), fallback `Whisker User <user-<uuid>@users.whisker.local>`.

- [ ] **Step 1: Tulis test gagal**: `tree_and_read`, `search_ranks_title_first` (kata di judul dok A dan di isi dok B → A di atas), `backlinks`, `commit_ok_updates_remote_and_index`, `commit_conflict_when_file_changed_remotely`, `remote_advanced_other_file_rebases`, `adr_accepted_rejected`, `rejects_unsafe_paths`, `concurrent_commits_serialized`, `default_message`.
- [ ] **Step 2: Jalankan** → FAIL. **Step 3: Implementasi** + generate. **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): endpoint dokumen dengan commit dan deteksi konflik`

### Task 9: Notifikasi, webhook, rekonsiliasi

**Files:**
- Create: `whisker_server/lib/src/sync/hub_events.dart`, `whisker_server/lib/src/sync/remote_sync.dart`, `whisker_server/lib/src/sync/webhook_route.dart`
- Modify: `whisker_server/lib/src/hub/hub_endpoint.dart` (tambah `watch`)
- Test: `whisker_server/test/integration/sync_test.dart`

**Interfaces:**
- Produces:
  - `Future<void> broadcastChange(Session s, HubChange c)` → `s.messages.postMessage('hub-${c.hubId}', c)`.
  - `HubEndpoint.watch(Session, int hubId) → Stream<HubChange>` (member saja).
  - `Future<HubChange?> syncFromRemote(Session s, Hub hub)` — di antrean Hub: `fetch` → bila `origin` == `headSha` → `null`; selain itu `resetHard(origin/<branch>)` → `indexHub(fromSha: headSha)` → broadcast → kembalikan perubahan.
  - `Future<int> reconcileAll(Session s)` — untuk tiap Hub `remoteHead` ≠ `headSha` → `syncFromRemote`; kembalikan jumlah Hub yang disinkron.
  - `Future<(int, String)> handleGithubWebhook(Session s, Map<String,String> headers, List<int> body, String secret)` → `(401,…)` tanda tangan salah; `(202,'ignored')` event bukan `push` atau repo tak dikenal; `(200,'synced')`. `WebhookRoute` (POST `/webhooks/github`) membungkus fungsi ini.

- [ ] **Step 1: Tulis test gagal**: `sync_after_external_push` (clone lain push file baru → `syncFromRemote` → dokumen baru terindeks, `HubChange.paths` memuatnya), `sync_noop_when_same`, `reconcile_counts`, `webhook_rejects_bad_signature`, `webhook_push_syncs`, `watch_receives_change` (stream menerima `HubChange` setelah commit).
- [ ] **Step 2: Jalankan** → FAIL. **Step 3: Implementasi** + generate. **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): webhook push, rekonsiliasi, dan siaran perubahan Hub`

### Task 10: Backup harian

**Files:**
- Create: `whisker_server/lib/src/backup/backup_store.dart` (`abstract class BackupStore { Future<void> put(String key, List<int> bytes); Future<List<String>> list(String prefix); Future<void> delete(String key); }`, `MinioBackupStore` dari passwords `s3Endpoint`, `s3AccessKey`, `s3SecretKey`, `s3Bucket`, `s3Region?`), `whisker_server/lib/src/backup/backup_job.dart`
- Test: `whisker_server/test/integration/backup_test.dart`

**Interfaces:**
- Produces: `Future<bool> runDailyBackup(Session s, BackupStore store, DateTime nowUtc)` — tanggal kunci = tanggal WIB (UTC+7) dari `nowUtc`; per Hub: `archiveZip` (di antrean Hub) → `put('backups/<slug>/<YYYY-MM-DD>.zip')` → `BackupRecord ok` → hapus kunci di prefix Hub dengan tanggal < hari ini − 6 hari (simpan 7); gagal → `BackupRecord failed` dan tidak menghapus apa pun untuk Hub itu. Kembalikan `true` bila semua Hub sukses.
- `Duration untilNextBackup(DateTime nowUtc)` → durasi ke 19.00 UTC berikutnya.

- [ ] **Step 1: Tulis test gagal** dengan `InMemoryBackupStore` (di file test): `writes_zip_and_record`, `retention_keeps_seven` (isi 9 kunci tanggal lama → setelah run tersisa 7 termasuk hari ini), `failure_keeps_old` (store `put` melempar → record `failed`, kunci lama utuh), `until_next_backup`.
- [ ] **Step 2: Jalankan** → FAIL. **Step 3: Implementasi.** **Step 4: Jalankan** → PASS.
- [ ] **Step 5: Commit** `feat(server): backup zip harian ke object storage dengan retensi 7 hari`

### Task 11: Wiring server dan dokumentasi

**Files:**
- Modify: `whisker_server/lib/server.dart`, `whisker_server/Dockerfile` (pasang `git`), `whisker_server/config/*.yaml` bila perlu, `Guides/Serverpod.md` (kunci passwords baru, env test, menjalankan lokal), `CLAUDE.md` status
- Test: `whisker_server/test/integration/wiring_test.dart`

**Interfaces:**
- `server.dart`: IdP GitHub (`GitHubIdpConfigFromPasswords` bila `githubClientId` ada) + email (dev); `ensureSearchSchema` saat start; `WebhookRoute` di `/webhooks/github` bila `githubWebhookSecret` ada; `Timer.periodic(5 menit, reconcileAll)`; timer backup `untilNextBackup` lalu tiap 24 jam, gagal → ulang tiap jam (bila kredensial S3 ada). Timer dipilih alih-alih future call: satu instance VPS, tidak butuh persistensi jadwal.

- [ ] **Step 1: Tulis test** `wiring_test`: `ensureSearchSchema` + `reconcileAll` tanpa Hub → 0 dan tidak error.
- [ ] **Step 2: Implementasi wiring**; `dart analyze` bersih; seluruh suite `dart test` → PASS.
- [ ] **Step 3: Commit** `feat(server): wiring auth, webhook, rekonsiliasi, dan backup`
