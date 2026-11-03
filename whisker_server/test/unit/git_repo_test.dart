import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/git/git_repo.dart';
import 'package:whisker_server/src/git/hub_locks.dart';
import 'package:serverpod/serverpod.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/hub/hub_service.dart';

import 'git_test_helpers.dart';

void main() {
  test('clone_commit_push', () async {
    final remote = await bareRemote();
    final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    expect(await repo.head(), isNull);
    await repo.writeFile('PKM/a.md', '# A\n');
    final sha = await repo.commitAll(
      'a',
      author: testAuthor,
      committer: testBot,
    );
    expect(await repo.push(remote, 'main'), isTrue);
    expect(await repo.remoteHead(remote, 'main'), sha);
    expect(await repo.head(), sha);
  });

  test('blob_and_show', () async {
    final remote = await bareRemote();
    final sha = await pushFiles(remote, {'a.md': 'isi\r\nCRLF'});
    final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    expect(await repo.show(sha, 'a.md'), 'isi\r\nCRLF');
    expect(await repo.blobAt(sha, 'a.md'), hasLength(40));
    expect(await repo.blobAt(sha, 'tidak.md'), isNull);
    expect(await repo.show(sha, 'tidak.md'), isNull);
    expect(await repo.lastCommitFor('a.md'), sha);
  });

  test('changed_paths', () async {
    final remote = await bareRemote();
    final s1 = await pushFiles(remote, {'a.md': '1', 'b.md': '1'});
    await pushFiles(remote, {'a.md': '2', 'b.md': null, 'c d.md': '1'});
    final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    final head = (await repo.head())!;
    expect((await repo.changedPaths(s1, head))..sort(), [
      'a.md',
      'b.md',
      'c d.md',
    ]);
    expect((await repo.changedPaths(null, head))..sort(), ['a.md', 'c d.md']);
    expect((await repo.listFiles())..sort(), ['a.md', 'c d.md']);
  });

  test('push_rejected_then_rebase', () async {
    final remote = await bareRemote();
    await pushFiles(remote, {'a.md': '1'});
    final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    await pushFiles(remote, {'b.md': 'dari PC'});
    await repo.writeFile('a.md', '2');
    await repo.commitAll('ubah a', author: testAuthor, committer: testBot);
    expect(await repo.push(remote, 'main'), isFalse);
    await repo.fetch(remote, 'main');
    expect(await repo.rebaseOnto('origin/main', committer: testBot), isTrue);
    expect(await repo.push(remote, 'main'), isTrue);
    final check = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    expect(await File('${check.dir}/b.md').readAsString(), 'dari PC');
    expect(await File('${check.dir}/a.md').readAsString(), '2');
  });

  test('log_for_path', () async {
    final remote = await bareRemote();
    await pushFiles(remote, {'a.md': '1'});
    await pushFiles(remote, {'b.md': '1'});
    await pushFiles(remote, {'a.md': '2'});
    final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    final log = await repo.log('a.md');
    expect(log, hasLength(2));
    expect(log.first.message, 'uji: ubah a.md');
    expect(log.first.authorName, 'Uji');
  });

  test('archive_zip_has_files', () async {
    final remote = await bareRemote();
    await pushFiles(remote, {'PKM/a.md': 'x'});
    final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
    final zip = ZipDecoder().decodeBytes(await repo.archiveZip());
    expect(zip.files.where((f) => f.isFile).map((f) => f.name), ['PKM/a.md']);
  });

  test('hub_locks_serializes', () async {
    final locks = HubLocks();
    final events = <String>[];
    Future<void> job(int hub, String name) => locks.run(hub, () async {
      events.add('$name+');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      events.add('$name-');
    });
    await Future.wait([job(1, 'a'), job(1, 'b'), job(2, 'c')]);
    final a = events.indexOf('a-'), b = events.indexOf('b+');
    expect(a < b, isTrue);
    expect(events.indexOf('c+') < events.indexOf('a-'), isTrue);
  });

  test('error_hides_token', () async {
    final repo = GitRepo(await tempDir());
    try {
      await repo.fetch(
        'https://x-access-token:RAHASIA@127.0.0.1:1/a.git',
        'main',
      );
      fail('harus gagal');
    } on GitException catch (e) {
      expect(e.toString(), isNot(contains('RAHASIA')));
    }
  });

  test('repo_for_concurrent_first_clone', () async {
    final remote = await bareRemote();
    await pushFiles(remote, {'a.md': '1'});
    final svc = HubService(dataDir: await tempDir(), allowLocalRemotes: true);
    final hub = Hub(
      id: 7,
      name: 'h',
      slug: 'h',
      remoteUrl: remote,
      ownerId: const Uuid().v4obj(),
    );
    final repos = await Future.wait([svc.repoFor(hub), svc.repoFor(hub)]);
    expect(await repos[0].show('HEAD', 'a.md'), '1');
    expect(await repos[1].show('HEAD', 'a.md'), '1');
  });
}
