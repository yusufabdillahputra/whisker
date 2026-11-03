import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_codec/markdown_codec.dart';
import 'package:whisker_client/whisker_client.dart';

import '../../data/providers.dart';

/// Status penyuntingan satu dokumen, dibagi editor dan inspector.
class DocSession {
  /// Isi di server saat dimuat atau setelah commit terakhir.
  final String serverContent;

  /// Commit acuan untuk deteksi konflik.
  final String? baseSha;

  /// Dokumen yang menjadi dasar editor (isi server atau draf).
  final MdDocument original;
  final String frontmatter;
  final String body;
  final String? readOnlyReason;

  /// Naik setiap editor harus dibangun ulang dari [original].
  final int generation;

  const DocSession({
    required this.serverContent,
    required this.baseSha,
    required this.original,
    required this.frontmatter,
    required this.body,
    required this.readOnlyReason,
    this.generation = 0,
  });

  String get content => frontmatter + body;
  bool get dirty => content != serverContent;

  DocSession copyWith({
    String? serverContent,
    String? baseSha,
    String? frontmatter,
    String? body,
    String? readOnlyReason,
  }) => DocSession(
    serverContent: serverContent ?? this.serverContent,
    baseSha: baseSha ?? this.baseSha,
    original: original,
    frontmatter: frontmatter ?? this.frontmatter,
    body: body ?? this.body,
    readOnlyReason: readOnlyReason ?? this.readOnlyReason,
    generation: generation,
  );
}

class DocSessionNotifier extends Notifier<DocSession?> {
  DocSessionNotifier(this.key);
  final DocKey key;

  @override
  DocSession? build() => null;

  /// Memulai sesi dari isi server; [draft] (bila ada) menjadi isi editor.
  void start(DocContent server, {String? draftContent, String? draftBaseSha}) {
    final text = draftContent ?? server.content;
    final md = MdDocument.parse(text);
    state = DocSession(
      serverContent: server.content,
      baseSha: draftContent == null ? server.baseSha : draftBaseSha,
      original: md,
      frontmatter: md.frontmatter.raw,
      body: md.frontmatter.body,
      readOnlyReason: server.readOnlyReason,
      generation: (state?.generation ?? 0) + 1,
    );
  }

  void setBody(String body) => state = state?.copyWith(body: body);

  void setFrontmatter(String raw) => state = state?.copyWith(frontmatter: raw);

  /// Commit berhasil: isi saat ini menjadi isi server.
  void committed(String? newSha) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(serverContent: s.content, baseSha: newSha);
  }

  /// Konflik, pengguna tetap memakai drafnya: commit berikutnya menimpa
  /// [latestSha] secara sadar.
  void rebase(String? latestSha, String? latestContent) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(baseSha: latestSha, serverContent: latestContent ?? '');
  }
}

final docSessionProvider =
    NotifierProvider.family<DocSessionNotifier, DocSession?, DocKey>(
      DocSessionNotifier.new,
    );
