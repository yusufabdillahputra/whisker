import 'dart:io';

import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

List<BodyPiece> untouched(MdDocument d) => [
  for (final i in contentBlockIndexes(d)) BodyPiece(blockIndex: i),
];

void main() {
  test('identity_for_all_fixtures', () {
    for (final f in Directory('test/fixtures').listSync().whereType<File>()) {
      final s = f.readAsStringSync();
      for (final input in [s, s.replaceAll('\n', '\r\n')]) {
        final d = MdDocument.parse(input);
        expect(
          d.frontmatter.raw + assembleBody(d, untouched(d)),
          input,
          reason: f.path,
        );
      }
    }
  });

  test('identity_with_leading_and_trailing_blanks', () {
    const s = '---\na: 1\n---\n\n# Judul\nlangsung\n\nParagraf\n\n\n';
    final d = MdDocument.parse(s);
    expect(d.frontmatter.raw + assembleBody(d, untouched(d)), s);
  });

  test('edit_middle_block', () {
    final d = MdDocument.parse('# A\n\nlama\n\n- x\n');
    final idx = contentBlockIndexes(d);
    final out = assembleBody(d, [
      BodyPiece(blockIndex: idx[0]),
      BodyPiece(blockIndex: idx[1], markdown: 'baru\nbaris dua'),
      BodyPiece(blockIndex: idx[2]),
    ]);
    expect(out, '# A\n\nbaru\nbaris dua\n\n- x\n');
  });

  test('delete_block_drops_its_leading_blank', () {
    final d = MdDocument.parse('A\n\nB\n\nC\n');
    final idx = contentBlockIndexes(d);
    expect(
      assembleBody(d, [
        BodyPiece(blockIndex: idx[0]),
        BodyPiece(blockIndex: idx[2]),
      ]),
      'A\n\nC\n',
    );
    expect(
      assembleBody(d, [
        BodyPiece(blockIndex: idx[1]),
        BodyPiece(blockIndex: idx[2]),
      ]),
      'B\n\nC\n',
    );
  });

  test('append_new_block_after_noeol', () {
    final d = MdDocument.parse('# A\n\nakhir');
    final out = assembleBody(d, [
      ...untouched(d),
      const BodyPiece(markdown: 'baru'),
    ]);
    expect(out, '# A\n\nakhir\n\nbaru\n');
  });

  test('insert_new_block_between_adjacent_blocks', () {
    final d = MdDocument.parse('# A\nteks\n');
    final idx = contentBlockIndexes(d);
    final out = assembleBody(d, [
      BodyPiece(blockIndex: idx[0]),
      const BodyPiece(markdown: 'sisipan'),
      BodyPiece(blockIndex: idx[1]),
    ]);
    expect(out, '# A\n\nsisipan\n\nteks\n');
  });

  test('crlf_new_text_uses_crlf', () {
    final d = MdDocument.parse('# A\r\n\r\nlama\r\n');
    final idx = contentBlockIndexes(d);
    final out = assembleBody(d, [
      BodyPiece(blockIndex: idx[0]),
      BodyPiece(blockIndex: idx[1], markdown: 'baru\ndua'),
      const BodyPiece(markdown: 'tambahan'),
    ]);
    expect(out, '# A\r\n\r\nbaru\r\ndua\r\n\r\ntambahan\r\n');
  });
}
