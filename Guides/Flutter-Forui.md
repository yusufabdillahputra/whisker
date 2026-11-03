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
- **Desain UI detail belum ditetapkan**; dibahas lewat `superpowers:brainstorming` (spec di
  `docs/superpowers/specs/`). Guide ini hanya memuat konvensi dasar.

## Tema calico ke Forui

Forui **tidak mengatur brightness otomatis**; aplikasi memilih light/dark (ikut sistem + pilihan user).
Nilai warna diambil dari `design/tokens/whisker.tokens.json` (`semantic.light` / `semantic.dark`).
Kelak dibuat generator token → Dart; sampai itu ada, salin nilai dan sertakan komentar nama tokennya.

```dart
// whisker_flutter/lib/theme/whisker_colors.dart (contoh light; dark mengikuti semantic.dark)
const whiskerLight = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  barrier: Color(0x33221E1A),               // fur.950 @ 20%
  background: Color(0xFFFEF9F4),            // fur.50
  foreground: Color(0xFF221E1A),            // fur.950
  primary: Color(0xFFA75001),               // ginger.700
  primaryForeground: Color(0xFFFEF9F4),     // fur.50
  secondary: Color(0xFFF8F1EA),             // fur.100
  secondaryForeground: Color(0xFF3C3731),   // fur.900
  muted: Color(0xFFF8F1EA),                 // fur.100
  mutedForeground: Color(0xFF716B63),       // fur.700
  destructive: Color(0xFFB83255),           // nose.700
  destructiveForeground: Color(0xFFFEF9F4), // fur.50
  error: Color(0xFFB83255),                 // nose.700
  errorForeground: Color(0xFFFEF9F4),       // fur.50
  card: Color(0xFFFFFFFF),
  border: Color(0xFFECE4DA),                // fur.200
);
```

Pasang dengan `FTheme(data: FThemeData(colors: whiskerLight, typography: ..., touch: true), child: ...)`
dan baca di widget lewat `context.theme.colors`. Token di luar `FColors` (mis. `success`, `input`,
`ring`, `brand`) dipasang sebagai `ThemeExtension` lewat parameter `extensions`. Untuk widget Material
yang tersisa, pakai `toApproximateMaterialTheme()`.

## Aksesibilitas (wajib)

- Kontras mengikuti WCAG 2.2 AA (detail di [Desain Warna](Desain-Warna.md)).
- Target sentuh minimal 44×44 dp (pakai varian `.touch` di perangkat sentuh).
- Setiap ikon tanpa teks diberi `Semantics`/label. Jangan menyampaikan status hanya lewat warna.
- Uji dengan skala teks besar dan navigasi keyboard di desktop/web.

## Bukti

`flutter analyze` bersih, `flutter test` hijau, dan screenshot light + dark untuk setiap perubahan UI.
