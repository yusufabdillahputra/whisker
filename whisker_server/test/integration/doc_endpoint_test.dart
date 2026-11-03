import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/git/git_repo.dart';

import '../unit/git_test_helpers.dart';
import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

const adr = '---\ntype: adr\nstatus: accepted\n---\n# ADR-001 Kunci\n\nIsi.\n';

void main() {
  withServerpod('DocEndpoint', (sessionBuilder, endpoints) {
    final owner = const Uuid().v4obj();
    late TestSessionBuilder me;
    late String remote;
    late Hub hub;

    setUp(() async {
      await setUpHubService(sessionBuilder);
      me = asUser(sessionBuilder, owner);
      remote = await bareRemote();
      await pushFiles(remote, {
        'PKM/ADR/ADR-001.md': adr,
        'Kucing.md': '# Kucing Calico\n\nTiga warna bulu.\n',
        'Catatan.md': '# Catatan\n\nTentang kucing di [[Kucing]].\n',
      });
      hub = await endpoints.hub.create(me, 'Uji', remoteUrl: remote);
    });

    Future<String> remoteFile(String path) async {
      final c = await GitRepo.clone(remote, await tempDir(), branch: 'main');
      return File('${c.dir}/$path').readAsString();
    }

    CommitRequest req(
      String path,
      String content,
      String? base, {
      String message = 'ubah',
    }) => CommitRequest(
      hubId: hub.id!,
      path: path,
      content: content,
      message: message,
      baseSha: base,
    );

    test('tree_and_read', () async {
      final tree = await endpoints.doc.tree(me, hub.id!);
      expect(tree.map((d) => d.path), [
        'Catatan.md',
        'Kucing.md',
        'PKM/ADR/ADR-001.md',
      ]);
      final doc = await endpoints.doc.read(me, hub.id!, 'Kucing.md');
      expect(doc.content, '# Kucing Calico\n\nTiga warna bulu.\n');
      expect(doc.baseSha, isNotNull);
      expect(doc.readOnlyReason, isNull);
      final a = await endpoints.doc.read(me, hub.id!, 'PKM/ADR/ADR-001.md');
      expect(a.readOnlyReason, isNotNull);
    });

    test('search_ranks_title_first', () async {
      final hits = await endpoints.doc.search(me, hub.id!, 'kucing');
      expect(hits.map((h) => h.path), ['Kucing.md', 'Catatan.md']);
      expect(hits[1].snippet, contains('kucing'));
    });

    test('backlinks', () async {
      final b = await endpoints.doc.backlinks(me, hub.id!, 'Kucing.md');
      expect(b.map((d) => d.path), ['Catatan.md']);
    });

    test('commit_ok_updates_remote_and_index', () async {
      final doc = await endpoints.doc.read(me, hub.id!, 'Kucing.md');
      final r = await endpoints.doc.commit(
        me,
        req('Kucing.md', '# Kucing Oranye\n', doc.baseSha),
      );
      expect(r.status, 'ok');
      expect(await remoteFile('Kucing.md'), '# Kucing Oranye\n');
      final tree = await endpoints.doc.tree(me, hub.id!);
      expect(
        tree.firstWhere((d) => d.path == 'Kucing.md').title,
        'Kucing Oranye',
      );
      final hist = await endpoints.doc.history(me, hub.id!, 'Kucing.md');
      expect(hist.first.sha, r.newSha);
      expect(hist.first.message, 'ubah');
    });

    test('commit_conflict_when_file_changed_remotely', () async {
      final doc = await endpoints.doc.read(me, hub.id!, 'Kucing.md');
      await pushFiles(remote, {'Kucing.md': '# Dari PC\n'});
      final r = await endpoints.doc.commit(
        me,
        req('Kucing.md', '# Dari app\n', doc.baseSha),
      );
      expect(r.status, 'conflict');
      expect(r.latestContent, '# Dari PC\n');
      expect(await remoteFile('Kucing.md'), '# Dari PC\n');
      final retry = await endpoints.doc.commit(
        me,
        req('Kucing.md', '# Gabungan\n', r.latestSha),
      );
      expect(retry.status, 'ok');
    });

    test('remote_advanced_other_file_rebases', () async {
      final doc = await endpoints.doc.read(me, hub.id!, 'Kucing.md');
      await pushFiles(remote, {'Lain.md': '# Lain\n'});
      final r = await endpoints.doc.commit(
        me,
        req('Kucing.md', '# Baru\n', doc.baseSha),
      );
      expect(r.status, 'ok');
      expect(await remoteFile('Lain.md'), '# Lain\n');
      expect(await remoteFile('Kucing.md'), '# Baru\n');
    });

    test('adr_accepted_rejected', () async {
      final doc = await endpoints.doc.read(me, hub.id!, 'PKM/ADR/ADR-001.md');
      final r = await endpoints.doc.commit(
        me,
        req(
          'PKM/ADR/ADR-001.md',
          adr.replaceFirst('Isi.', 'Diubah.'),
          doc.baseSha,
        ),
      );
      expect(r.status, 'rejected');
      expect(r.reason, contains('ADR'));
    });

    test('rejects_unsafe_paths', () async {
      for (final p in ['../x.md', '/etc/x.md', 'a.txt', 'a/../../b.md']) {
        await expectLater(
          endpoints.doc.commit(me, req(p, 'x', null)),
          throwsA(isA<WhiskerException>()),
          reason: p,
        );
      }
    });

    test('default_message', () async {
      final r = await endpoints.doc.commit(
        me,
        req('Baru.md', '# Dokumen Baru\n', null, message: ''),
      );
      expect(r.status, 'ok');
      final hist = await endpoints.doc.history(me, hub.id!, 'Baru.md');
      expect(hist.single.message, 'docs(other): update Dokumen Baru');
    });
  });

  // Dua commit paralel butuh koneksi DB paralel, jadi tanpa rollback;
  // data dibersihkan manual.
  withServerpod(
    'DocEndpoint paralel',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      final owner = const Uuid().v4obj();
      late TestSessionBuilder me;
      late Hub hub;

      setUp(() async {
        await setUpHubService(sessionBuilder);
        me = asUser(sessionBuilder, owner);
        final remote = await bareRemote();
        await pushFiles(remote, {'Kucing.md': '# Kucing\n'});
        hub = await endpoints.hub.create(
          me,
          'Paralel ${owner.uuid}',
          remoteUrl: remote,
        );
      });

      tearDown(() async {
        final s = sessionBuilder.build();
        final docs = await HubDocument.db.find(
          s,
          where: (d) => d.hubId.equals(hub.id!),
        );
        await DocumentLink.db.deleteWhere(
          s,
          where: (l) => l.hubId.equals(hub.id!),
        );
        await HubDocument.db.delete(s, docs);
        await HubMember.db.deleteWhere(
          s,
          where: (m) => m.hubId.equals(hub.id!),
        );
        await Hub.db.deleteRow(s, hub);
      });

      CommitRequest req(String content, String? base) => CommitRequest(
        hubId: hub.id!,
        path: 'Kucing.md',
        content: content,
        message: 'ubah',
        baseSha: base,
      );

      test('concurrent_commits_serialized', () async {
        final doc = await endpoints.doc.read(me, hub.id!, 'Kucing.md');
        final rs = await Future.wait([
          endpoints.doc.commit(me, req('# Satu\n', doc.baseSha)),
          endpoints.doc.commit(me, req('# Dua\n', doc.baseSha)),
        ]);
        expect(rs.map((r) => r.status).toList()..sort(), ['conflict', 'ok']);
      });
    },
  );
}
