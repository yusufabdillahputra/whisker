import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

const _adr = '---\ntype: adr\nstatus: accepted\n---\n# ADR-001\n\nIsi.\n';

void main() {
  test('protected_paths', () {
    expect(checkHubRules('PKM/_LLM-Wiki/a.md', null, 'x'), isNotNull);
    expect(checkHubRules('Features/_Format/T.md', 'a', 'b'), isNotNull);
    expect(checkHubRules('PKM/ADR/a.md', null, _adr), isNull);
  });

  test('accepted_adr_only_status', () {
    const path = 'PKM/ADR/ADR-001.md';
    expect(
      checkHubRules(path, _adr, _adr.replaceFirst('Isi.', 'Isi baru.')),
      isNotNull,
    );
    final superseded = _adr.replaceFirst(
      'status: accepted',
      'status: superseded\nsuperseded_by: ADR-010',
    );
    expect(checkHubRules(path, _adr, superseded), isNull);
  });

  test('draft_adr_free', () {
    final draft = _adr.replaceFirst('accepted', 'proposed');
    expect(
      checkHubRules('PKM/ADR/x.md', draft, draft.replaceFirst('Isi.', 'Lain.')),
      isNull,
    );
  });

  test('read_only_reason', () {
    expect(readOnlyReason('PKM/ADR/x.md', _adr), contains('ADR'));
    expect(readOnlyReason('Features/_Format/T.md', 'x'), isNotNull);
    expect(readOnlyReason('Catatan.md', '# Halo\n'), isNull);
  });
}
