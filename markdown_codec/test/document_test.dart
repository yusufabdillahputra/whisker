import 'dart:io';

import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  test('roundtrip_fixtures', () {
    for (final f in Directory('test/fixtures').listSync().whereType<File>()) {
      final s = f.readAsStringSync();
      expect(MdDocument.parse(s).serialize(), s, reason: f.path);
      final crlf = s.replaceAll('\n', '\r\n');
      expect(
        MdDocument.parse(crlf).serialize(),
        crlf,
        reason: '${f.path} (CRLF)',
      );
    }
  });

  test('crlf_roundtrip', () {
    final crlf = fixture('adr.md').replaceAll('\n', '\r\n');
    final doc = MdDocument.parse(crlf);
    expect(doc.newline, '\r\n');
    expect(doc.serialize(), crlf);
    expect(
      doc.blocks.where((b) => b.kind == MdBlockKind.callout),
      hasLength(1),
    );
  });

  test('kinds_mermaid', () {
    final doc = MdDocument.parse(fixture('mermaid.md'));
    final fences = doc.blocks
        .where((b) => b.kind == MdBlockKind.fence)
        .toList();
    expect(fences.first.info, 'mermaid');
    expect(fences, hasLength(2));
    expect(
      doc.blocks.where(
        (b) => b.kind == MdBlockKind.heading && b.text == 'bukan heading',
      ),
      isEmpty,
    );
  });

  test('kinds_adr', () {
    final kinds = MdDocument.parse(fixture('adr.md')).blocks
        .where((b) => b.kind != MdBlockKind.blank)
        .map((b) => b.kind)
        .toList();
    expect(kinds, [
      MdBlockKind.heading,
      MdBlockKind.heading,
      MdBlockKind.paragraph,
      MdBlockKind.table,
      MdBlockKind.callout,
      MdBlockKind.blockquote,
      MdBlockKind.thematicBreak,
      MdBlockKind.paragraph,
    ]);
  });

  test('unclosed_fence_consumes_rest', () {
    final doc = MdDocument.parse('a\n\n```js\nx\n# y\n');
    expect(doc.blocks.last.kind, MdBlockKind.fence);
    expect(doc.blocks.last.source, '```js\nx\n# y\n');
  });

  test('empty_and_frontmatter_only', () {
    for (final s in ['', '---\na: 1\n---\n', 'tanpa newline']) {
      expect(MdDocument.parse(s).serialize(), s);
    }
    expect(MdDocument.parse('').blocks, isEmpty);
    expect(MdDocument.parse('---\na: 1\n---\n').blocks, isEmpty);
    expect(
      MdDocument.parse('tanpa newline').blocks.single.kind,
      MdBlockKind.paragraph,
    );
  });

  test('edit_heading_only_changes_that_block', () {
    final s = fixture('adr.md');
    final doc = MdDocument.parse(s);
    final i = doc.blocks.indexWhere((b) => b.kind == MdBlockKind.heading);
    final out = doc
        .replaceBlock(i, MdBlock.edit(doc.blocks[i], 'Judul Baru'))
        .serialize();
    expect(out, s.replaceFirst('# ADR-009 — Contoh Keputusan', '# Judul Baru'));
  });

  test('edit_callout_keeps_marker', () {
    final doc = MdDocument.parse(fixture('adr.md'));
    final i = doc.blocks.indexWhere((b) => b.kind == MdBlockKind.callout);
    final edited = MdBlock.edit(doc.blocks[i], 'Baris A\nBaris B');
    expect(edited.source, '> [!note] Catatan\n> Baris A\n> Baris B\n');
    expect(edited.edited, isTrue);
  });
}
