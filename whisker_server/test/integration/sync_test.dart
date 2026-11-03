import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/sync/remote_sync.dart';

import '../unit/git_test_helpers.dart';
import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

Map<String, String> signed(
  String secret,
  List<int> body, {
  String event = 'push',
}) => {
  'x-github-event': event,
  'x-hub-signature-256':
      'sha256=${Hmac(sha256, utf8.encode(secret)).convert(body)}',
};

void main() {
  withServerpod('Sinkron', (sessionBuilder, endpoints) {
    final owner = const Uuid().v4obj();
    late TestSessionBuilder me;
    late String remote;
    late Hub hub;
    late Session s;

    setUp(() async {
      await setUpHubService(sessionBuilder);
      me = asUser(sessionBuilder, owner);
      s = sessionBuilder.build();
      remote = await bareRemote();
      await pushFiles(remote, {'a.md': '# A\n'});
      hub = await endpoints.hub.create(
        me,
        'Sinkron',
        githubRepo: 'org/sinkron-${owner.uuid}',
        remoteUrl: remote,
      );
    });

    test('sync_after_external_push', () async {
      await pushFiles(remote, {'Dari PC.md': '# Dari PC\n'});
      final change = await syncFromRemote(s, hub);
      expect(change!.paths, ['Dari PC.md']);
      final docs = await endpoints.doc.tree(me, hub.id!);
      expect(docs.map((d) => d.path), ['Dari PC.md', 'a.md']);
      expect((await Hub.db.findById(s, hub.id!))!.headSha, change.headSha);
    });

    test('sync_noop_when_same', () async {
      expect(await syncFromRemote(s, hub), isNull);
    });

    test('reconcile_counts', () async {
      await pushFiles(remote, {'b.md': '# B\n'});
      expect(await reconcileAll(s), 1);
      expect(await reconcileAll(s), 0);
    });

    test('webhook_rejects_bad_signature', () async {
      final body = utf8.encode('{}');
      final (code, _) = await handleGithubWebhook(
        s,
        {'x-github-event': 'push', 'x-hub-signature-256': 'sha256=00'},
        body,
        'rahasia',
      );
      expect(code, 401);
      final (code2, msg) = await handleGithubWebhook(
        s,
        signed('rahasia', body, event: 'ping'),
        body,
        'rahasia',
      );
      expect((code2, msg), (202, 'ignored'));
    });

    test('webhook_push_syncs', () async {
      await pushFiles(remote, {'c.md': '# C\n'});
      final body = utf8.encode(
        jsonEncode({
          'ref': 'refs/heads/main',
          'repository': {'full_name': hub.githubRepo},
        }),
      );
      final (code, msg) = await handleGithubWebhook(
        s,
        signed('k', body),
        body,
        'k',
      );
      expect((code, msg), (200, 'synced'));
      final docs = await endpoints.doc.tree(me, hub.id!);
      expect(docs.map((d) => d.path), contains('c.md'));
      final other = utf8.encode(
        jsonEncode({
          'ref': 'refs/heads/main',
          'repository': {'full_name': 'org/tidak-dikenal'},
        }),
      );
      expect(
        (await handleGithubWebhook(s, signed('k', other), other, 'k')).$1,
        202,
      );
    });

    test('watch_receives_change', () async {
      final events = endpoints.hub.watch(me, hub.id!);
      final first = events.first;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final doc = await endpoints.doc.read(me, hub.id!, 'a.md');
      await endpoints.doc.commit(
        me,
        CommitRequest(
          hubId: hub.id!,
          path: 'a.md',
          content: '# A2\n',
          message: 'ubah',
          baseSha: doc.baseSha,
        ),
      );
      final change = await first.timeout(const Duration(seconds: 5));
      expect(change.paths, ['a.md']);
    });
  });
}
