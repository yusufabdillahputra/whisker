import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('spike', () {
    final doc = markdownToDocument('# Judul\n\nParagraf **tebal** dan [[Link]].\n\n- a\n- b\n\n```mermaid\nA-->B\n```\n\n> [!note] C\n> isi\n\n| a | b |\n| - | - |\n| 1 | 2 |\n');
    print(doc.root.children.map((n) => n.type).toList());
    print(documentToMarkdown(doc));
  });
}
