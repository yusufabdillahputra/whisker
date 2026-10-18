# DESIGN.md — Whisker

Acuan visual UI Whisker (web + mobile). Sumbernya **canvas Claude Design** milik owner; berkas ini
menuangkan nilainya ke bentuk yang dipakai kode (token CSS, kelas Tailwind, komponen shadcn/ui).
Bila canvas dan berkas ini berbeda, canvas menang dan berkas ini diperbarui.

| Canvas | Artboard yang dibaca | Versi dibaca |
| --- | --- | --- |
| Whisker — Project Picker & App Shell (`claude.ai/artifact/JLwenVXjGnAnmaQVrLzyaM`) | `Main` (pemilih Project), `Shell` (sidebar-07), `AccountView`, `AddProjectDialog`, `McpConnect`, `ProgressDashboard`, `MobileShell`, `MobileSidebar`, `PickerEmpty`, `HandoverView` | 2026-10-18 |
| Whisker Logo (`claude.ai/artifact/SnGowrQkcjb84bPM1aKdfT`) | `Main` (logo utama), `Mark` (variasi mark) | 2026-10-18 |

Nilai di bawah disalin dari canvas. Bagian yang **tidak digambar** di canvas ditandai
**turunan** (disusun dari token canvas) atau **terbuka** (belum diputuskan).

---

## 1. Prinsip

- **Tinta dulu, aksen hemat.** Warna utama UI adalah ink `#14161B` (terang) / `#F4F5F7` (gelap).
  Aksen `#FF7A45` hanya untuk sorotan kecil: titik hidung logo, titik "Terakhir dibuka", centang item
  aktif, ring fokus, ring avatar terpilih, border item terpilih, batang "Berjalan".
- **Tombol utama = ink, bukan aksen.** Teks putih di atas `#FF7A45` hanya ±2,6:1 (gagal WCAG AA);
  putih di atas `#14161B` ±18:1.
- **Tiga tema**: Terang, Gelap, Sistem (ikut `prefers-color-scheme`).
- **Target sentuh mobile ≥ 44×44 px**, jarak antar-target ≥ 8 px.
- **Label badge Title Case** (huruf awal tiap kata kapital), mis. "Fullstack (Monolith)", "Terakhir Dibuka".
- Bahasa UI: Indonesia; istilah produk tetap ("Project", "Tokens", "Add Project", "Admin Users").

## 2. Token warna

Sumber: fungsi `wkTheme(dark)` di semua artboard canvas (nilainya identik antar-artboard).

| Token canvas | Peran | Terang | Gelap |
| --- | --- | --- | --- |
| `bg` | latar halaman | `#F4F5F7` | `#0E1014` |
| `surface` | kartu, panel, header, dialog, menu | `#FFFFFF` | `#16191F` |
| `sidebar` | latar sidebar | `#FAFAFB` | `#121418` |
| `text` | teks utama (ink) | `#14161B` | `#F4F5F7` |
| `muted` | teks sekunder, ikon non-aktif | `#5A606B` | `#A3A9B4` |
| `border` | garis pemisah, batas komponen, input | `#E3E5EA` | `#2A2F38` |
| `dashed` | border putus-putus kartu "Add Project" | `#B8BCC6` | `#4A515E` |
| `hover` | latar hover / item aktif / input read-only | `#EEF0F3` | `#1E222A` |
| `tile` / `tileFg` | ubin ikon project, avatar inisial | `#14161B` / `#F4F5F7` | `#F4F5F7` / `#14161B` |
| `primaryBg` / `primaryText` | tombol utama | `#14161B` / `#FFFFFF` | `#F4F5F7` / `#14161B` |
| `codeBg` / `codeFg` | blok kode, token sekali tampil | `#14161B` / `#F4F5F7` | `#0B0D10` / `#E6E8EC` |
| `danger` | teks error, aksi destruktif | `#B42318` | `#FF8A80` |
| `okBg` / `okFg` | badge status aktif | `#DCFCE7` / `#14532D` | `#12321F` / `#86EFAC` |
| `offBg` / `offFg` | badge status non-aktif | `#EEF0F3` / `#5A606B` | `#2A2F38` / `#A3A9B4` |
| `overlay` | latar di balik dialog | `rgba(20,22,27,0.45)` | `rgba(0,0,0,0.6)` |
| accent | aksen brand (dipakai hemat) | `#FF7A45` | `#FF7A45` |
| link | tautan teks / hover | `#B4471A` / `#8A3412` | `#FDBA74` / `#FED7AA` (turunan, Confirmation 10) |

### Pemetaan ke variabel CSS shadcn/ui

Ditulis di `frontend/src/styles/globals.css` (`:root` = Terang, `.dark` = Gelap). Catatan penting:
di shadcn, `accent` adalah **latar hover** (bukan aksen brand); aksen brand memakai token `brand`.

| Variabel | Token canvas |
| --- | --- |
| `--background` | `bg` |
| `--foreground`, `--card-foreground`, `--popover-foreground`, `--secondary-foreground`, `--accent-foreground` | `text` |
| `--card`, `--popover` | `surface` |
| `--primary` / `--primary-foreground` | `primaryBg` / `primaryText` |
| `--secondary`, `--muted`, `--accent` | `hover` |
| `--muted-foreground` | `muted` |
| `--destructive` | `danger` |
| `--border`, `--input` | `border` |
| `--ring` | accent `#FF7A45` (ring fokus) |
| `--brand` | accent `#FF7A45` |
| `--sidebar` | `sidebar` |
| `--tile` / `--tile-foreground` | `tile` / `tileFg` |
| `--code` / `--code-foreground` | `codeBg` / `codeFg` |
| `--dashed`, `--overlay` | `dashed`, `overlay` |

Kontras (rumus luminans relatif WCAG): teks utama dan muted lolos AA di kedua tema
(muted terang ±5,8:1 di `bg`; muted gelap ±7,5:1 di `surface`).
Link gelap (canvas hanya merender tautan di tema terang): `#B4471A` hanya ±3,5:1 di `#0E1014`, maka
`.dark` memakai orange-300 `#FDBA74` (±11,3:1 di `bg`, ±10,4:1 di `surface`) dan hover orange-200
`#FED7AA` (±14,1:1 di `bg`) — skala Tailwind yang sama dengan aturan badge Tipe gelap (`-300`).
Link terang lolos AA: `#B4471A` ±5,4:1 di `surface`, ±5,0:1 di `bg`.

## 3. Tipografi

| Peran | Font | Ukuran / berat | Catatan canvas |
| --- | --- | --- | --- |
| Wordmark header | Sora | 20 px / 600, `letter-spacing: -0.03em` | header pemilih Project |
| Judul halaman (h1) | Sora | 28 px / 600, `-0.03em` | "Projects", "Dashboard" |
| Judul section / dialog (h2) | Sora | 20 px / 600, `-0.02em` | "Add Project", "Profil", "Keamanan" |
| Lead / deskripsi halaman | Figtree | 15 px / 400, warna `muted` | "Pilih project untuk mulai bekerja." |
| Nama kartu | Figtree | 17 px / 600 | kartu project |
| Label, kontrol, item menu | Figtree | 14 px / 600 (label), 14–15 px / 500–600 (tombol) | |
| Meta, hint, error | Figtree | 13 px / 400 | hint field, `role="alert"` |
| Badge | Figtree | 12 px / 600 | |
| Slug, kode, hash | `ui-monospace, SFMono-Regular, Menlo, monospace` | 13 px | `/p/{slug}`, hash commit |

- Font family: judul `Sora, Figtree, sans-serif`; isi `Figtree, system-ui, sans-serif`.
- Berat yang dimuat: Sora **600**; Figtree **400 / 500 / 600**.
- **Self-host** lewat paket `@fontsource/sora` + `@fontsource/figtree`, tanpa CDN
  (asumsi Q19 — canvas memakai Google Fonts hanya untuk pratinjau).
- Input di mobile memakai teks 16 px (`text-base`) agar Safari iOS tidak zoom.

## 4. Spacing

Grid 4 px, ritme 8 px. Satu skala (kelas Tailwind default, 1 unit = 4 px):

| Token | px | Tailwind | Peran utama |
| --- | --- | --- | --- |
| `space-3xs` | 2 | `0.5` | hairline, padding segmented control |
| `space-2xs` | 4 | `1` | jarak terkecil di komponen rapat, padding menu |
| `space-xs` | 6 | `1.5` | label → field, judul → deskripsi |
| `space-sm` | 8 | `2` | ikon ↔ label, antar-item dalam grup, tombol berdampingan |
| `space-md` | 12 | `3` | antar-item sedikit lega, ikon berderet di mobile |
| `space-lg` | 16 | `4` | margin tepi mobile, padding kartu mobile, gap Dialog |
| `space-xl` | 24 | `6` | padding kartu / Dialog web, gap grid desktop |
| `space-2xl` | 32 | `8` | antar-section mobile, padding-x halaman desktop |
| `space-3xl` | 48 | `12` | antar-section desktop, padding-top halaman desktop |
| `space-4xl` | 64 | `16` | jeda besar (hero, empty state, padding-bottom halaman) |

Aturan proximity: jarak dalam grup < antar-grup < antar-section; padding kartu > jarak antar-kartu
tidak dipakai — kartu `p-6` dengan gap grid `gap-6` (web), `p-4` / `gap-4` (mobile).

## 5. Bentuk, bayangan, fokus

| Elemen | Nilai |
| --- | --- |
| Radius badge, item menu | 6 px |
| Radius tombol, input, segmen toggle | 8 px |
| Radius ubin ikon, menu, wadah segmented control | 10 px |
| Radius kartu, dialog | 14 px (dialog peringatan Shell: 16 px) |
| Radius pill (avatar, chip filter, tombol akun) | 999 px |
| Bayangan menu | `0 16px 32px rgba(20,22,27,0.14)` |
| Bayangan dialog | `0 24px 48px rgba(20,22,27,0.18)` |
| Bayangan segmen aktif | `0 1px 2px rgba(20,22,27,0.14)` |
| Ring fokus | `outline: 2px solid #FF7A45; outline-offset: 2px` (`:focus-visible`); aturan dasar di `globals.css`, komponen `ui/*` tidak menimpanya (tanpa ring shadcn 3px / `outline-none`) |
| Kartu hover | border berubah ke `#FF7A45`, `translateY(-1px)`, transisi 150 ms |

## 6. Komponen

| Komponen | Web | Mobile |
| --- | --- | --- |
| Button utama | latar `primary`, teks `primary-foreground`, `h-9 px-4`, 14 px / 600, radius 8 | `h-11` (44 px), 15 px |
| Button sekunder | border `border`, latar transparan, teks `text` | `h-11` |
| Button danger | seperti sekunder, teks `danger` | `h-11` |
| Input | `h-9 px-3`, border `border`, latar `bg`, radius 8 | `h-11`, `text-base` |
| Label | 14 px / 600, jarak ke field 6–8 px | sama |
| Card | latar `surface`, border `border`, radius 14, `p-6 gap-6` | `p-4 gap-4` |
| Dialog | `p-6 gap-6`, `max-w-[480px]`, radius 14, overlay `overlay` | margin 16 px |
| Header app | `h-14` (56 px), `px-8`, border-bottom `border`, latar `surface` | `h-14` + safe area, `px-2` |
| Menu akun | lebar 224 px, `p-1`, item `min-h-10 px-2 gap-2`, radius 10; item: Tokens, Account, Admin Users (admin), Lisensi pihak ketiga (turunan), Logout | item 44 px |
| Tombol akun | pill `h-11`, avatar 34 px + chevron | sama |
| Kartu project | `min-h-[164px] p-6`, radius 14, ubin ikon 44 px radius 10 | satu kolom |
| Sidebar (sidebar-07) | lebar `16rem`, ikon `3rem`, item `h-8 gap-2 px-2` | di Sheet, item `h-11` |

### Theme toggle

Segmented control tiga tombol ikon (Lucide `Sun` / `Moon` / `Monitor`), label aksesibel
**"Terang" / "Gelap" / "Sistem"**; satu pilihan aktif (`aria-pressed` / `data-state="on"`).

- Wadah: `p-0.5 gap-0.5`, radius 10, border `border`, latar `bg`.
- Segmen: 40×40 px (pemilih Project), radius 8; aktif = latar `surface` + teks `text` + bayangan
  segmen aktif; non-aktif = transparan + teks `muted`. Ikon 18 px, stroke 2.
- Di mobile segmen 44×44 px.
- Penempatan: header pemilih Project dan app shell (web), footer sidebar (mobile), pojok kanan atas
  halaman Login (turunan).

## 7. Badge

Bentuk badge data (canvas `ProgressDashboard` / `HandoverView`): tinggi 22 px, `px-2`, radius 6,
12 px / 600, `white-space: nowrap`. Varian **mono** (hash, id, tag teknis) memakai font mono 500.
Badge status akun/token (canvas `AccountView`): tinggi 24 px, pill, 12 px / 600.

### Palet (`wkPal`) — `[latar, teks, solid]`

| Hue | Terang | Gelap |
| --- | --- | --- |
| sky | `#E0F2FE` / `#075985` / `#0284C7` | `#0C2A4A` / `#7DD3FC` / `#38BDF8` |
| violet | `#EDE9FE` / `#5B21B6` / `#7C3AED` | `#2E1A4F` / `#C4B5FD` / `#A78BFA` |
| amber | `#FEF3C7` / `#78350F` / `#D97706` | `#3A2A12` / `#FCD34D` / `#FBBF24` |
| green | `#DCFCE7` / `#14532D` / `#16A34A` | `#0F3A26` / `#86EFAC` / `#4ADE80` |
| indigo | `#E0E7FF` / `#3730A3` / `#4F46E5` | `#1E1B4B` / `#A5B4FC` / `#818CF8` |
| orange | `#FFEDD5` / `#9A3412` / `#FF7A45` | `#431407` / `#FDBA74` / `#FF7A45` |
| red | `#FEE2E2` / `#991B1B` / `#DC2626` | `#3A1616` / `#FCA5A5` / `#F87171` |
| gray | `#EEF0F3` / `#3B4049` / `#C9CED6` | `#232830` / `#C9CED6` / `#4A515E` |

"Solid" dipakai untuk isian batang progres / meteran.

Di kode, pasangan `[latar, teks]` hue yang sudah dipakai menjadi token `--badge-<hue>` /
`--badge-<hue>-foreground` di `globals.css` (kelas `bg-badge-sky text-badge-sky-foreground`, dst.);
saat ini sky, green, amber, red, gray. Hue lain ditambahkan dengan pola yang sama saat dibutuhkan.

### Pemetaan badge

| Kelompok | Nilai → label (hue) | Sumber |
| --- | --- | --- |
| Status fase / item | Selesai (green) · Berjalan (orange) · Antri (indigo) · Terblokir (red) | canvas |
| Review | Terverifikasi (green) · Dilaporkan (amber) | canvas |
| Penanggung jawab | AI Client (violet) · Anda (orange) | canvas |
| Mode | Read-Only (sky) · Menulis (amber) | canvas |
| Meteran sesi | Aman (green) · Dumb Zone (orange) · Titik Compact (red) | canvas |
| Model / bukti non-hash | sky | canvas |
| Tag teknis, hash commit, id sesi | gray, varian mono | canvas |
| Status akun / token | Aktif (`okBg`/`okFg`) · Revoked, Wajib Ganti Password (`offBg`/`offFg`) | canvas |
| Tipe (`area`) | Backend (sky) · Frontend (violet) · Shared (teal) · Infra (amber) · MCP (pink) · Fullstack (Monolith) (green); Terang `-100`/`-800`, Gelap `-900`/`-300` skala Tailwind | knowledge vault "Desain UI Layout Spacing dan Navigasi" (sintesis, bukan canvas) |
| Method HTTP | GET (sky) · POST (green) · PUT/PATCH (amber) · DELETE (red); method lain (gray); varian mono, label huruf besar (`HttpMethodBadge`) | turunan, Confirmation 10 |

Teks label di kode boleh huruf kecil (nilai data); yang tampil selalu **Title Case**.

## 8. Layout

| Aspek | Web | Mobile |
| --- | --- | --- |
| Header | `h-14` | `h-14` + `env(safe-area-inset-top)` |
| Kontainer halaman | `mx-auto max-w-7xl px-8`, `pt-12 pb-16` | `px-4` (tablet `px-6`), `pt-4 pb-8` |
| Grid kartu | `repeat(auto-fill, minmax(240px, 1fr))`, `gap-6` | satu kolom, `gap-4` |
| Jarak antar-section | `space-y-12` | `space-y-8` |
| Shell | shadcn sidebar-07 (collapse ke ikon) | header + Sheet sidebar |

Catatan: artboard pemilih Project memakai `max-width: 1120px`; kode memakai `max-w-7xl` (1280 px)
sesuai keputusan layout di knowledge vault — beda lebar ini tidak mengubah grid kartu.

## 9. Tema Terang / Gelap / Sistem

- Preferensi `light | dark | system` disimpan di `localStorage` kunci **`whisker-theme`**;
  nilai tak sah atau kosong = `system`.
- Tema efektif dipasang sebagai kelas `dark` di `<html>` + `color-scheme`.
- Skrip inline di `<head>` (root view Rust) memasang kelas sebelum CSS dimuat agar tidak berkedip;
  logikanya sama dengan `frontend/src/lib/theme.ts`.
- Mode Sistem mengikuti perubahan `prefers-color-scheme` secara langsung.

## 10. Logo

| Berkas (`frontend/src/assets/logo/`) | Dipakai untuk |
| --- | --- |
| `whisker-logo-horizontal.svg` | mark + wordmark (wordmark butuh Sora 600) |
| `whisker-mark-light.svg` | mark di latar terang (garis `#14161B`, stroke 6/4) |
| `whisker-mark-dark.svg` | mark di latar gelap (garis `#F4F5F7`) |
| `whisker-app-icon.svg` | ikon aplikasi 112 px, persegi radius 26, latar ink |
| `whisker-favicon-48.svg`, `-32.svg`, `-16.svg` | favicon (mark disederhanakan per ukuran) |

- Mark: kepala kucing garis, dua goresan mata, titik hidung **aksen**, empat kumis. Hanya titik
  hidung yang berwarna aksen.
- Wordmark: "whisker" huruf kecil, Sora 600, `letter-spacing: -0.03em`. Tagline: "sense the context."
- Di UI, komponen `<Logo />` me-render SVG inline dengan `stroke="currentColor"` sehingga mengikuti
  tema; header memakai mark 30×29 px (stroke 7/5) + wordmark 20 px, jarak 8 px.

## 11. Avatar

- 40 preset (DiceBear `lorelei` + Fluent Emoji Flat) di atas latar pastel.
- **Tema terang: ring 1 px warna `border`** (`box-shadow: 0 0 0 1px var(--border)`), karena kontras
  latar pastel vs putih hanya ±1,2–1,5:1. Avatar terpilih di pemilih: ring 3 px `#FF7A45`.
- Ukuran: 80 px (profil), 40 px (daftar user), 34 px (tombol akun).

## 12. Halaman Login (turunan)

Canvas **tidak** punya artboard Login. Tampilan di bawah **diturunkan** dari token, tipografi, dan logo
di atas agar konsisten dengan pemilih Project (asumsi Q14):

- Latar `bg`, konten di tengah layar; theme toggle di pojok kanan atas.
- Logo horizontal (mark + wordmark) di atas kartu, tagline "sense the context." warna `muted`.
- Kartu `surface`, border, radius 14, lebar maks 400 px, `p-6 gap-6` (mobile `p-4 gap-4`, margin 16 px).
- Judul h1 "Masuk" (Sora 600, 20 px) + deskripsi `muted` 14 px.
- Field Email + Password (label 14/600, input), pesan error generik `role="alert"` warna `danger`.
- Tombol utama lebar penuh "Masuk"; mobile 44 px.

Halaman error (`Errors/NotFound`, `Errors/Forbidden`) memakai pola yang sama: mark, kode status,
judul Sora, deskripsi `muted`, tombol sekunder "Kembali ke Projects".
