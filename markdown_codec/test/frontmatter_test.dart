import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

void main() {
  test('no_frontmatter', () {
    final s = splitFrontmatter('# A\n');
    expect(s.raw, '');
    expect(s.body, '# A\n');
    expect(s.data, isEmpty);
  });

  test('basic', () {
    final s = splitFrontmatter('---\ntype: adr\ntags: [a, b]\n---\n# T\n');
    expect(s.raw, '---\ntype: adr\ntags: [a, b]\n---\n');
    expect(s.data['type'], 'adr');
    expect(s.data['tags'], ['a', 'b']);
    expect(s.body, '# T\n');
    expect(s.error, isNull);
  });

  test('crlf_roundtrip', () {
    const input = '---\r\ntype: adr\r\ntags: [a, b]\r\n---\r\n# T\r\n';
    final s = splitFrontmatter(input);
    expect(s.raw + s.body, input);
    expect(s.data['type'], 'adr');
    expect(detectNewline(input), '\r\n');
    expect(detectNewline('a\nb'), '\n');
  });

  test('invalid_yaml_keeps_raw', () {
    const input = '---\nkey: [unclosed\n---\nisi\n';
    final s = splitFrontmatter(input);
    expect(s.data, isEmpty);
    expect(s.error, isNotNull);
    expect(s.raw + s.body, input);
  });

  test('dashes_not_at_start', () {
    expect(splitFrontmatter('teks\n---\nbukan: fm\n---\n').raw, '');
  });

  test('unclosed_frontmatter', () {
    const input = '---\na: 1\n';
    final s = splitFrontmatter(input);
    expect(s.raw, '');
    expect(s.body, input);
  });

  test('bom_before_frontmatter', () {
    const s = '\uFEFF---\ntags: [a]\n---\nx\n';
    final fm = splitFrontmatter(s);
    expect(fm.data, {
      'tags': ['a'],
    });
    expect(fm.raw + fm.body, s);
  });
}
