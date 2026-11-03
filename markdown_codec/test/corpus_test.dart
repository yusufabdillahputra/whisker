import 'dart:io';

import 'package:markdown_codec/markdown_codec.dart';
import 'package:test/test.dart';

/// Round-trip semua file markdown di vault nyata. Vault klien tidak di-commit;
/// arahkan `WHISKER_FIXTURE_VAULT` ke salinan lokal untuk menjalankannya.
void main() {
  test('corpus_roundtrip', () {
    final root = Platform.environment['WHISKER_FIXTURE_VAULT'] ?? '';
    if (root.isEmpty) {
      markTestSkipped('WHISKER_FIXTURE_VAULT tidak diset');
      return;
    }
    final skip = RegExp(r'(^|[\\/])\.(git|obsidian)([\\/]|$)');
    var count = 0;
    for (final f in Directory(
      root,
    ).listSync(recursive: true).whereType<File>()) {
      final rel = f.path.substring(root.length);
      if (!f.path.endsWith('.md') || skip.hasMatch(rel)) continue;
      final s = f.readAsStringSync();
      expect(MdDocument.parse(s).serialize(), s, reason: f.path);
      count++;
    }
    print('corpus_roundtrip: $count file diuji');
    expect(count, greaterThan(0));
  });
}
