import 'dart:convert';

import 'package:markdown_codec/markdown_codec.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../git/git_repo.dart';

/// Mengindeks file markdown Hub dari clone kerja [repo] ke Postgres.
///
/// [fromSha] `null` = indeks penuh (dokumen yang tak ada lagi dihapus);
/// selain itu hanya path yang berubah antara [fromSha] dan `HEAD`.
/// Mengembalikan path `.md` yang berubah.
Future<List<String>> indexHub(
  Session s,
  Hub hub,
  GitRepo repo, {
  String? fromSha,
}) async {
  final head = await repo.head();
  final hubId = hub.id!;
  if (head == null) return [];
  final paths = (await repo.changedPaths(
    fromSha,
    head,
  )).where((p) => p.toLowerCase().endsWith('.md')).toList();

  if (fromSha == null) {
    final keep = paths.toSet();
    final stale = await HubDocument.db.find(
      s,
      where: (d) => d.hubId.equals(hubId),
    );
    await _deleteDocs(s, stale.where((d) => !keep.contains(d.path)));
  }

  for (final path in paths) {
    final existing = await HubDocument.db.findFirstRow(
      s,
      where: (d) => d.hubId.equals(hubId) & d.path.equals(path),
    );
    final content = await repo.show(head, path);
    if (content == null) {
      if (existing != null) await _deleteDocs(s, [existing]);
      continue;
    }
    final md = MdDocument.parse(content);
    final fm = md.frontmatter.data;
    final cls = classifyPath(path, fm);
    final status = fm['status'];
    final row = HubDocument(
      id: existing?.id,
      hubId: hubId,
      path: path,
      title: extractTitle(md, path),
      area: cls.area.name,
      type: cls.type,
      status: status is String ? status : null,
      frontmatter: jsonEncode(fm, toEncodable: (o) => o.toString()),
      tags: extractTags(md),
      blobSha: (await repo.blobAt(head, path))!,
      lastCommitSha: await repo.lastCommitFor(path),
      updatedAt: DateTime.now().toUtc(),
    );
    final saved = existing == null
        ? await HubDocument.db.insertRow(s, row)
        : await HubDocument.db.updateRow(s, row);

    await DocumentLink.db.deleteWhere(
      s,
      where: (l) => l.fromDocId.equals(saved.id!),
    );
    final targets = {
      for (final l in extractWikilinks(md))
        if (l.target.isNotEmpty) l.target,
    };
    await DocumentLink.db.insert(s, [
      for (final t in targets)
        DocumentLink(fromDocId: saved.id!, hubId: hubId, toPath: t),
    ]);

    await s.db.unsafeExecute(
      '''
INSERT INTO document_fts (document_id, hub_id, vec)
VALUES (@id, @hub,
  setweight(to_tsvector('simple', @title), 'A') ||
  setweight(to_tsvector('simple', @tags), 'B') ||
  setweight(to_tsvector('simple', @body), 'C'))
ON CONFLICT (document_id) DO UPDATE SET vec = EXCLUDED.vec''',
      parameters: QueryParameters.named({
        'id': saved.id,
        'hub': hubId,
        'title': saved.title,
        'tags': saved.tags.join(' '),
        'body': md.frontmatter.body,
      }),
    );
  }

  await resolveLinks(s, hubId);
  await Hub.db.updateRow(
    s,
    hub.copyWith(headSha: head, lastIndexedAt: DateTime.now().toUtc()),
  );
  hub.headSha = head;
  return paths;
}

Future<void> _deleteDocs(Session s, Iterable<HubDocument> docs) async {
  final ids = docs.map((d) => d.id!).toSet();
  if (ids.isEmpty) return;
  await DocumentLink.db.deleteWhere(
    s,
    where: (l) => l.fromDocId.inSet(ids),
  );
  await HubDocument.db.deleteWhere(s, where: (d) => d.id.inSet(ids));
}

String _key(String s) {
  final lower = s.toLowerCase();
  return lower.endsWith('.md') ? lower.substring(0, lower.length - 3) : lower;
}

/// Mengisi ulang `toDocId` semua tautan di Hub: target cocok dengan nama file
/// atau path tanpa `.md` (tidak peka huruf besar, seperti Obsidian).
Future<void> resolveLinks(Session s, int hubId) async {
  final docs = await HubDocument.db.find(
    s,
    where: (d) => d.hubId.equals(hubId),
  );
  final byKey = <String, int>{};
  for (final d in docs) {
    byKey.putIfAbsent(_key(d.path), () => d.id!);
    byKey.putIfAbsent(_key(d.path.split('/').last), () => d.id!);
  }
  final links = await DocumentLink.db.find(
    s,
    where: (l) => l.hubId.equals(hubId),
  );
  final changed = <DocumentLink>[];
  for (final l in links) {
    final id = byKey[_key(l.toPath)];
    if (id != l.toDocId) changed.add(l.copyWith(toDocId: id));
  }
  if (changed.isNotEmpty) await DocumentLink.db.update(s, changed);
}
