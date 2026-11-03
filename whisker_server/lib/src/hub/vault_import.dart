import 'package:archive/archive.dart';

import '../git/git_repo.dart';

/// Path relatif yang aman: tidak absolut dan tanpa segmen `..`.
bool isSafeRelative(String path) =>
    path.isNotEmpty &&
    !path.startsWith('/') &&
    !RegExp(r'^[A-Za-z]:').hasMatch(path) &&
    !path.split('/').contains('..');

bool _skipped(String path) {
  final seg = path.split('/');
  return seg.contains('.obsidian') ||
      seg.contains('.git') ||
      path == '.claude/settings.local.json';
}

/// Mengekstrak vault zip ke working tree [repo]; folder akar tunggal di-strip,
/// entri yang tidak aman atau dibuang (`.obsidian/`, `.git/`,
/// `.claude/settings.local.json`) dilewati. Mengembalikan jumlah file ditulis.
Future<int> extractVault(GitRepo repo, List<int> zipBytes) async {
  final files = ZipDecoder()
      .decodeBytes(zipBytes)
      .files
      .where((f) => f.isFile)
      .map((f) => (f.name.replaceAll('\\', '/'), f))
      .toList();
  final firsts = files.map((e) => e.$1.split('/').first).toSet();
  final strip = firsts.length == 1 && files.every((e) => e.$1.contains('/'));
  var n = 0;
  for (final (name, f) in files) {
    final path = strip ? name.substring(name.indexOf('/') + 1) : name;
    if (!isSafeRelative(path) || _skipped(path)) continue;
    if (await repo.hasSymlinkOnPath(path)) continue;
    await repo.writeBytes(path, f.content);
    n++;
  }
  return n;
}
