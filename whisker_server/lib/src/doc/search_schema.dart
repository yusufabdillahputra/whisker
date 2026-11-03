import 'package:serverpod/serverpod.dart';

/// Membuat tabel full-text turunan `document_fts` bila belum ada.
///
/// Model Serverpod tidak mendukung kolom `tsvector`, jadi tabel ini dikelola
/// manual. Isinya bisa dibangun ulang kapan saja lewat indeks ulang Hub.
Future<void> ensureSearchSchema(Session session) async {
  await session.db.unsafeExecute('''
CREATE TABLE IF NOT EXISTS document_fts (
  document_id bigint PRIMARY KEY REFERENCES document(id) ON DELETE CASCADE,
  hub_id bigint NOT NULL,
  vec tsvector NOT NULL
)''');
  await session.db.unsafeExecute(
    'CREATE INDEX IF NOT EXISTS document_fts_vec_idx '
    'ON document_fts USING GIN (vec)',
  );
  await session.db.unsafeExecute(
    'CREATE INDEX IF NOT EXISTS document_fts_hub_idx ON document_fts (hub_id)',
  );
}
