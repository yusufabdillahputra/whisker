import 'dart:io';

import 'package:whisker_client/whisker_client.dart';

enum SyncState { cloned, updated, upToDate, localChanges, error }

class SyncStatus {
  final SyncState state;
  final String? detail;
  const SyncStatus(this.state, [this.detail]);
}

/// Menyinkronkan clone lokal Hub di `<root>/<slug>` agar Claude Code bisa
/// grep file markdown. Tidak pernah menimpa perubahan lokal: folder dengan
/// file belum di-commit atau commit belum di-push dilaporkan apa adanya.
class LocalSync {
  final String root;
  LocalSync(this.root);

  String dirFor(Hub hub) => '$root${Platform.pathSeparator}${hub.slug}';

  Future<ProcessResult> _git(List<String> args, {String? cwd}) =>
      Process.run('git', args, workingDirectory: cwd);

  Future<String> _ok(List<String> args, {String? cwd}) async {
    final r = await _git(args, cwd: cwd);
    if (r.exitCode != 0) {
      throw ProcessException('git', args, '${r.stderr}'.trim(), r.exitCode);
    }
    return '${r.stdout}'.trim();
  }

  Future<SyncStatus> syncHub(Hub hub) async {
    final dir = dirFor(hub);
    try {
      if (hub.remoteUrl.startsWith('-')) {
        return const SyncStatus(SyncState.error, 'URL remote tidak valid.');
      }
      if (!await Directory(dir).exists()) {
        await Directory(root).create(recursive: true);
        await _ok([
          'clone',
          '--branch',
          hub.defaultBranch,
          '--',
          hub.remoteUrl,
          dir,
        ]);
        return const SyncStatus(SyncState.cloned);
      }
      if (!await Directory('$dir${Platform.pathSeparator}.git').exists()) {
        return const SyncStatus(
          SyncState.error,
          'Folder sudah ada tetapi bukan repo git.',
        );
      }
      if ((await _ok(['status', '--porcelain'], cwd: dir)).isNotEmpty) {
        return const SyncStatus(
          SyncState.localChanges,
          'Ada file yang belum di-commit.',
        );
      }
      await _ok(['fetch', 'origin'], cwd: dir);
      final ahead = await _ok(['rev-list', '@{u}..HEAD'], cwd: dir);
      if (ahead.isNotEmpty) {
        return const SyncStatus(
          SyncState.localChanges,
          'Ada commit lokal yang belum di-push.',
        );
      }
      final before = await _ok(['rev-parse', 'HEAD'], cwd: dir);
      await _ok(['merge', '--ff-only', '@{u}'], cwd: dir);
      final after = await _ok(['rev-parse', 'HEAD'], cwd: dir);
      return SyncStatus(
        before == after ? SyncState.upToDate : SyncState.updated,
      );
    } on ProcessException catch (e) {
      return SyncStatus(SyncState.error, e.message);
    } on FileSystemException catch (e) {
      return SyncStatus(SyncState.error, e.message);
    }
  }
}
