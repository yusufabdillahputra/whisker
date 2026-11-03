import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:whisker_client/whisker_client.dart';

/// Satu baris pohon: folder atau dokumen.
class TreeRow {
  final String path;
  final String label;
  final int depth;
  final bool isFolder;
  final DocSummary? doc;
  const TreeRow(
    this.path,
    this.label,
    this.depth, {
    this.isFolder = false,
    this.doc,
  });
}

/// Baris pohon terlihat dari [docs] (terurut), melewati isi folder di
/// [collapsed]. Folder didahulukan sebelum dokumen di tiap level.
List<TreeRow> treeRows(List<DocSummary> docs, Set<String> collapsed) {
  final root = _Dir('');
  for (final d in docs) {
    final parts = d.path.split('/');
    var dir = root;
    for (var i = 0; i < parts.length - 1; i++) {
      dir = dir.dirs.putIfAbsent(
        parts[i],
        () => _Dir(parts.take(i + 1).join('/')),
      );
    }
    dir.docs.add(d);
  }
  final out = <TreeRow>[];
  void walk(_Dir dir, int depth) {
    final names = dir.dirs.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    for (final n in names) {
      final sub = dir.dirs[n]!;
      out.add(TreeRow(sub.path, n, depth, isFolder: true));
      if (!collapsed.contains(sub.path)) walk(sub, depth + 1);
    }
    final docs = [...dir.docs]
      ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    for (final d in docs) {
      out.add(TreeRow(d.path, d.title, depth, doc: d));
    }
  }

  walk(root, 0);
  return out;
}

class _Dir {
  final String path;
  final dirs = <String, _Dir>{};
  final docs = <DocSummary>[];
  _Dir(this.path);
}

IconData _iconFor(DocSummary d) => switch (d.area) {
  'knowledge' => FLucideIcons.bookOpen,
  'tracking' => FLucideIcons.listTodo,
  'guide' => FLucideIcons.compass,
  _ => FLucideIcons.fileText,
};

/// Pohon dokumen Hub: folder bisa dilipat, ikon per area, dokumen aktif
/// disorot.
class HubTree extends StatefulWidget {
  final List<DocSummary> docs;
  final String? activePath;
  final ValueChanged<String> onOpen;

  const HubTree({
    super.key,
    required this.docs,
    required this.onOpen,
    this.activePath,
  });

  @override
  State<HubTree> createState() => _HubTreeState();
}

class _HubTreeState extends State<HubTree> {
  final _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final rows = treeRows(widget.docs, _collapsed);
    if (rows.isEmpty) {
      return const Center(child: Text('Hub ini belum punya dokumen.'));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final r = rows[i];
        final open = !_collapsed.contains(r.path);
        return Padding(
          padding: EdgeInsets.only(left: 12.0 * r.depth),
          child: FItem(
            selected: r.path == widget.activePath,
            semanticsLabel: r.isFolder ? 'Folder ${r.label}' : r.label,
            semanticsExpanded: r.isFolder ? open : null,
            prefix: Icon(
              r.isFolder
                  ? (open ? FLucideIcons.folderOpen : FLucideIcons.folder)
                  : _iconFor(r.doc!),
            ),
            title: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis),
            onPress: () {
              if (r.isFolder) {
                setState(
                  () =>
                      open ? _collapsed.add(r.path) : _collapsed.remove(r.path),
                );
              } else {
                widget.onOpen(r.path);
              }
            },
          ),
        );
      },
    );
  }
}
