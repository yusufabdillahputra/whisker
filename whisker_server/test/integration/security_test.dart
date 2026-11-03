import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/git/git_repo.dart';
import 'package:whisker_server/src/github/remote_access.dart';
import 'package:whisker_server/src/hub/hub_service.dart';

import '../unit/git_test_helpers.dart';
import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

/// URL benar untuk [okCalls] panggilan pertama, lalu URL rusak.
class FlakyRemote extends RemoteAccess {
  int calls = 0;
  int okCalls = 1 << 30;
  @override
  Future<String> urlFor(Hub hub) async =>
      ++calls <= okCalls ? hub.remoteUrl : '/tidak/ada/repo.git';
}

void main() {
  test('validate_remote_url', () {
    expect(validateRemoteUrl('https://github.com/org/repo.git'), isNull);
    expect(validateRemoteUrl('https://github.com/org/repo'), isNull);
    expect(validateRemoteUrl('--upload-pack=touch x'), isNotNull);
    expect(validateRemoteUrl('/srv/repo.git'), isNotNull);
    expect(validateRemoteUrl('/srv/repo.git', allowLocal: true), isNull);
    expect(validateRemoteUrl('-x', allowLocal: true), isNotNull);
    expect(validateRemoteUrl('ext::sh -c id', allowLocal: true), isNotNull);
  });

  withServerpod('Keamanan', (sessionBuilder, endpoints) {
    final owner = const Uuid().v4obj();
    late TestSessionBuilder me;

    setUp(() async {
      await setUpHubService(sessionBuilder);
      me = asUser(sessionBuilder, owner);
    });

    test('rejects_option_injection_remote', () async {
      final marker = '${await tempDir()}/PWNED';
      await expectLater(
        endpoints.hub.create(
          me,
          'x',
          remoteUrl: '--upload-pack=touch $marker;',
        ),
        throwsA(isA<WhiskerException>()),
      );
      expect(File(marker).existsSync(), isFalse);
    });

    test('rejects_local_remote_in_production', () async {
      HubService.instance = HubService(dataDir: await tempDir());
      await expectLater(
        endpoints.hub.create(me, 'x', remoteUrl: await bareRemote()),
        throwsA(isA<WhiskerException>()),
      );
    });

    test('rejects_write_through_symlink_and_dot_git', () async {
      final outside = await tempDir('whisker-outside-');
      final remote = await bareRemote();
      final work = await GitRepo.clone(remote, await tempDir(), branch: 'main');
      await Link('${work.dir}/evil').create(outside);
      await work.writeFile('a.md', '# A\n');
      await work.commitAll(
        'symlink',
        author: testAuthor,
        committer: testAuthor,
      );
      await work.push(remote, 'main');
      final hub = await endpoints.hub.create(me, 'Sym', remoteUrl: remote);
      for (final p in ['evil/x.md', '.git/x.md']) {
        await expectLater(
          endpoints.doc.commit(
            me,
            CommitRequest(hubId: hub.id!, path: p, content: 'x', message: 'm'),
          ),
          throwsA(isA<WhiskerException>()),
          reason: p,
        );
      }
      expect(File('$outside/x.md').existsSync(), isFalse);
    });

    test('push_exception_resets_local', () async {
      final flaky = FlakyRemote();
      HubService.instance = HubService(
        dataDir: await tempDir(),
        remote: flaky,
        allowLocalRemotes: true,
      );
      final remote = await bareRemote();
      await pushFiles(remote, {'a.md': '# A\n'});
      final hub = await endpoints.hub.create(me, 'Flaky', remoteUrl: remote);
      final doc = await endpoints.doc.read(me, hub.id!, 'a.md');
      flaky.okCalls = flaky.calls + 1;
      await expectLater(
        endpoints.doc.commit(
          me,
          CommitRequest(
            hubId: hub.id!,
            path: 'a.md',
            content: '# B\n',
            message: 'm',
            baseSha: doc.baseSha,
          ),
        ),
        throwsA(
          isA<WhiskerException>().having(
            (e) => e.message,
            'message',
            contains('Push gagal'),
          ),
        ),
      );
      final local = GitRepo(HubService.instance.repoDir(hub.id!));
      expect(await local.head(), await local.remoteHead(remote, 'main'));
    });
  });
}
