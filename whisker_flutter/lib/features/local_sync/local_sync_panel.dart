import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisker_client/whisker_client.dart';

import 'local_sync.dart';

/// Sinkron folder lokal hanya di desktop (macOS, Windows, Linux).
bool get localSyncSupported =>
    !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

const _rootKey = 'whisker.localRoot';

class LocalSyncState {
  final String? root;
  final Map<int, SyncStatus> statuses;
  final Set<int> running;
  const LocalSyncState({
    this.root,
    this.statuses = const {},
    this.running = const {},
  });

  LocalSyncState copyWith({
    String? root,
    Map<int, SyncStatus>? statuses,
    Set<int>? running,
  }) => LocalSyncState(
    root: root ?? this.root,
    statuses: statuses ?? this.statuses,
    running: running ?? this.running,
  );
}

/// Pembuat [LocalSync] per folder induk (diganti di test).
final localSyncFactoryProvider = Provider<LocalSync Function(String root)>(
  (ref) => LocalSync.new,
);

/// Folder induk clone lokal + status sinkron per Hub.
class LocalSyncController extends Notifier<LocalSyncState> {
  @override
  LocalSyncState build() {
    _loadRoot();
    return const LocalSyncState();
  }

  Future<void> _loadRoot() async {
    final p = await SharedPreferences.getInstance();
    final root = p.getString(_rootKey);
    if (root != null) state = state.copyWith(root: root);
  }

  Future<void> setRoot(String root) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_rootKey, root);
    state = LocalSyncState(root: root);
  }

  /// Hub yang menerima perubahan saat sinkronnya masih berjalan.
  final _rerun = <int>{};

  /// Menyinkronkan [hub]; permintaan yang datang saat sinkron Hub itu masih
  /// berjalan dijalankan sekali lagi setelahnya, agar clone tidak tertinggal.
  Future<void> sync(Hub hub) async {
    final root = state.root;
    final id = hub.id!;
    if (root == null) return;
    if (state.running.contains(id)) {
      _rerun.add(id);
      return;
    }
    state = state.copyWith(running: {...state.running, id});
    final status = await ref.read(localSyncFactoryProvider)(root).syncHub(hub);
    state = state.copyWith(
      statuses: {...state.statuses, id: status},
      running: {...state.running}..remove(id),
    );
    if (_rerun.remove(id)) await sync(hub);
  }

  Future<void> syncAll(List<Hub> hubs) async {
    for (final h in hubs) {
      await sync(h);
    }
  }
}

final localSyncProvider = NotifierProvider<LocalSyncController, LocalSyncState>(
  LocalSyncController.new,
);

String _label(SyncStatus? s) => switch (s?.state) {
  null => 'Belum disinkronkan',
  SyncState.cloned => 'Di-clone',
  SyncState.updated => 'Diperbarui',
  SyncState.upToDate => 'Mutakhir',
  SyncState.localChanges => 'Perubahan lokal: ${s!.detail ?? ''}',
  SyncState.error => 'Gagal: ${s!.detail ?? ''}',
};

/// Panel **Folder lokal**: pilih folder induk dan lihat status tiap Hub.
class LocalSyncPanel extends ConsumerStatefulWidget {
  final List<Hub> hubs;
  const LocalSyncPanel({super.key, required this.hubs});

  @override
  ConsumerState<LocalSyncPanel> createState() => _LocalSyncPanelState();
}

class _LocalSyncPanelState extends ConsumerState<LocalSyncPanel> {
  bool _autoRan = false;

  Future<void> _pick() async {
    final dir = await getDirectoryPath(confirmButtonText: 'Pilih folder');
    if (dir == null) return;
    final c = ref.read(localSyncProvider.notifier);
    await c.setRoot(dir);
    await c.syncAll(widget.hubs);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(localSyncProvider);
    if (!_autoRan && s.root != null && widget.hubs.isNotEmpty) {
      _autoRan = true;
      Future.microtask(
        () => ref.read(localSyncProvider.notifier).syncAll(widget.hubs),
      );
    }
    final muted = context.theme.typography.body.sm.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Folder lokal',
              style: context.theme.typography.body.md.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            s.root == null
                ? 'Pilih folder agar setiap Hub di-clone ke sini dan '
                      'diperbarui otomatis (untuk Claude Code).'
                : s.root!,
            style: muted,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(FLucideIcons.folderSync),
                onPress: _pick,
                child: Text(s.root == null ? 'Pilih folder' : 'Ganti folder'),
              ),
              if (s.root != null)
                FButton(
                  variant: FButtonVariant.ghost,
                  mainAxisSize: MainAxisSize.min,
                  prefix: const Icon(FLucideIcons.refreshCw),
                  onPress: () =>
                      ref.read(localSyncProvider.notifier).syncAll(widget.hubs),
                  child: const Text('Sinkron sekarang'),
                ),
            ],
          ),
          if (s.root != null)
            for (final h in widget.hubs)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${h.name}: ${s.running.contains(h.id) ? 'Menyinkronkan…' : _label(s.statuses[h.id])}',
                  style: muted,
                ),
              ),
        ],
      ),
    );
  }
}
