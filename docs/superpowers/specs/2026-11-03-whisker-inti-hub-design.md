---
title: Whisker — Inti Hub (sub-proyek 1)
status: draf, menunggu review user
date: 2026-11-03
---

# Whisker — Inti Hub (sub-proyek 1)

## 1. Tujuan dan pemahaman

Whisker adalah second brain terpusat lintas device dan lintas proyek. Satu proyek = satu **Hub**,
berisi markdown bergaya vault Obsidian (contoh nyata: `wiki-angkasa`). Seperti Hubzoid, Hub adalah
**folder file markdown**: Claude Code di PC membacanya langsung dengan grep, sehingga Hub harus ada
sebagai file lokal dan **sinkron dua arah** dengan aplikasi.

Whisker dipecah menjadi empat sub-proyek, masing-masing dengan spec → plan → implementasi sendiri:

1. **Inti Hub** (dokumen ini): server, auth, sinkron git, impor vault, baca/edit/cari dokumen, backup,
   aplikasi tiga panel, sinkron folder lokal di desktop.
2. MCP server + plugin `whisker` (termasuk hook `git pull` di SessionStart dan semantic search).
3. Tracking (Plan/Task, Test, Confirmation dengan human gate, Question, Dashboard).
4. CI/release 6 platform (menunggu daftar extension dari agent Retail).

### Kriteria sukses sub-proyek 1

- Vault `wiki-angkasa` bisa diimpor menjadi Hub yang terhubung ke repo GitHub private.
- Dokumen bisa dibaca, dicari (full-text), dan diedit di `appflowy_editor`, lalu di-commit + push
  lewat dialog bergaya GitHub.
- Perubahan yang di-push Claude Code dari PC muncul di aplikasi tanpa reload manual.
- Aplikasi desktop menjaga folder lokal tetap sinkron.
- Membuka lalu menyimpan dokumen tanpa edit menghasilkan file yang **byte-identik**.
- Backup `.zip` harian per Hub ada di Object Storage IDCloudHost, maksimal 7 hari.

## 2. Keputusan (hasil brainstorming 2026-11-03)

| topik | keputusan |
| --- | --- |
| Pengguna MVP | single user (owner) lintas device; model data siap untuk peran tim (`editor`, `viewer`) |
| Sumber kebenaran | **Git-first**: repo GitHub = kebenaran; server memegang clone kerja; Postgres = indeks yang bisa dibangun ulang |
| Remote git | repo **GitHub private** per Hub (untuk sekarang); lapisan remote dibuat sebagai antarmuka |
| Masuk konten | impor vault Obsidian (zip) + ekspor balik = repo itu sendiri |
| Sinkron lokal | aplikasi desktop mengelola clone (auto pull) **dan** hook plugin `git pull` (sub-proyek 2) |
| Edit | `appflowy_editor` (WYSIWYG) dengan codec markdown Whisker |
| Simpan | dialog **Commit changes** (pesan + deskripsi opsional) → commit + push langsung |
| Pencarian | full-text Postgres (judul, isi, tag), indeks ulang tiap push |
| State & routing | Riverpod + `go_router` |
| Auth | login GitHub (IdP Serverpod) + GitHub App "Whisker" untuk akses repo dan webhook |
| Hosting | Docker di Cloud VPS IDCloudHost (Serverpod + PostgreSQL + `git`) |
| Backup | `.zip` harian per Hub ke Object Storage IDCloudHost (S3-compatible), retensi 7 hari dikelola Whisker |
| Layout | tiga panel (pohon Hub · editor · Properties/Backlinks/Riwayat); ponsel: sheet + bottom nav |

Mockup: [Whisker — Layout UI](https://claude.ai/artifact/MozdMru2QfRdFxMGTjrQQP).

## 3. Arsitektur dan komponen

### Server (`whisker_server`)

| modul | tanggung jawab | bergantung pada |
| --- | --- | --- |
| `auth` | login GitHub, sesi Serverpod | IdP GitHub Serverpod |
| `github` | token instalasi GitHub App (berumur pendek, di-cache), panggilan REST, verifikasi tanda tangan webhook | kunci privat App di `passwords.yaml` |
| `git` | membungkus `git` sistem: clone, fetch, reset, commit, push, log, archive di `/data/hubs/<hub-id>`; **antrean per Hub** (satu operasi git per Hub sekaligus) | `github` (kredensial push) |
| `hub` | daftar/buat Hub, hubungkan repo, impor vault zip | `git`, `index` |
| `index` | parse markdown (frontmatter, judul, wikilink, tag, area/tipe) → tabel `document`, `document_link`, `tsvector`; dijalankan untuk file yang berubah antara `headSha` lama dan baru | `git` |
| `doc` | baca isi, daftar pohon, cari, backlink, riwayat file, **commit**; menegakkan aturan Hub | `git`, `index` |
| `webhook` | endpoint `POST /webhooks/github` (web server Relic) untuk event `push` | `github`, `git`, `index` |
| `backup` | future call harian: `git archive --format=zip` → unggah S3 → catat → hapus > 7 hari | `git`, S3 client |
| `notify` | stream Serverpod "Hub berubah" (hubId, headSha baru, path berubah) ke aplikasi | – |

### Aplikasi (`whisker_flutter`)

| bagian | isi |
| --- | --- |
| `app/` | `FTheme` calico light/dark, `go_router`, shell tiga panel / ponsel |
| `features/hub_tree/` | pohon dokumen, badge Confirmation `open`, dokumen baru dari template `_Format/` |
| `features/editor/` | `appflowy_editor`, codec markdown, blok kustom, draf lokal, banner ADR terkunci |
| `features/commit/` | dialog Commit changes, tampilan konflik (diff, muat ulang, gabung manual) |
| `features/inspector/` | Properties (form frontmatter), Backlinks, Riwayat |
| `features/search/` | palet pencarian `Ctrl K` |
| `features/local_sync/` | **desktop saja**: pilih folder, clone semua Hub, `git pull --ff-only` saat notifikasi, tanda "ada perubahan lokal belum di-push" |
| `markdown_codec/` (paket Dart terpisah) | parse/serialize markdown ↔ dokumen editor; dipakai juga oleh `index` di server |

`markdown_codec` dibuat sebagai paket Dart murni di root repo supaya server (indeks, wikilink) dan
aplikasi (editor) memakai parser yang sama.

## 4. Alur data

### 4.1 Impor vault
1. User membuat repo GitHub private kosong, memasang GitHub App Whisker di repo itu.
2. Di aplikasi: "Hub baru" → pilih repo → unggah zip vault.
3. Server mengekstrak ke clone kerja, membuang `.obsidian/`, `.git/` bawaan zip, `.claude/settings.local.json`,
   dan file yang cocok `.gitignore` vault; commit `chore: impor vault` → push → indeks penuh.

### 4.2 Edit → commit → push
1. Membuka dokumen: server mengirim isi, `blobSha`, dan `baseSha` (commit terakhir yang menyentuh file).
2. User mengedit; draf disimpan lokal di perangkat.
3. **Commit changes** → kirim `{hubId, path, content, message, description?, baseSha}`.
4. Di antrean Hub, server: `fetch` → bandingkan blob file di `origin/<branch>` dengan blob di `baseSha`.
   - Sama → tulis file, cek aturan Hub, commit (author = user, committer = Whisker), push, indeks
     ulang, broadcast, balas `{status: ok, newSha}`.
   - Beda → balas `{status: conflict, latestContent, latestSha}`; tidak ada yang ditulis.
   - Push ditolak (remote maju di file lain) → `rebase` ke remote, push ulang sekali.
5. Pesan commit default: `docs(<area>): update <judul>`; bisa diubah user.

### 4.3 Push dari PC
Webhook `push` → verifikasi tanda tangan → (antrean Hub) `fetch` + `reset --hard origin/<branch>` →
indeks file yang berubah → broadcast. Rekonsiliasi setiap 5 menit: `git ls-remote` vs `headSha`.

### 4.4 Desktop `local_sync`
Saat broadcast diterima (atau saat aplikasi dibuka): untuk tiap Hub, `git pull --ff-only` di folder
lokal. Bila folder punya commit/perubahan lokal yang belum di-push → jangan sentuh, tampilkan status
"perlu push/merge manual".

### 4.5 Backup
Setiap hari 02.00 WIB: per Hub `git archive --format=zip HEAD` → `backups/<hub-slug>/<YYYY-MM-DD>.zip`
di bucket IDCloudHost → catat di tabel `backup` → hapus objek > 7 hari **hanya bila backup hari ini
sukses**.

## 5. Model data

Tabel auth/pengguna memakai modul auth Serverpod.

| tabel | kolom utama | sumber |
| --- | --- | --- |
| `hub` | `name`, `slug`, `githubRepo`, `installationId`, `defaultBranch`, `headSha`, `lastIndexedAt`, `ownerId` | primer |
| `hub_member` | `hubId`, `userId`, `role` (`owner`; `editor`/`viewer` disiapkan) | primer |
| `document` | `hubId`, `path` (unik per Hub), `title`, `area`, `type`, `status`, `frontmatter` (JSON), `tags`, `blobSha`, `lastCommitSha`, `updatedAt`, `searchVector` (`tsvector`, indeks GIN) | turunan repo |
| `document_link` | `fromDocId`, `toPath`, `toDocId?` | turunan repo |
| `backup` | `hubId`, `objectKey`, `sizeBytes`, `createdAt`, `status` | primer |

- Isi markdown **tidak** disimpan di Postgres; dibaca dari clone kerja.
- Riwayat file dari `git log -- <path>`, tidak ditabelkan.
- `area`/`type` diturunkan dari konvensi folder vault (mis. `PKM/ADR/` → `knowledge`/`adr`,
  `Confirmation/` → `tracking`/`confirmation`); frontmatter `type:` menang bila ada.
- Konfigurasi `full-text`: konfigurasi `simple` (campuran Indonesia–Inggris), bobot judul > tag > isi.

## 6. Editor dan UI

### Codec markdown
- Frontmatter YAML dipisah ke Properties; body dikonversi ke dokumen `appflowy_editor`.
- Blok kustom: wikilink `[[target|alias]]` (inline, autocomplete dari `document`), callout
  `> [!type] judul`, Mermaid (pratinjau + kode), tabel.
- Konstruksi yang tidak dikenal → **raw block** yang disimpan verbatim.
- Serializer menyimpan gaya asli (penanda list, fence, baris kosong) agar dokumen tanpa edit
  **byte-identik**; bila round-trip suatu file tidak identik, file dibuka mode baca saja + peringatan.

### Aturan Hub di MVP
- ADR `status: accepted` → editor baca saja; hanya `status` dan `superseded_by` yang bisa diubah
  (ditegakkan juga di server).
- Path `_LLM-Wiki/` dan `_Format/` tidak bisa diedit dari editor biasa (mirror/template).
- Aturan tracking lain (human gate Confirmation, komplain Task) masuk sub-proyek 3.

### UI
- Desktop/web: tiga panel sesuai mockup; ponsel: panel kiri/kanan jadi sheet, bottom nav
  Beranda/Dokumen/Cari/Tracking.
- Warna hanya dari token `design/tokens/whisker.tokens.json`; light/dark; WCAG 2.2 AA; target sentuh ≥ 44 dp.
- Avatar pengguna dari style DiceBear `whisker-critters` (seed = id pengguna).

## 7. Penanganan error

| kasus | perilaku |
| --- | --- |
| konflik edit | status `conflict`, draf lokal tetap; UI diff + muat ulang / gabung manual |
| push gagal | commit lokal di-reset; refresh token App; coba ulang sekali; lalu error jelas ke UI |
| webhook terlewat | rekonsiliasi 5 menit via `ls-remote` |
| indeks basi/rusak | endpoint admin "indeks ulang Hub" (bangun ulang dari repo) |
| backup gagal | status `failed`, coba ulang tiap jam; backup lama tidak dihapus |
| offline | draf lokal; commit hanya saat online (commit offline di luar MVP) |
| round-trip tidak identik | dokumen dibuka baca saja + peringatan, dilaporkan ke log |

## 8. Testing

- **Server**: test endpoint dengan test tools Serverpod; remote GitHub diganti **repo bare lokal**.
  Skenario: commit normal, konflik, remote maju di file lain, webhook, rekonsiliasi, aturan ADR, backup
  (S3 di-mock).
- **`markdown_codec`**: round-trip byte-identik untuk **setiap** file `wiki-angkasa` (fixture), plus kasus
  frontmatter, wikilink, callout, Mermaid, tabel, raw block.
- **Aplikasi**: widget test dialog commit, pohon Hub, banner ADR terkunci, inspector; screenshot
  light/dark ponsel + desktop.
- **`local_sync`**: test integrasi dua clone + satu remote bare (fast-forward, perubahan lokal dijaga).

## 9. Di luar cakupan sub-proyek 1

MCP server dan plugin, semantic search, tracking (Plan/Task/Confirmation workflow, Dashboard), CI/release
6 platform, peran tim, remote selain GitHub, commit offline, kolaborasi real-time.
