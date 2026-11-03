---
title: Flutter dan Forui
description: Konvensi aplikasi Flutter Whisker, pemasangan tema calico ke Forui, dan aksesibilitas
updated: 2026-11-03
---

# Flutter dan Forui

Sumber: <https://docs.flutter.dev/>, <https://forui.dev/docs>, API `forui` 0.27.x di pub.dev.

## Prinsip UI

- **Forui dulu.** Pakai widget `F*` (FScaffold, FButton, FTextField, FSidebar, FTabs, FDialog, FToast,
  FAvatar, …) sebelum membuat widget sendiri. Material dipakai hanya bila Forui tidak punya padanannya.
- **Satu codebase, adaptif.** Layout responsif (ponsel → tablet → desktop/web) dengan breakpoint, bukan
  cabang kode per platform. Varian Forui: `.touch` untuk Android/iOS, `.desktop` untuk Web/desktop.
- Desain UI mengikuti spec `docs/superpowers/specs/2026-11-03-whisker-inti-hub-design.md`.

## Struktur aplikasi

`whisker_flutter/` **diresolusi terpisah dari pub workspace** (`appflowy_editor` menarik win32 5,
server Serverpod win32 6). `appflowy_editor` dipatok ke commit git `01eccc6` (rilis pub 6.2.0 tidak
terkompilasi di Flutter 3.47).

| path | isi |
| --- | --- |
| `lib/app/` | `tokens.g.dart` (generate), `theme.dart` (FColors calico + `materialThemeOf`), `app.dart` (router), `logo.dart` |
| `lib/data/` | `WhiskerApi` (antarmuka), `ServerpodWhiskerApi`, `FakeWhiskerApi` (memori, demo/test), provider Riverpod, `DraftStore` |
| `lib/features/hubs/` | daftar Hub, dialog **Hub baru**, **Impor vault** (.zip) |
| `lib/features/shell/` | workspace responsif: ≥ 1100 px tiga panel, 700–1099 px pohon + editor (inspector di sheet), < 700 px bottom nav Beranda/Dokumen/Cari/Tracking; `Ctrl/Cmd K` membuka palet cari |
| `lib/features/hub_tree/` | pohon dokumen (folder dilipat, ikon per area) |
| `lib/features/editor/` | `editor_codec.dart` (blok `MdDocument` ↔ node appflowy), `raw_block.dart`, `doc_session.dart`, `editor_pane.dart` |
| `lib/features/commit/` | dialog **Commit changes** dan dialog konflik |
| `lib/features/inspector/` | Properties (YAML frontmatter), Backlinks, Riwayat |
| `lib/features/search/` | palet pencarian (debounce 250 ms, Enter = hasil pertama) |
| `lib/features/local_sync/` | clone/`ff-only` folder lokal Hub di desktop; tidak menyentuh perubahan lokal |

## Editor: byte-identik dulu

- Blok heading/paragraf/list/quote yang **stabil** (render HTML sama setelah round-trip appflowy) jadi
  node WYSIWYG; fence/Mermaid, callout, tabel, HTML, dan blok lain jadi **raw block** (teks mentah).
- Saat simpan, blok yang tidak berubah memakai teks aslinya (`assembleBody` di `markdown_codec`), jadi
  dokumen yang dibuka lalu disimpan tanpa edit **byte-identik**. List yang diedit memakai penanda asli.
- Draf disimpan per (`hubId`, `path`) di `shared_preferences` (debounce 800 ms) dan tetap ada saat
  konflik. Dokumen `_Format/`, `_LLM-Wiki/`, dan ADR `accepted` dibuka baca saja (ADR masih boleh
  mengubah `status` lewat Properties).

## Tema calico ke Forui

Warna **hanya** dari token: jalankan `python3 design/tools/gen-dart-tokens.py` setelah mengubah
`design/tokens/whisker.tokens.json` untuk membuat ulang `lib/app/tokens.g.dart` (jangan diedit manual).
`whiskerTheme(brightness, touch:)` membangun `FThemeData`; brightness mengikuti sistem, `touch` aktif
di Android/iOS. Baca warna di widget lewat `context.theme.colors`; token di luar `FColors` lewat
`semanticOf(brightness)`.

`toApproximateMaterialTheme()` milik Forui 0.27 memakai paket `material_ui`, bukan
`package:flutter/material.dart`; untuk widget Material (appflowy_editor) pakai `materialThemeOf(theme)`.

## Mode demo dan screenshot

```bash
cd whisker_flutter
flutter run -d chrome --dart-define=WHISKER_DEMO=true      # data contoh, tanpa login
flutter build web --dart-define=WHISKER_DEMO=true --no-web-resources-cdn
NODE_PATH=$(npm root -g) node tool/screenshots.mjs           # → docs/screenshots/*.png
```

Tanpa `WHISKER_DEMO`, aplikasi memakai server (`SERVER_URL` atau `assets/config.json`) dan login.

## Aksesibilitas (wajib)

- Kontras mengikuti WCAG 2.2 AA (detail di [Desain Warna](Desain-Warna.md)).
- Target sentuh minimal 44×44 dp (pakai varian `.touch` di perangkat sentuh).
- Setiap ikon tanpa teks diberi `Semantics`/label. Jangan menyampaikan status hanya lewat warna.
- Uji dengan skala teks besar dan navigasi keyboard di desktop/web.

## Bukti

`flutter analyze` bersih, `flutter test` hijau, dan screenshot light + dark untuk setiap perubahan UI.
