import 'dart:io';

import 'package:markdown_codec/markdown_codec.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../hub/hub_service.dart';
import 'commit_service.dart';
import 'safe_path.dart';

DocSummary _summary(HubDocument d) => DocSummary(
  path: d.path,
  title: d.title,
  area: d.area,
  type: d.type,
  status: d.status,
);

/// Baca, cari, backlink, riwayat, dan commit dokumen Hub.
class DocEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  HubService get _svc => HubService.instance;

  /// Semua dokumen Hub, urut path.
  Future<List<DocSummary>> tree(Session session, int hubId) async {
    await _svc.requireMember(session, hubId);
    final docs = await HubDocument.db.find(
      session,
      where: (d) => d.hubId.equals(hubId),
      orderBy: (d) => d.path,
    );
    return docs.map(_summary).toList();
  }

  /// Isi dokumen beserta `blobSha` dan `baseSha` untuk commit berikutnya.
  Future<DocContent> read(Session session, int hubId, String path) async {
    safePath(path);
    final hub = await _svc.requireMember(session, hubId);
    final repo = await _svc.repoFor(hub);
    final content = await repo.show('HEAD', path);
    if (content == null) {
      throw WhiskerException(message: 'Dokumen tidak ditemukan: $path');
    }
    return DocContent(
      path: path,
      content: content,
      blobSha: (await repo.blobAt('HEAD', path))!,
      baseSha: await repo.lastCommitFor(path),
      readOnlyReason: readOnlyReason(path, content),
    );
  }

  /// Pencarian full-text; judul berbobot lebih tinggi dari tag dan isi.
  Future<List<SearchHit>> search(
    Session session,
    int hubId,
    String query, {
    int? limit,
  }) async {
    final hub = await _svc.requireMember(session, hubId);
    if (query.trim().isEmpty) return [];
    final rows = await session.db.unsafeQuery(
      '''
SELECT d.path, d.title, ts_rank(f.vec, q) AS rank
FROM document_fts f
JOIN document d ON d.id = f.document_id,
     websearch_to_tsquery('simple', @q) q
WHERE f.hub_id = @hub AND f.vec @@ q
ORDER BY rank DESC, d.path
LIMIT @limit''',
      parameters: QueryParameters.named({
        'q': query,
        'hub': hubId,
        'limit': limit ?? 20,
      }),
    );
    final words = query
        .toLowerCase()
        .split(RegExp(r'[\s"]+'))
        .map((w) => w.replaceFirst(RegExp(r'^-'), ''))
        .where((w) => w.isNotEmpty && w != 'or')
        .toList();
    final dir = _svc.repoDir(hub.id!);
    return [
      for (final r in rows)
        SearchHit(
          path: r[0] as String,
          title: r[1] as String,
          rank: (r[2] as num).toDouble(),
          snippet: await _snippet('$dir/${r[0]}', words),
        ),
    ];
  }

  Future<String> _snippet(String file, List<String> words) async {
    final f = File(file);
    if (!await f.exists()) return '';
    final body = splitFrontmatter(await f.readAsString()).body;
    for (final line in body.split('\n')) {
      final l = line.toLowerCase();
      if (words.any(l.contains)) {
        final t = line.trim();
        return t.length > 160 ? '${t.substring(0, 157)}...' : t;
      }
    }
    return '';
  }

  /// Dokumen yang menautkan ke [path].
  Future<List<DocSummary>> backlinks(
    Session session,
    int hubId,
    String path,
  ) async {
    await _svc.requireMember(session, hubId);
    final target = await HubDocument.db.findFirstRow(
      session,
      where: (d) => d.hubId.equals(hubId) & d.path.equals(path),
    );
    if (target == null) return [];
    final links = await DocumentLink.db.find(
      session,
      where: (l) => l.toDocId.equals(target.id!),
    );
    if (links.isEmpty) return [];
    final docs = await HubDocument.db.find(
      session,
      where: (d) => d.id.inSet(links.map((l) => l.fromDocId).toSet()),
      orderBy: (d) => d.path,
    );
    return docs.map(_summary).toList();
  }

  /// Riwayat commit [path].
  Future<List<HistoryEntry>> history(
    Session session,
    int hubId,
    String path,
  ) async {
    safePath(path);
    final hub = await _svc.requireMember(session, hubId);
    return (await _svc.repoFor(hub)).log(path);
  }

  /// Commit + push satu dokumen (lihat spec 4.2).
  Future<CommitResult> commit(Session session, CommitRequest request) =>
      commitDocument(session, request);
}
