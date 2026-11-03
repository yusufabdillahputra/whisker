import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/generated/protocol.dart';

import '../unit/git_test_helpers.dart';
import 'hub_endpoint_test.dart' show zipOf;
import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

/// Skenario ujung ke ujung alur aplikasi: buat Hub dari repo, impor vault,
/// pohon, cari, buka, commit, lalu konflik dari "PC lain".
void main() {
  withServerpod('E2E aplikasi', (sessionBuilder, endpoints) {
    test('app_flow_end_to_end', () async {
      await setUpHubService(sessionBuilder);
      final me = asUser(sessionBuilder, const Uuid().v4obj());
      final remote = await bareRemote();

      final hub = await endpoints.hub.create(me, 'Hub E2E', remoteUrl: remote);
      await endpoints.hub.importVault(
        me,
        hub.id!,
        zipOf({
          'vault/README.md': '# Beranda\n\nLihat [[Kucing]].\n',
          'vault/PKM/Kucing.md': '# Kucing\n\nKucing calico tiga warna.\n',
        }),
      );

      final tree = await endpoints.doc.tree(me, hub.id!);
      expect(tree.map((d) => d.path), ['PKM/Kucing.md', 'README.md']);

      final hits = await endpoints.doc.search(me, hub.id!, 'calico');
      expect(hits.single.path, 'PKM/Kucing.md');

      final doc = await endpoints.doc.read(me, hub.id!, 'PKM/Kucing.md');
      final ok = await endpoints.doc.commit(
        me,
        CommitRequest(
          hubId: hub.id!,
          path: doc.path,
          content: '${doc.content}Ditambah dari aplikasi.\n',
          message: '',
          baseSha: doc.baseSha,
        ),
      );
      expect(ok.status, 'ok');
      final history = await endpoints.doc.history(me, hub.id!, doc.path);
      expect(history.first.message, 'docs(knowledge): update Kucing');
      final back = await endpoints.doc.backlinks(me, hub.id!, doc.path);
      expect(back.map((d) => d.path), ['README.md']);

      // PC lain mendorong perubahan; commit dengan baseSha lama → konflik.
      await pushFiles(remote, {'PKM/Kucing.md': '# Kucing\n\nDari PC.\n'});
      final conflict = await endpoints.doc.commit(
        me,
        CommitRequest(
          hubId: hub.id!,
          path: doc.path,
          content: '# Kucing\n\nDraf aplikasi.\n',
          message: 'docs: draf',
          baseSha: ok.newSha,
        ),
      );
      expect(conflict.status, 'conflict');
      expect(conflict.latestContent, '# Kucing\n\nDari PC.\n');
    });
  });
}
