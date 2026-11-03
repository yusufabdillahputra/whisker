---
title: Desain Warna
description: Palet terinspirasi kucing calico, struktur design token (W3C DTCG), dan aturan kontras WCAG 2.2
updated: 2026-11-03
---

# Desain Warna

## Acuan komunitas

| praktik | dari mana | dipakai untuk |
| --- | --- | --- |
| Format token `$value` / `$type` + alias `{color.ginger.700}` | W3C Design Tokens Community Group (dipakai Style Dictionary, Figma Tokens) | `design/tokens/whisker.tokens.json` |
| Dua lapis token: **primitive** (skala) → **semantic** (peran) | Material Design 3, Radix Colors, shadcn/ui | skala calico → peran `FColors` Forui |
| Skala 11 langkah 50…950 dengan lightness merata | Tailwind CSS, dihitung di ruang warna **OKLCH** | langkah yang konsisten antar-hue |
| Kontras teks ≥ 4.5:1, komponen UI & fokus ≥ 3:1 | WCAG 2.2 SC 1.4.3 dan 1.4.11 | dicek otomatis oleh `design/tools/check-contrast.py` |

## Palet calico

Kucing calico = bulu putih krem, belang oranye, belang hitam; ditambah mata hijau dan hidung merah muda.

| skala | inspirasi | peran | 50 | 500 | 950 |
| --- | --- | --- | --- | --- | --- |
| `fur` | bulu krem → belang hitam | netral (latar, teks, border) | `#FEF9F4` | `#A79E95` | `#221E1A` |
| `ginger` | belang oranye | brand / primary | `#FEF9F6` | `#F47806` | `#351500` |
| `jade` | mata hijau | success / aksen | `#F1FEF3` | `#56B870` | `#072610` |
| `nose` | hidung merah muda | destructive / error | `#FEF8F9` | `#FA6786` | `#3C0816` |

Nilai lengkap 50…950 ada di file token.

## Peta semantic (ringkas)

| peran | light | dark |
| --- | --- | --- |
| background / foreground | `fur.50` / `fur.950` | `fur.950` / `fur.50` |
| primary / primaryForeground | `ginger.700` / `fur.50` | `ginger.400` / `fur.950` |
| muted / mutedForeground | `fur.100` / `fur.700` | `fur.900` / `fur.400` |
| destructive, error | `nose.700` / `fur.50` | `nose.400` / `fur.950` |
| success | `jade.700` / `fur.50` | `jade.400` / `fur.950` |
| border (dekoratif) | `fur.200` | `fur.800` |
| input (batas field, wajib ≥ 3:1) | `fur.600` | `fur.600` |
| brand (logo, ilustrasi, bukan teks) | `ginger.500` | `ginger.500` |

Catatan penting: **oranye calico murni (`ginger.500`) tidak boleh jadi latar teks** di tema light
(kontras dengan putih hanya ±2.9:1). Untuk tombol primary pakai `ginger.700`; `ginger.500` hanya untuk
elemen brand dan dekoratif.

## Aturan

1. Ubah warna **hanya** di `design/tokens/whisker.tokens.json`, lalu jalankan
   `python3 design/tools/check-contrast.py`. Semua baris harus `OK`.
2. Pasangan baru (mis. token `warning`) ditambahkan juga ke daftar `PAIRS` di skrip itu.
3. Widget tidak boleh menulis hex langsung; selalu lewat tema (lihat [Flutter dan Forui](Flutter-Forui.md)).
4. Status tidak boleh disampaikan hanya dengan warna; sertakan ikon atau teks.
