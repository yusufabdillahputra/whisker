import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../editor/editor_pane.dart';
import '../hub_tree/hub_tree.dart';
import '../inspector/inspector.dart';
import '../local_sync/local_sync_panel.dart';
import '../search/search_palette.dart';

/// Lebar minimum layout tiga panel dan dua panel.
const wideBreakpoint = 1100.0;
const mediumBreakpoint = 700.0;

/// Lokasi workspace untuk dokumen [path] di Hub [hubId].
String docLocation(int hubId, String? path) => path == null
    ? '/hub/$hubId'
    : '/hub/$hubId?doc=${Uri.encodeQueryComponent(path)}';

/// Workspace Hub: tiga panel (≥ 1100 px), pohon + editor dengan inspector di
/// sheet (700–1099 px), atau bottom nav Beranda/Dokumen/Cari/Tracking.
class WorkspacePage extends ConsumerStatefulWidget {
  final int hubId;
  final String? docPath;
  const WorkspacePage({super.key, required this.hubId, this.docPath});

  @override
  ConsumerState<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends ConsumerState<WorkspacePage> {
  var _tab = 0;
  String? _path;

  @override
  void initState() {
    super.initState();
    _path = widget.docPath;
    if (_path != null) _tab = 1;
  }

  @override
  void didUpdateWidget(WorkspacePage old) {
    super.didUpdateWidget(old);
    if (widget.docPath != old.docPath) {
      _path = widget.docPath;
      if (_path != null) _tab = 1;
    }
  }

  void _open(String path) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(docLocation(widget.hubId, path));
    } else {
      setState(() {
        _path = path;
        _tab = 1;
      });
    }
  }

  void _showInspector() {
    final path = _path;
    if (path == null) return;
    showFSheet<void>(
      context: context,
      side: FLayout.rtl,
      builder: (context) => SizedBox(
        width: 340,
        child: ColoredBox(
          color: context.theme.colors.background,
          child: Inspector(hubId: widget.hubId, path: path),
        ),
      ),
    );
  }

  Future<void> _search() async {
    final path = await showSearchPalette(context, widget.hubId);
    if (path != null && mounted) _open(path);
  }

  Widget _tree() {
    final tree = ref.watch(treeProvider(widget.hubId));
    return tree.when(
      data: (docs) => HubTree(docs: docs, activePath: _path, onOpen: _open),
      loading: () => const Center(child: FCircularProgress()),
      error: (e, _) => Center(child: Text('Gagal memuat pohon: $e')),
    );
  }

  Widget _editor() => _path == null
      ? const Center(child: Text('Pilih dokumen dari pohon.'))
      : EditorPane(key: ValueKey(_path), hubId: widget.hubId, path: _path!);

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): _search,
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _search,
    },
    child: Focus(autofocus: true, child: _layout(context)),
  );

  Widget _layout(BuildContext context) {
    // HubChange → perbarui clone lokal Hub ini (desktop).
    ref.listen(hubWatchProvider(widget.hubId), (_, next) {
      if (!next.hasValue || !localSyncSupported) return;
      final hub = ref
          .read(hubsProvider)
          .value
          ?.where((h) => h.id == widget.hubId)
          .firstOrNull;
      if (hub != null) ref.read(localSyncProvider.notifier).sync(hub);
    });
    final colors = context.theme.colors;
    final hubs = ref.watch(hubsProvider).value ?? const [];
    final name =
        hubs.where((h) => h.id == widget.hubId).firstOrNull?.name ?? 'Hub';
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= wideBreakpoint;
    final medium = !wide && width >= mediumBreakpoint;
    final divider = BorderSide(color: colors.border);

    final header = FHeader.nested(
      title: Text(name),
      prefixes: [
        FHeaderAction.back(
          semanticsLabel: 'Daftar Hub',
          onPress: () => GoRouter.maybeOf(context)?.go('/'),
        ),
      ],
      suffixes: [
        if (wide || medium)
          FHeaderAction(
            icon: const Icon(FLucideIcons.search),
            semanticsLabel: 'Cari (Ctrl K)',
            onPress: _search,
          ),
        if (medium || (!wide && _tab == 1))
          FHeaderAction(
            icon: const Icon(FLucideIcons.panelRight),
            semanticsLabel: 'Inspector',
            onPress: _path == null ? null : _showInspector,
          ),
      ],
    );

    if (wide || medium) {
      return FScaffold(
        header: header,
        childPad: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              key: const Key('tree-pane'),
              width: wide ? 280 : 260,
              decoration: BoxDecoration(border: Border(right: divider)),
              child: _tree(),
            ),
            Expanded(
              child: KeyedSubtree(
                key: const Key('editor-pane'),
                child: _editor(),
              ),
            ),
            if (wide)
              Container(
                key: const Key('inspector-pane'),
                width: 320,
                decoration: BoxDecoration(border: Border(left: divider)),
                child: _path == null
                    ? const SizedBox.shrink()
                    : Inspector(hubId: widget.hubId, path: _path!),
              ),
          ],
        ),
      );
    }

    final body = switch (_tab) {
      0 => KeyedSubtree(key: const Key('tree-pane'), child: _tree()),
      1 => KeyedSubtree(key: const Key('editor-pane'), child: _editor()),
      2 => SearchPanel(hubId: widget.hubId, onOpen: _open),
      _ => const Center(child: Text('Segera hadir')),
    };
    return FScaffold(
      header: header,
      childPad: false,
      footer: FBottomNavigationBar(
        index: _tab,
        onChange: (i) => setState(() => _tab = i),
        children: const [
          FBottomNavigationBarItem(
            icon: Icon(FLucideIcons.house),
            label: Text('Beranda'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FLucideIcons.fileText),
            label: Text('Dokumen'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FLucideIcons.search),
            label: Text('Cari'),
          ),
          FBottomNavigationBarItem(
            icon: Icon(FLucideIcons.listTodo),
            label: Text('Tracking'),
          ),
        ],
      ),
      child: body,
    );
  }
}
