import 'dart:convert';
import 'dart:io';

import '../generated/protocol.dart';

/// Identitas author/committer git.
class GitIdentity {
  final String name;
  final String email;
  const GitIdentity(this.name, this.email);
}

/// Perintah git gagal. Kredensial di URL tidak pernah ikut dalam pesan.
class GitException implements Exception {
  final String command;
  final String stderr;
  GitException(String command, String stderr)
    : command = redactUrl(command),
      stderr = redactUrl(stderr);

  @override
  String toString() => 'GitException: git $command\n$stderr';
}

final _cred = RegExp(r'//[^/@\s]+@');

/// Mengganti `//user:token@` di URL dengan `//***@`.
String redactUrl(String s) => s.replaceAll(_cred, '//***@');

/// Pembungkus `git` sistem untuk satu clone kerja di [dir].
///
/// URL remote selalu diberikan per panggilan (token GitHub App berumur
/// pendek), sedangkan ref remote disimpan sebagai `origin/<branch>`.
class GitRepo {
  final String dir;
  GitRepo(this.dir);

  static const _base = [
    '-c',
    'core.quotepath=off',
    '-c',
    'core.autocrlf=false',
  ];

  Future<ProcessResult> _raw(
    List<String> args, {
    bool binary = false,
    Map<String, String>? env,
  }) => Process.run(
    'git',
    [..._base, ...args],
    workingDirectory: dir,
    environment: {
      'GIT_TERMINAL_PROMPT': '0',
      // Abaikan konfigurasi git host agar perilaku sama di semua mesin.
      'GIT_CONFIG_GLOBAL': '/dev/null',
      'GIT_CONFIG_NOSYSTEM': '1',
      ...?env,
    },
    stdoutEncoding: binary ? null : utf8,
    stderrEncoding: utf8,
  );

  Future<String> _git(List<String> args, {Map<String, String>? env}) async {
    final r = await _raw(args, env: env);
    if (r.exitCode != 0) {
      throw GitException(args.join(' '), '${r.stderr}');
    }
    return r.stdout as String;
  }

  /// Membuat clone kerja di [dir] dari [url]; remote kosong diperbolehkan.
  static Future<GitRepo> clone(
    String url,
    String dir, {
    String branch = 'main',
  }) async {
    final repo = GitRepo(dir);
    await repo.initEmpty(branch);
    if (await repo.remoteHead(url, branch) != null) {
      await repo.fetch(url, branch);
      await repo.resetHard('origin/$branch');
    }
    return repo;
  }

  /// `git init` dengan branch awal [branch].
  Future<void> initEmpty(String branch) async {
    await Directory(dir).create(recursive: true);
    await _git(['init', '-q', '-b', branch]);
  }

  /// SHA `HEAD`, atau `null` bila belum ada commit.
  Future<String?> head() async {
    final r = await _raw(['rev-parse', '--verify', '-q', 'HEAD']);
    return r.exitCode == 0 ? (r.stdout as String).trim() : null;
  }

  /// Menolak URL yang bisa dibaca git sebagai opsi atau transport `ext::`.
  static String _url(String url) {
    if (url.startsWith('-') || url.contains('::')) {
      throw GitException('remote', 'URL remote tidak valid');
    }
    return url;
  }

  /// `true` bila salah satu segmen [path] (relatif ke [dir]) adalah symlink.
  Future<bool> hasSymlinkOnPath(String path) async {
    var cur = dir;
    for (final seg in path.split('/')) {
      cur = '$cur/$seg';
      final type = await FileSystemEntity.type(cur, followLinks: false);
      if (type == FileSystemEntityType.link) return true;
      if (type == FileSystemEntityType.notFound) return false;
    }
    return false;
  }

  Future<void> _ensureInside(String path) async {
    if (await hasSymlinkOnPath(path)) {
      throw GitException('write', 'Path melewati symlink: $path');
    }
  }

  Future<void> fetch(String url, String branch) => _git([
    'fetch',
    '-q',
    _url(url),
    '+refs/heads/$branch:refs/remotes/origin/$branch',
  ]);

  /// SHA branch di remote lewat `ls-remote`, atau `null` bila belum ada.
  Future<String?> remoteHead(String url, String branch) async {
    final out = await _git(['ls-remote', _url(url), 'refs/heads/$branch']);
    final line = out.trim();
    return line.isEmpty ? null : line.split(RegExp(r'\s+')).first;
  }

  /// SHA dari [rev], atau `null` bila tidak ada.
  Future<String?> revParse(String rev) async {
    final r = await _raw(['rev-parse', '-q', '--verify', '$rev^{commit}']);
    return r.exitCode == 0 ? (r.stdout as String).trim() : null;
  }

  /// SHA blob [path] di [rev], atau `null` bila tidak ada.
  Future<String?> blobAt(String rev, String path) async {
    final r = await _raw(['rev-parse', '-q', '--verify', '$rev:$path']);
    return r.exitCode == 0 ? (r.stdout as String).trim() : null;
  }

  /// Isi [path] di [rev] (UTF-8), atau `null` bila tidak ada.
  Future<String?> show(String rev, String path) async {
    final r = await _raw(['show', '$rev:$path'], binary: true);
    if (r.exitCode != 0) return null;
    return utf8.decode(r.stdout as List<int>, allowMalformed: true);
  }

  /// Commit terakhir yang menyentuh [path].
  Future<String?> lastCommitFor(String path, {String rev = 'HEAD'}) async {
    if (await revParse(rev) == null) return null;
    final out = (await _git([
      'log',
      '-1',
      '--format=%H',
      rev,
      '--',
      path,
    ])).trim();
    return out.isEmpty ? null : out;
  }

  /// Menulis [content] persis apa adanya ke [path] di working tree.
  Future<void> writeFile(String path, String content) async {
    await _ensureInside(path);
    final f = File('$dir/$path');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(utf8.encode(content), flush: true);
  }

  /// Menulis byte mentah ke [path] di working tree.
  Future<void> writeBytes(String path, List<int> bytes) async {
    await _ensureInside(path);
    final f = File('$dir/$path');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(bytes, flush: true);
  }

  /// `git add -A` lalu commit; mengembalikan SHA baru.
  Future<String> commitAll(
    String message, {
    required GitIdentity author,
    required GitIdentity committer,
  }) async {
    await _git(['add', '-A']);
    await _git(
      [
        'commit',
        '-q',
        '--no-verify',
        '-m',
        message,
        '--author',
        '${author.name} <${author.email}>',
      ],
      env: {
        'GIT_COMMITTER_NAME': committer.name,
        'GIT_COMMITTER_EMAIL': committer.email,
      },
    );
    return (await head())!;
  }

  /// Push `HEAD` ke [branch]; `false` bila ditolak karena remote maju.
  Future<bool> push(String url, String branch) async {
    final args = ['push', '-q', _url(url), 'HEAD:refs/heads/$branch'];
    final r = await _raw(args);
    if (r.exitCode == 0) {
      await _git(['update-ref', 'refs/remotes/origin/$branch', 'HEAD']);
      return true;
    }
    final err = '${r.stderr}';
    if (err.contains('rejected') || err.contains('fetch first')) return false;
    throw GitException(args.join(' '), err);
  }

  /// Rebase ke [rev] dengan [committer] sebagai committer commit yang
  /// diterapkan ulang; bila konflik dibatalkan dan mengembalikan `false`.
  Future<bool> rebaseOnto(String rev, {required GitIdentity committer}) async {
    final r = await _raw(
      ['rebase', '-q', rev],
      env: {
        'GIT_COMMITTER_NAME': committer.name,
        'GIT_COMMITTER_EMAIL': committer.email,
      },
    );
    if (r.exitCode == 0) return true;
    await _raw(['rebase', '--abort']);
    return false;
  }

  Future<void> resetHard(String rev) async {
    await _git(['reset', '-q', '--hard', rev]);
    await _git(['clean', '-q', '-fd']);
  }

  /// Menghapus file yang cocok `.gitignore` dari working tree.
  Future<void> removeIgnored() => _git(['clean', '-q', '-fdX']);

  /// Path yang berubah antara [from] dan [to]; [from] `null` = semua file di [to].
  Future<List<String>> changedPaths(String? from, String to) async {
    final out = from == null
        ? await _git(['ls-tree', '-r', '-z', '--name-only', to])
        : await _git(['diff', '--no-renames', '--name-only', '-z', from, to]);
    return out.split('\x00').where((p) => p.isNotEmpty).toList();
  }

  /// Semua file yang dilacak di working tree.
  Future<List<String>> listFiles() async {
    final out = await _git(['ls-files', '-z']);
    return out.split('\x00').where((p) => p.isNotEmpty).toList();
  }

  /// Riwayat commit yang menyentuh [path], terbaru dulu.
  Future<List<HistoryEntry>> log(String path, {int limit = 50}) async {
    if (await head() == null) return [];
    final out = await _git([
      'log',
      '-n',
      '$limit',
      '--format=%H%x1f%s%x1f%an%x1f%aI%x1e',
      '--',
      path,
    ]);
    return [
      for (final rec in out.split('\x1e'))
        if (rec.trim().isNotEmpty)
          () {
            final f = rec.trim().split('\x1f');
            return HistoryEntry(
              sha: f[0],
              message: f[1],
              authorName: f[2],
              date: DateTime.parse(f[3]).toUtc(),
            );
          }(),
    ];
  }

  /// `git archive --format=zip HEAD`.
  Future<List<int>> archiveZip() async {
    final r = await _raw(['archive', '--format=zip', 'HEAD'], binary: true);
    if (r.exitCode != 0) throw GitException('archive', '${r.stderr}');
    return r.stdout as List<int>;
  }
}
