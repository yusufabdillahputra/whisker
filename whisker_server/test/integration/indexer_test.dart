import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/doc/search_schema.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/git/git_repo.dart';
import 'package:whisker_server/src/index/indexer.dart';

import '../unit/git_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

const adr = '---\ntype: adr\nstatus: accepted\ntags: [x]\n---\n'
    '# ADR-001 — Pilih Postgres\n\nKarena andal.\n';

void main() {
  withServerpod('Indexer', (sessionBuilder, endpoints) {
    late Session s;
    late String remote;
    late GitRepo repo;
    late Hub hub;

    setUp(() async {
      s = sessionBuilder.build();
      await ensureSearchSchema(s);
      remote = await bareRemote();
      await pushFiles(remote, {
        'PKM/ADR/ADR-001 - A.md': adr,
        'B.md': '# B\n\nLihat [[ADR-001 - A]] dan [[Tidak Ada]].\n',
        'gambar.png': 'bukan md',
      });
      repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
      hub = await Hub.db.insertRow(
        s,
        Hub(name: 'H', slug: 'h', remoteUrl: remote, ownerId: const Uuid().v4obj()),
      );
    });

    test('full_index', () async {
      final changed = await indexHub(s, hub, repo);
      expect(changed..sort(), ['B.md', 'PKM/ADR/ADR-001 - A.md']);
      final docs = await HubDocument.db.find(s, orderBy: (d) => d.path);
      expect(docs.map((d) => d.path), ['B.md', 'PKM/ADR/ADR-001 - A.md']);
      final a = docs[1];
      expect([a.title, a.area, a.type, a.status, a.tags], [
        'ADR-001 — Pilih Postgres', 'knowledge', 'adr', 'accepted', ['x'],
      ]);
      expect(a.lastCommitSha, await repo.head());
      final links = await DocumentLink.db.find(s, orderBy: (l) => l.toPath);
      expect(links.map((l) => (l.toPath, l.toDocId)), [
        ('ADR-001 - A', a.id),
        ('Tidak Ada', null),
      ]);
      final h = await Hub.db.findById(s, hub.id!);
      expect(h!.headSha, await repo.head());
      expect(h.lastIndexedAt, isNotNull);
    });

    test('incremental_index', () async {
      await indexHub(s, hub, repo);
      final from = (await repo.head())!;
      await pushFiles(remote, {
        'PKM/ADR/ADR-001 - A.md': null,
        'B.md': '# B baru\n\n[[ADR-001 - A]]\n',
      });
      await repo.fetch(remote, 'main');
      await repo.resetHard('origin/main');
      final changed = await indexHub(s, hub, repo, fromSha: from);
      expect(changed..sort(), ['B.md', 'PKM/ADR/ADR-001 - A.md']);
      final docs = await HubDocument.db.find(s);
      expect(docs.map((d) => d.title), ['B baru']);
      final links = await DocumentLink.db.find(s);
      expect(links.single.toDocId, isNull);
    });

    test('fts_row_written', () async {
      await indexHub(s, hub, repo);
      final r = await s.db.unsafeQuery(
        "select count(*) from document_fts where vec @@ to_tsquery('simple', 'andal')",
      );
      expect(r.first.first, 1);
      final all = await s.db.unsafeQuery('select count(*) from document_fts');
      expect(all.first.first, 2);
    });
  });
}
