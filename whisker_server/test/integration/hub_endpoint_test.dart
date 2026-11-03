import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/git/git_repo.dart';

import '../unit/git_test_helpers.dart';
import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

ByteData zipOf(Map<String, String> files) {
  final a = Archive();
  for (final e in files.entries) {
    a.addFile(ArchiveFile.bytes(e.key, e.value.codeUnits));
  }
  return ByteData.sublistView(Uint8List.fromList(ZipEncoder().encode(a)));
}

void main() {
  withServerpod('HubEndpoint', (sessionBuilder, endpoints) {
    final owner = const Uuid().v4obj();
    final other = const Uuid().v4obj();
    late TestSessionBuilder me;
    late String remote;

    setUp(() async {
      await setUpHubService(sessionBuilder);
      me = asUser(sessionBuilder, owner);
      remote = await bareRemote();
    });

    test('create_lists_for_owner_only', () async {
      await pushFiles(remote, {'a.md': '# A\n'});
      final hub = await endpoints.hub.create(me, 'Wiki Angkasa', remoteUrl: remote);
      expect(hub.slug, 'wiki-angkasa');
      expect(hub.headSha, isNotNull);
      expect((await endpoints.hub.list(me)).map((h) => h.id), [hub.id]);
      expect(await endpoints.hub.list(asUser(sessionBuilder, other)), isEmpty);
      final docs = await HubDocument.db.find(sessionBuilder.build());
      expect(docs.map((d) => d.path), ['a.md']);
    });

    test('import_vault_commits_and_indexes', () async {
      final hub = await endpoints.hub.create(me, 'Baru', remoteUrl: remote);
      expect(hub.headSha, isNull);
      final after = await endpoints.hub.importVault(
        me,
        hub.id!,
        zipOf({
          '.obsidian/app.json': '{}',
          '.claude/settings.local.json': '{}',
          '.gitignore': 'secret.md\n',
          'secret.md': 'rahasia',
          'a.md': '# A\n',
        }),
      );
      expect(after.headSha, isNotNull);
      final check = await GitRepo.clone(remote, await tempDir(), branch: 'main');
      expect((await check.listFiles())..sort(), ['.gitignore', 'a.md']);
      final log = await check.log('a.md');
      expect(log.single.message, 'chore: impor vault');
      final docs = await HubDocument.db.find(sessionBuilder.build());
      expect(docs.map((d) => d.path), ['a.md']);
    });

    test('import_strips_root_and_blocks_zip_slip', () async {
      final hub = await endpoints.hub.create(me, 'Z', remoteUrl: remote);
      await endpoints.hub.importVault(
        me,
        hub.id!,
        zipOf({
          'wiki-angkasa/PKM/a.md': '# A\n',
          'wiki-angkasa/../../jahat.md': 'x',
        }),
      );
      final check = await GitRepo.clone(remote, await tempDir(), branch: 'main');
      expect(await check.listFiles(), ['PKM/a.md']);
      expect(File('${Directory.systemTemp.path}/jahat.md').existsSync(), isFalse);
    });

    test('non_member_rejected', () async {
      final hub = await endpoints.hub.create(me, 'P', remoteUrl: remote);
      await expectLater(
        endpoints.hub.reindex(asUser(sessionBuilder, other), hub.id!),
        throwsA(isA<WhiskerException>()),
      );
    });
  });
}
