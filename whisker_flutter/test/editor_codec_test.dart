import 'dart:io';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_codec/markdown_codec.dart';
import 'package:whisker/data/fake_api.dart';
import 'package:whisker/features/editor/editor_codec.dart';

void setText(Node n, String text) =>
    n.updateAttributes({'delta': (Delta()..insert(text)).toJson()});

String body(MdDocument d, Document e) => bodyFromEditor(d, e);

void main() {
  test('fixtures_roundtrip_without_edit', () {
    final inputs = <String, String>{
      for (final f in Directory(
        '../markdown_codec/test/fixtures',
      ).listSync().whereType<File>())
        f.path: f.readAsStringSync(),
      ...sampleFiles,
    };
    for (final e in inputs.entries) {
      for (final s in [e.value, e.value.replaceAll('\n', '\r\n')]) {
        final d = MdDocument.parse(s);
        expect(
          d.frontmatter.raw + body(d, editorDocumentFrom(d)),
          s,
          reason: e.key,
        );
      }
    }
  });

  test('edit_heading_changes_one_line', () {
    const s = '# Lama\n\nParagraf *miring* tetap.\n\n- a\n- b\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final h = e.root.children.first;
    expect(h.type, 'heading');
    setText(h, 'Baru');
    expect(body(d, e), '# Baru\n\nParagraf *miring* tetap.\n\n- a\n- b\n');
  });

  test('mermaid_is_raw_and_editable', () {
    const s = '# A\n\n```mermaid\nflowchart LR\n  A --> B\n```\n\nakhir\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final raw = e.root.children.firstWhere((n) => n.type == rawBlockType);
    expect(raw.attributes[rawLabelKey], 'Mermaid');
    expect(
      raw.attributes[rawSourceKey],
      '```mermaid\nflowchart LR\n  A --> B\n```',
    );
    raw.updateAttributes({
      rawSourceKey: '```mermaid\nflowchart LR\n  A --> C\n```',
    });
    expect(
      body(d, e),
      '# A\n\n```mermaid\nflowchart LR\n  A --> C\n```\n\nakhir\n',
    );
  });

  test('callout_table_are_raw', () {
    final d = MdDocument.parse(sampleFiles['PKM/Catatan/Kucing Calico.md']!);
    final labels = editorDocumentFrom(d).root.children
        .where((n) => n.type == rawBlockType)
        .map((n) => n.attributes[rawLabelKey])
        .toList();
    expect(labels, containsAll(['Callout note', 'Tabel']));
  });

  test('split_node_keeps_blank_line', () {
    const s = '# A\n\nsatu dua\n\nakhir\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final p = e.root.children.elementAt(1);
    setText(p, 'satu');
    // Enter di tengah: node baru mewarisi atribut blok asal (termasuk wb).
    final split = p.copyWith(attributes: {...p.attributes});
    setText(split, 'dua');
    e.insert(p.path.next, [split]);
    expect(body(d, e), '# A\n\nsatu\n\ndua\n\nakhir\n');

    // Varian tanpa wb (node baru polos).
    final d2 = MdDocument.parse(s);
    final e2 = editorDocumentFrom(d2);
    final p2 = e2.root.children.elementAt(1);
    setText(p2, 'satu');
    e2.insert(p2.path.next, [paragraphNode(text: 'dua')]);
    expect(body(d2, e2), '# A\n\nsatu\n\ndua\n\nakhir\n');
  });

  test('edited_list_keeps_marker', () {
    const s = 'Daftar:\n\n- a\n- b\n  - b1\n\nakhir\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final items = e.root.children
        .where((n) => n.type == 'bulleted_list')
        .toList();
    expect(items, hasLength(2));
    setText(items.first, 'a diubah');
    expect(body(d, e), 'Daftar:\n\n- a diubah\n- b\n  - b1\n\nakhir\n');
  });

  test('new_paragraph_appended', () {
    const s = '# A\n\nteks';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    e.insert([e.root.children.length], [paragraphNode(text: 'baru')]);
    expect(body(d, e), '# A\n\nteks\n\nbaru\n');
  });

  test('deleted_block_removed', () {
    const s = '# A\n\nhapus aku\n\nakhir\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    e.delete(e.root.children.elementAt(1).path);
    expect(body(d, e), '# A\n\nakhir\n');
  });

  test('todo_list_keeps_marker', () {
    const s = '* [ ] satu\n* [x] dua\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final todo = e.root.children.first;
    expect(todo.type, 'todo_list');
    setText(todo, 'satu diubah');
    expect(body(d, e), '* [ ] satu diubah\n* [x] dua\n');
  });

  test('ordered_paren_delimiter_kept', () {
    const s = '1) satu\n2) dua\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final first = e.root.children.first;
    expect(first.type, 'numbered_list');
    setText(first, 'satu diubah');
    expect(body(d, e), '1) satu diubah\n2) dua\n');
  });

  test('nested_under_ordered_uses_marker_width', () {
    const s = '1. a\n2. b\n';
    final d = MdDocument.parse(s);
    final e = editorDocumentFrom(d);
    final first = e.root.children.first;
    e.insert([0, 0], [bulletedListNode(text: 'anak')]);
    expect(first.children, hasLength(1));
    expect(body(d, e), '1. a\n   - anak\n2. b\n');
  });

  test('snapshot_reuse_matches_fresh', () {
    const s = '# A\n\nsatu\n\n- x\n- y\n';
    final d = MdDocument.parse(s);
    final snap = snapshotOf(d);
    final e = editorDocumentFrom(d);
    expect(bodyFromEditor(d, e, snapshot: snap), s);
    setText(e.root.children.elementAt(1), 'dua');
    expect(bodyFromEditor(d, e, snapshot: snap), bodyFromEditor(d, e));
    expect(bodyFromEditor(d, e, snapshot: snap), '# A\n\ndua\n\n- x\n- y\n');
  });
}
