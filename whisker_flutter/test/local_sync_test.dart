import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:whisker/features/local_sync/local_sync.dart';
import 'package:whisker/features/local_sync/local_sync_panel.dart';
import 'package:whisker_client/whisker_client.dart';

Future<String> git(String dir, List<String> args) async {
  final r = await Process.run('git', [
    '-c',
    'user.name=Uji',
    '-c',
    'user.email=uji@contoh.test',
    '-c',
    'init.defaultBranch=main',
    ...args,
  ], workingDirectory: dir);
  if (r.exitCode != 0) throw StateError('git $args: ${r.stderr}');
  return (r.stdout as String).trim();
}

/// Remote bare + clone "PC lain" untuk mendorong perubahan.
Future<({String remote, String pc})> setUpRemote() async {
  final tmp = await Directory.systemTemp.createTemp('whisker-sync-');
  addTearDown(() => tmp.delete(recursive: true));
  final remote = '${tmp.path}/remote.git';
  await git(tmp.path, ['init', '--bare', '-b', 'main', remote]);
  final pc = '${tmp.path}/pc';
  await git(tmp.path, ['clone', remote, pc]);
  await File('$pc/README.md').writeAsString('# Satu\n');
  await git(pc, ['add', '-A']);
  await git(pc, ['commit', '-m', 'awal']);
  await git(pc, ['push', 'origin', 'HEAD:main']);
  return (remote: remote, pc: pc);
}

Hub hubAt(String remote) => Hub(
  id: 1,
  name: 'Uji',
  slug: 'uji',
  remoteUrl: remote,
  defaultBranch: 'main',
  ownerId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
);

void main() {
  queueTests();

  test('clones_then_fast_forwards', () async {
    final r = await setUpRemote();
    final root = await Directory.systemTemp.createTemp('whisker-root-');
    addTearDown(() => root.delete(recursive: true));
    final sync = LocalSync(root.path);
    final hub = hubAt(r.remote);

    expect((await sync.syncHub(hub)).state, SyncState.cloned);
    expect(File('${root.path}/uji/README.md').readAsStringSync(), '# Satu\n');
    expect((await sync.syncHub(hub)).state, SyncState.upToDate);

    await File('${r.pc}/README.md').writeAsString('# Dua\n');
    await git(r.pc, ['commit', '-am', 'dua']);
    await git(r.pc, ['push', 'origin', 'HEAD:main']);
    expect((await sync.syncHub(hub)).state, SyncState.updated);
    expect(File('${root.path}/uji/README.md').readAsStringSync(), '# Dua\n');
  });

  test('local_changes_untouched', () async {
    final r = await setUpRemote();
    final root = await Directory.systemTemp.createTemp('whisker-root-');
    addTearDown(() => root.delete(recursive: true));
    final sync = LocalSync(root.path);
    final hub = hubAt(r.remote);
    await sync.syncHub(hub);
    final local = '${root.path}/uji';

    // Remote maju.
    await File('${r.pc}/README.md').writeAsString('# Dua\n');
    await git(r.pc, ['commit', '-am', 'dua']);
    await git(r.pc, ['push', 'origin', 'HEAD:main']);

    // File lokal belum di-commit.
    await File('$local/Catatan.md').writeAsString('lokal\n');
    final s1 = await sync.syncHub(hub);
    expect(s1.state, SyncState.localChanges);
    expect(File('$local/README.md').readAsStringSync(), '# Satu\n');
    expect(File('$local/Catatan.md').readAsStringSync(), 'lokal\n');

    // Commit lokal belum di-push.
    await git(local, ['add', '-A']);
    await git(local, ['commit', '-m', 'lokal']);
    final head = await git(local, ['rev-parse', 'HEAD']);
    final s2 = await sync.syncHub(hub);
    expect(s2.state, SyncState.localChanges);
    expect(await git(local, ['rev-parse', 'HEAD']), head);
    expect(File('$local/README.md').readAsStringSync(), '# Satu\n');
  });

  test('broken_folder_reports_error', () async {
    final root = await Directory.systemTemp.createTemp('whisker-root-');
    addTearDown(() => root.delete(recursive: true));
    await Directory('${root.path}/uji').create();
    final s = await LocalSync(root.path).syncHub(hubAt('/tidak/ada'));
    expect(s.state, SyncState.error);
  });
}

class _GatedSync extends LocalSync {
  _GatedSync() : super('/tidak-dipakai');
  final gates = <Completer<void>>[];

  @override
  Future<SyncStatus> syncHub(Hub hub) async {
    final g = Completer<void>();
    gates.add(g);
    await g.future;
    return const SyncStatus(SyncState.upToDate);
  }
}

void queueTests() {
  test('unsafe_slug_rejected', () async {
    final root = await Directory.systemTemp.createTemp('whisker-root-');
    addTearDown(() => root.delete(recursive: true));
    final hub = hubAt('/tidak/ada').copyWith(slug: '..');
    final s = await LocalSync(root.path).syncHub(hub);
    expect(s.state, SyncState.error);
  });

  test('change_during_sync_is_queued', () async {
    SharedPreferences.setMockInitialValues({'whisker.localRoot': '/x'});
    final fake = _GatedSync();
    final c = ProviderContainer(
      overrides: [localSyncFactoryProvider.overrideWithValue((_) => fake)],
    );
    addTearDown(c.dispose);
    final ctl = c.read(localSyncProvider.notifier);
    await c.read(localSyncProvider.notifier).setRoot('/x');
    final hub = hubAt('/r');
    final first = ctl.sync(hub);
    await Future<void>.delayed(Duration.zero);
    unawaited(ctl.sync(hub)); // HubChange saat sinkron berjalan
    expect(fake.gates, hasLength(1));
    fake.gates.first.complete();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(fake.gates, hasLength(2));
    fake.gates.last.complete();
    await first;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(c.read(localSyncProvider).running, isEmpty);
  });
}
