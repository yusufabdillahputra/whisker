import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

List<WikiLink> links(String s) => extractWikilinks(MdDocument.parse(s));

void main() {
  test('parses_parts', () {
    final l = links('[[A#B|C]] dan ![[x.png]] dan [[#Sub]]\n');
    expect(l, hasLength(3));
    expect(
      [l[0].target, l[0].heading, l[0].alias, l[0].embed],
      ['A', 'B', 'C', false],
    );
    expect(
      [l[1].target, l[1].heading, l[1].alias, l[1].embed],
      ['x.png', null, null, true],
    );
    expect(
      [l[2].target, l[2].heading, l[2].alias, l[2].embed],
      ['', 'Sub', null, false],
    );
  });

  test('ignores_links_in_code', () {
    final l = links(
      'Lihat [[Ya]] dan `[[Tidak1]]`.\n\n```md\n[[Tidak2]]\n```\n',
    );
    expect(l.map((x) => x.target), ['Ya']);
  });

  test('links_in_lists_tables_callouts', () {
    final l = links(
      '- item [[L]]\n\n| a |\n| --- |\n| [[T]] |\n\n> [!note] Judul\n> isi [[C]]\n',
    );
    expect(l.map((x) => x.target), ['L', 'T', 'C']);
  });

  test('title_order', () {
    expect(
      extractTitle(MdDocument.parse('---\ntitle: X\n---\n# Y\n'), 'a.md'),
      'X',
    );
    expect(
      extractTitle(
        MdDocument.parse('## Bukan\n\n# ADR-003 — Autentikasi\n'),
        'a.md',
      ),
      'ADR-003 — Autentikasi',
    );
    expect(
      extractTitle(
        MdDocument.parse('isi saja\n'),
        'PKM/ADR/ADR-001 - Offload.md',
      ),
      'ADR-001 - Offload',
    );
  });

  test('title_fallback_to_stem', () {
    expect(extractTitle(MdDocument.parse(''), 'Catatan.md'), 'Catatan');
  });

  test('tags_forms', () {
    expect(extractTags(MdDocument.parse('---\ntags: [a, b]\n---\n')), [
      'a',
      'b',
    ]);
    expect(extractTags(MdDocument.parse('---\ntags: "#a, b c"\n---\n')), [
      'a',
      'b',
      'c',
    ]);
    expect(extractTags(MdDocument.parse('isi\n')), isEmpty);
  });
}
