---
title: CI dan Release
description: CI dan release Whisker dengan GitHub Actions untuk Android, iOS, Web, macOS, Windows, dan Linux
status: draf
updated: 2026-11-03
---

# CI dan Release

Semua CI dan release memakai **GitHub Actions**. Aplikasi bisa diunduh untuk **Android, iPhone (iOS),
Web, macOS, Windows, dan Linux (Ubuntu)**.

> **Menunggu masukan:** daftar extension/package lintas platform (dan kebutuhan build tiap platform)
> akan diberikan oleh agent **Retail**. Workflow build per platform disusun setelah daftar itu ada.

## CI (setiap PR ke `main`)

| job | runner | isi |
| --- | --- | --- |
| server | `ubuntu-latest` + Postgres service | `dart analyze`, `dart test` di `whisker_server/`, cek migrasi ter-commit |
| app | `ubuntu-latest` | `flutter analyze`, `flutter test` di `whisker_flutter/` |
| generated | `ubuntu-latest` | generate ulang kode Serverpod, gagal bila ada diff (kode generate basi) |
| design | `ubuntu-latest` | `python3 design/tools/check-contrast.py` |

## Release (tag `v*`)

Acuan bentuk release: release **Lakuna 0.4.0** dari user (satu GitHub Release berisi semua artefak
platform, masing-masing dengan digest `sha256`). Whisker meniru pola penamaannya:

| platform | runner | nama artefak |
| --- | --- | --- |
| Android | `ubuntu-latest` | `Whisker-<versi>-android-<flavor>.aab` dan `.apk` (Lakuna memakai flavor `uji`) |
| iOS | `macos-latest` | `Whisker-<versi>-ios-unsigned.ipa` (versi signed untuk TestFlight menyusul) |
| macOS | `macos-latest` | `Whisker-<versi>-macos.dmg` |
| Windows | `windows-latest` | `Whisker-<versi>-windows-x64-setup.exe` dan `Whisker-<versi>-windows-x64.msi` |
| Linux / Ubuntu | `ubuntu-latest` | `whisker_<versi>_amd64.deb` (konvensi Debian: huruf kecil + underscore) |
| Web | `ubuntu-latest` | di-deploy ke hosting (bukan aset release); arsip `build/web` opsional |
| Server | `ubuntu-latest` | image Docker (registry ditentukan kemudian) |

Artefak diunggah ke **GitHub Release** untuk tag tersebut, dengan `sha256` per file. Versi mengikuti
SemVer dan `pubspec.yaml`.

## Rahasia

Keystore Android, sertifikat dan profil Apple, sertifikat code signing Windows, dan kredensial store
disimpan sebagai **GitHub Actions secrets** / environment, tidak pernah di repo.
