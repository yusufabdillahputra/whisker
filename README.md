# Whisker

Aplikasi **Second Brain** monolith berbasis **PKM + LLM Wiki + graphify** — satu container Docker
yang memuat aplikasi dan graphify.

> **Status: pra-implementasi.** Stack yang diarahkan: Rust **Axum** (backend) + **React** via protokol
> **Inertia** + **shadcn/ui** (frontend). Keputusan final dicatat sebagai ADR di vault dokumentasi.

## Pengembangan

- **TDD** — tes gagal dulu, implementasi minimal, lalu tes lulus (Rust: `cargo test`; frontend: unit test).
- **E2E** — **Playwright** di `test/playwright/`, dijalankan terhadap aplikasi yang berjalan:
  `npx playwright test -c test/playwright`. Env: salin `test/playwright/.e2e.env.example` →
  `test/playwright/.e2e.env` (keduanya dibuat bersama spec E2E pertama). Hasil & bukti gambar tidak
  di-commit di repo ini.

## Dokumentasi

Dokumentasi pembangunan (ADR, arsitektur, rencana & task fitur) ada di vault terpisah:
<https://github.com/yusufabdillahputra/wiki-whisker>.

## Roadmap singkat

- **MVP**: PKM + LLM Wiki + graphify.
- **Berikutnya**: upload berkas dengan konversi Docling.

## Lisensi

[GNU Affero General Public License v3.0](LICENSE) (AGPL-3.0-only).
