import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/doc/search_schema.dart';
import 'package:whisker_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Model', (sessionBuilder, endpoints) {
    late Session session;
    setUp(() => session = sessionBuilder.build());

    HubDocument doc(int hubId, String path) => HubDocument(
          hubId: hubId,
          path: path,
          title: 'A',
          area: 'knowledge',
          frontmatter: '{}',
          tags: ['x'],
          blobSha: 'abc',
          updatedAt: DateTime.now().toUtc(),
        );

    test('hub, member, dan dokumen tersimpan', () async {
      final owner = const Uuid().v4obj();
      final hub = await Hub.db.insertRow(
        session,
        Hub(name: 'Angkasa', slug: 'angkasa', remoteUrl: '/r', ownerId: owner),
      );
      expect(hub.defaultBranch, 'main');
      await HubMember.db.insertRow(
        session,
        HubMember(hubId: hub.id!, userId: owner, role: 'owner'),
      );
      final d = await HubDocument.db.insertRow(session, doc(hub.id!, 'a.md'));
      final back = await HubDocument.db.findById(session, d.id!);
      expect(back!.tags, ['x']);
      await expectLater(
        HubDocument.db.insertRow(session, doc(hub.id!, 'a.md')),
        throwsA(anything),
      );
    });

    test('ensureSearchSchema idempoten', () async {
      await ensureSearchSchema(session);
      await ensureSearchSchema(session);
      final r = await session.db.unsafeQuery(
        "select 1 from information_schema.tables where table_name = 'document_fts'",
      );
      expect(r, hasLength(1));
    });
  });
}
