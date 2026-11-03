import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_codec/markdown_codec.dart';

/// Tipe node untuk blok yang disunting sebagai teks mentah.
const rawBlockType = 'whisker_raw';

/// Atribut node: indeks blok asli di `MdDocument.blocks`.
const wbKey = 'wb';
const rawSourceKey = 'source';
const rawLabelKey = 'label';

const _wysiwygKinds = {
  MdBlockKind.heading,
  MdBlockKind.paragraph,
  MdBlockKind.list,
  MdBlockKind.blockquote,
};

const _listTypes = {'bulleted_list', 'numbered_list', 'todo_list'};

String _lf(String s) => s.replaceAll('\r\n', '\n');

String _trimEnd(String s) => s.replaceFirst(RegExp(r'\s+$'), '');

String _html(String s) =>
    md.markdownToHtml(s, extensionSet: md.ExtensionSet.gitHubFlavored);

/// `true` bila [source] bisa disunting WYSIWYG tanpa mengubah maknanya:
/// hasil encode appflowy setelah decode merender HTML yang sama.
bool isStableForEditor(String source) {
  final s = _trimEnd(_lf(source));
  if (s.isEmpty) return false;
  final again = _trimEnd(documentToMarkdown(markdownToDocument(s)));
  return again.isNotEmpty && _html(again) == _html(s);
}

/// Label raw block untuk ditampilkan di editor.
String rawLabel(MdBlock b) => switch (b.kind) {
  MdBlockKind.fence when b.info?.trim().toLowerCase() == 'mermaid' => 'Mermaid',
  MdBlockKind.fence =>
    (b.info ?? '').trim().isEmpty ? 'Kode' : 'Kode ${b.info!.trim()}',
  MdBlockKind.callout => 'Callout ${_calloutKind(b.info)}',
  MdBlockKind.table => 'Tabel',
  MdBlockKind.html => 'HTML',
  MdBlockKind.thematicBreak => 'Garis',
  _ => 'Markdown',
};

String _calloutKind(String? info) =>
    RegExp(r'\[!(\w+)').firstMatch(info ?? '')?.group(1) ?? '';

/// Dokumen appflowy dari [doc]: blok stabil menjadi node WYSIWYG, sisanya
/// raw block. Setiap node tingkat atas membawa atribut [wbKey].
Document editorDocumentFrom(MdDocument doc) {
  final nodes = <Node>[];
  for (final i in contentBlockIndexes(doc)) {
    final b = doc.blocks[i];
    if (_wysiwygKinds.contains(b.kind) && isStableForEditor(b.source)) {
      for (final n in markdownToDocument(
        _trimEnd(_lf(b.source)),
      ).root.children) {
        nodes.add(n.copyWith(attributes: {...n.attributes, wbKey: i}));
      }
    } else {
      nodes.add(
        Node(
          type: rawBlockType,
          attributes: {
            wbKey: i,
            rawSourceKey: _rawSource(b),
            rawLabelKey: rawLabel(b),
          },
        ),
      );
    }
  }
  if (nodes.isEmpty) nodes.add(paragraphNode());
  return Document(root: pageNode(children: nodes));
}

String _rawSource(MdBlock b) => _lf(b.source).replaceFirst(RegExp(r'\n$'), '');

String _nodeMarkdown(Node n) {
  if (n.type == rawBlockType) return '${n.attributes[rawSourceKey] ?? ''}';
  return _trimEnd(
    documentToMarkdown(Document(root: pageNode(children: [n.deepCopy()]))),
  );
}

String _joinNodes(List<Node> nodes) {
  final b = StringBuffer();
  for (var k = 0; k < nodes.length; k++) {
    if (k > 0) {
      final listy =
          _listTypes.contains(nodes[k - 1].type) &&
          _listTypes.contains(nodes[k].type);
      b.write(listy ? '\n' : '\n\n');
    }
    b.write(_nodeMarkdown(nodes[k]));
  }
  return b.toString();
}

/// Penanda list dan indentasi asli blok list.
({String marker, String indent}) _listStyle(String source) {
  final m = RegExp(r'^ {0,3}([-*+])[ \t]', multiLine: true).firstMatch(source);
  final ind = RegExp(
    r'^([ \t]+)(?:[-*+]|\d+[.)])[ \t]',
    multiLine: true,
  ).firstMatch(source);
  return (marker: m?.group(1) ?? '-', indent: ind?.group(1) ?? '  ');
}

/// Mengembalikan penanda `*` dan indentasi tab appflowy ke gaya asli.
String _restoreList(String markdown, String source) {
  final style = _listStyle(_lf(source));
  return markdown
      .split('\n')
      .map((line) {
        final m = RegExp(r'^(\t*)\* (?!\[[ xX]\] )').firstMatch(line);
        final lead = RegExp(r'^\t*').firstMatch(line)!.group(0)!;
        final indent = style.indent * lead.length;
        if (m != null) {
          return '$indent${style.marker} ${line.substring(m.end)}';
        }
        return '$indent${line.substring(lead.length)}';
      })
      .join('\n');
}

/// Body markdown dari [edited]; kelompok node yang tidak berubah memakai teks
/// asli sehingga dokumen tanpa edit byte-identik.
String bodyFromEditor(MdDocument original, Document edited) {
  final snapshot = editorDocumentFrom(original);
  final before = <int, String>{};
  for (final g in _groups(snapshot.root.children.toList())) {
    if (g.wb != null) before[g.wb!] = _joinNodes(g.nodes);
  }

  final pieces = <BodyPiece>[];
  final used = <int>{};
  for (final g in _groups(edited.root.children.toList())) {
    final markdown = _joinNodes(g.nodes);
    final wb = g.wb;
    if (wb != null && !used.contains(wb) && before.containsKey(wb)) {
      used.add(wb);
      if (markdown == before[wb]) {
        pieces.add(BodyPiece(blockIndex: wb));
      } else if (markdown.trim().isNotEmpty) {
        final src = original.blocks[wb].source;
        final out = original.blocks[wb].kind == MdBlockKind.list
            ? _restoreList(markdown, src)
            : markdown;
        pieces.add(BodyPiece(blockIndex: wb, markdown: out));
      }
    } else if (markdown.trim().isNotEmpty) {
      pieces.add(BodyPiece(markdown: markdown));
    }
  }
  return assembleBody(original, pieces);
}

class _Group {
  final int? wb;
  final List<Node> nodes;
  _Group(this.wb, this.nodes);
}

/// Node berurutan dengan [wbKey] sama; node tanpa [wbKey] dikelompokkan bila
/// sama-sama item list (agar list baru tetap rapat).
List<_Group> _groups(List<Node> nodes) {
  final out = <_Group>[];
  for (final n in nodes) {
    final wb = n.attributes[wbKey] as int?;
    final last = out.isEmpty ? null : out.last;
    final joinNew =
        wb == null &&
        last != null &&
        last.wb == null &&
        _listTypes.contains(n.type) &&
        _listTypes.contains(last.nodes.last.type);
    if (last != null && ((wb != null && last.wb == wb) || joinNew)) {
      last.nodes.add(n);
    } else {
      out.add(_Group(wb, [n]));
    }
  }
  return out;
}
