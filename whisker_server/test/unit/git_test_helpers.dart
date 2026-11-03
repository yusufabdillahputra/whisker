import 'dart:io';

import 'package:whisker_server/src/git/git_repo.dart';

const testAuthor = GitIdentity('Uji', 'uji@example.com');
const testBot = GitIdentity('Whisker', 'bot@whisker.local');

/// Repo bare kosong di temp dir; mengembalikan path-nya.
Future<String> bareRemote() async {
  final dir = await Directory.systemTemp.createTemp('whisker-remote-');
  await Process.run('git', ['init', '--bare', '-b', 'main', dir.path]);
  return dir.path;
}

Future<String> tempDir([String p = 'whisker-work-']) async =>
    (await Directory.systemTemp.createTemp(p)).path;

/// Membuat commit langsung ke [remote] lewat clone sementara.
Future<String> pushFiles(String remote, Map<String, String?> files) async {
  final repo = await GitRepo.clone(remote, await tempDir(), branch: 'main');
  for (final e in files.entries) {
    if (e.value == null) {
      await File('${repo.dir}/${e.key}').delete();
    } else {
      await repo.writeFile(e.key, e.value!);
    }
  }
  final sha = await repo.commitAll(
    'uji: ubah ${files.keys.join(', ')}',
    author: testAuthor,
    committer: testAuthor,
  );
  if (!await repo.push(remote, 'main')) throw StateError('push gagal');
  return sha;
}
