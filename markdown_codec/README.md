# markdown_codec

Paket Dart murni untuk mem-parse markdown vault Whisker (frontmatter, blok, wikilink, tag) dan
menyerialisasinya kembali secara **byte-identik** bila tidak diedit. Dipakai server (indeks) dan
aplikasi (editor).

```bash
dart pub get
dart test
# opsional: uji round-trip terhadap vault nyata (tidak di-commit ke repo)
WHISKER_FIXTURE_VAULT=/path/ke/vault dart test test/corpus_test.dart
```
