---
title: Logo DiceBear
description: Logo Whisker dan avatar pengguna dari style DiceBear whisker-critters (remix Critters, kucing calico)
updated: 2026-11-03
---

# Logo DiceBear

![Pratinjau logo dan avatar](../design/logo/preview.png)

## Cara kerja

DiceBear 10 menggambar avatar dari **style definition JSON** dan sebuah **seed** secara deterministik
(seed + opsi yang sama → SVG yang identik di semua bahasa). Logo dan avatar Whisker memakai style
`design/dicebear/whisker-critters.json`: remix [Critters](https://www.dicebear.com/styles/critters/)
(DiceBear, **CC0 1.0**, bebas dipakai komersial dan di-remix) menjadi kucing calico.

| komponen | asal | isi |
| --- | --- | --- |
| `top` | diubah | hanya `earsPointy`; telinga kiri `earLeft` (oranye), kanan `earRight` (hitam) |
| `body` | Critters | bentuk membulat: `dome`, `round`, `squat`, `blob`, `tilt`, `peak`, `bell` |
| `calico` | baru | belang `patchA` (oranye) dan `patchB` (hitam), varian `classic`, `mask`, `splash`, dipotong mengikuti clipPath badan |
| `eyes`, `mouth`, `cheeks` | Critters (disaring) | ekspresi ramah; `catMouth` paling sering muncul |
| `pattern`, `animation` | dimatikan | pola putih bawaan tak terlihat di bulu krem; logo statis |

Semua warna diambil dari token calico (lihat [Desain Warna](Desain-Warna.md)).

## Logo resmi

Seed `Whisker` dengan varian dan warna terkunci: badan `round`, belang `classic`, mata `round`, mulut
`catMouth`, bulu `fur.50`, oranye `ginger.500`, hitam `fur.950`. Konfigurasinya di
`design/tools/render-logo.mjs`.

| file | pakai untuk |
| --- | --- |
| `design/logo/whisker-logo.svg` | ikon aplikasi utama (latar krem `ginger.100`, sudut membulat) |
| `design/logo/whisker-logo-ginger.svg` | splash / store listing (latar `ginger.500`, belang `ginger.400`) |
| `design/logo/whisker-mark.svg` | tanda tanpa latar (header, favicon, dokumen) |
| `design/logo/avatar-samples.svg` | contoh avatar pengguna |

## Membangun dan merender

Style dibangun oleh skrip dari Critters asli, **jangan diedit manual**:

```bash
cd design/tools && npm install
python3 build-critters-cat.py   # tulis ulang design/dicebear/whisker-critters.json
npm run logo                    # render design/logo/*.svg
```

Ikon per platform (Android adaptive icon, iOS, web, desktop) dihasilkan dari `whisker-logo.svg` saat
aplikasi Flutter dibuat; tool-nya ditentukan bersama daftar extension lintas platform
(lihat [Tech Stack](Tech-Stack.md)).

## Avatar pengguna

Avatar default pengguna dan agent = style yang sama dengan `seed` = id pengguna dan varian bebas,
sehingga setiap orang mendapat kucing calico yang unik tapi tetap satu keluarga dengan logo. Render di
server lalu cache sebagai SVG, atau pakai implementasi DiceBear untuk Dart bila sudah mendukung versi 10.

## Aturan

- Logo **tidak** digambar ulang manual; ubah `build-critters-cat.py` atau opsi di `render-logo.mjs`,
  lalu bangun dan render ulang.
- Setelah render, perbarui `design/logo/preview.png` (screenshot logo + avatar di latar terang dan gelap)
  dan cek hasilnya di kedua latar.
- Atribusi Critters (CC0) tetap disimpan di `meta` style.
