import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:whisker_client/whisker_client.dart';

import '../../app/app.dart';
import '../../app/logo.dart';
import '../../data/providers.dart';
import '../local_sync/local_sync_panel.dart';

/// Daftar Hub pengguna, tombol **Hub baru**, dan **Impor vault** per Hub.
class HubsPage extends ConsumerWidget {
  const HubsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hubs = ref.watch(hubsProvider);
    final auth = ref.watch(authGateProvider);
    return FScaffold(
      header: FHeader(
        title: const Row(
          children: [
            WhiskerMark(size: 28),
            SizedBox(width: 8),
            Text('Whisker'),
          ],
        ),
        suffixes: [
          FHeaderAction(
            icon: const Icon(FLucideIcons.plus),
            semanticsLabel: 'Hub baru',
            onPress: () => showNewHubDialog(context, ref),
          ),
          if (auth?.signOut != null)
            FHeaderAction(
              icon: const Icon(FLucideIcons.logOut),
              semanticsLabel: 'Keluar',
              onPress: auth!.signOut,
            ),
        ],
      ),
      child: hubs.when(
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) =>
            Center(child: Text('Gagal memuat Hub: ${_message(e)}')),
        data: (list) => list.isEmpty
            ? const Center(
                child: Text('Belum ada Hub. Buat Hub baru dari repo GitHub.'),
              )
            : ListView(
                children: [
                  for (final h in list) _HubTile(hub: h),
                  if (localSyncSupported && !ref.watch(demoModeProvider))
                    LocalSyncPanel(hubs: list),
                ],
              ),
      ),
    );
  }
}

String _message(Object e) => e is WhiskerException ? e.message : '$e';

class _HubTile extends ConsumerWidget {
  final Hub hub;
  const _HubTile({required this.hub});

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Vault zip', extensions: ['zip']),
      ],
    );
    if (file == null) return;
    try {
      await ref
          .read(apiProvider)
          .importVault(hub.id!, await file.readAsBytes());
      ref.invalidate(treeProvider(hub.id!));
      if (context.mounted) {
        showFToast(context: context, title: const Text('Vault diimpor.'));
      }
    } catch (e) {
      if (context.mounted) {
        showFToast(
          context: context,
          variant: FToastVariant.destructive,
          title: Text('Impor gagal: ${_message(e)}'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: FTile(
      prefix: const Icon(FLucideIcons.folderGit2),
      title: Text(hub.name),
      subtitle: Text(hub.githubRepo ?? hub.remoteUrl),
      suffix: FButton.icon(
        variant: FButtonVariant.ghost,
        semanticsLabel: 'Impor vault ke ${hub.name}',
        onPress: () => _import(context, ref),
        child: const Icon(FLucideIcons.upload),
      ),
      onPress: () => GoRouter.maybeOf(context)?.go('/hub/${hub.id}'),
    ),
  );
}

/// Dialog **Hub baru**: nama + repo GitHub `owner/nama`.
Future<void> showNewHubDialog(BuildContext context, WidgetRef ref) async {
  final name = TextEditingController();
  final repo = TextEditingController();
  await showFDialog<void>(
    context: context,
    builder: (context, style, animation) {
      var busy = false;
      String? error;
      return StatefulBuilder(
        builder: (context, setState) => FDialog(
          style: style,
          animation: animation,
          builder: (context, style) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hub baru',
                  style: context.theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FTextField(
                  control: FTextFieldControl.managed(controller: name),
                  label: const Text('Nama'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                FTextField(
                  control: FTextFieldControl.managed(controller: repo),
                  label: const Text('Repo GitHub'),
                  hint: 'owner/nama',
                  error: error == null ? null : Text(error!),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      variant: FButtonVariant.outline,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      mainAxisSize: MainAxisSize.min,
                      onPress: busy
                          ? null
                          : () async {
                              setState(() {
                                busy = true;
                                error = null;
                              });
                              try {
                                await ref
                                    .read(apiProvider)
                                    .createHub(
                                      name.text.trim(),
                                      githubRepo: repo.text.trim(),
                                    );
                                ref.invalidate(hubsProvider);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              } catch (e) {
                                setState(() {
                                  busy = false;
                                  error = _message(e);
                                });
                              }
                            },
                      child: const Text('Buat Hub'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
