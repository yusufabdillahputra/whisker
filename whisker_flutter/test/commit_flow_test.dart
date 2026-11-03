import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisker/data/drafts.dart';
import 'package:whisker/features/editor/doc_session.dart';
import 'package:whisker/features/editor/editor_pane.dart';

import 'helpers.dart';

const kucing = 'PKM/Catatan/Kucing Calico.md';
const adr = 'PKM/ADR/ADR-0001 Pakai Git.md';

/// Menambahkan [text] di akhir node teks pertama (judul) lewat transaksi.
Future<void> typeIntoFirstText(WidgetTester tester, String text) async {
  final state = tester.state<EditorPaneState>(find.byType(EditorPane));
  final es = state.editorState!;
  final node = es.document.root.children.firstWhere((n) => n.delta != null);
  final t = es.transaction..insertText(node, node.delta!.length, text);
  await es.apply(t);
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('commit_sends_default_message', (tester) async {
    final api = await pumpWhisker(
      tester,
      const EditorPane(hubId: 1, path: kucing),
    );
    await typeIntoFirstText(tester, ' Lucu');
    expect(await DraftStore().load(1, kucing), isNotNull);

    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();
    expect(find.text('docs(knowledge): update Kucing Calico'), findsOneWidget);
    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();

    final sent = api.commits.single;
    expect(sent.message, 'docs(knowledge): update Kucing Calico');
    expect(sent.content, contains('# Kucing Calico Lucu\n'));
    // Bagian lain tetap byte-identik.
    expect(sent.content, contains('> [!note] Catatan\n> Hampir semua'));
    expect(await DraftStore().load(1, kucing), isNull);
    expect((await api.read(1, kucing)).content, sent.content);
  });

  testWidgets('conflict_keeps_draft', (tester) async {
    final api = await pumpWhisker(
      tester,
      const EditorPane(hubId: 1, path: kucing),
    );
    await typeIntoFirstText(tester, ' Lucu');
    api.externalEdit(1, kucing, '# Kucing Calico dari PC\n');

    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();

    expect(find.text('Konflik: dokumen sudah berubah'), findsOneWidget);
    expect(find.text('# Kucing Calico dari PC\n'), findsOneWidget);
    expect(await DraftStore().load(1, kucing), isNotNull);

    await tester.tap(find.text('Tetap pakai draf saya'));
    await tester.pumpAndSettle();
    expect(await DraftStore().load(1, kucing), isNotNull);

    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();
    expect(api.commits, hasLength(2));
    expect((await api.read(1, kucing)).content, contains('Kucing Calico Lucu'));
    expect(await DraftStore().load(1, kucing), isNull);
  });

  testWidgets('rejected_shows_reason', (tester) async {
    await pumpWhisker(tester, const EditorPane(hubId: 1, path: adr));
    // ADR accepted: editor terkunci, tetapi frontmatter bisa diubah lewat
    // Properties. Mengubah kunci selain status ditolak aturan Hub.
    final c = ProviderScope.containerOf(
      tester.element(find.byType(EditorPane)),
    );
    c
        .read(docSessionProvider((1, adr)).notifier)
        .setFrontmatter('---\ntype: adr\nstatus: accepted\nowner: baru\n---\n');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('hanya boleh mengubah status'),
      findsOneWidget,
    );
  });

  testWidgets('restores_draft_on_open', (tester) async {
    await DraftStore().save(1, 'README.md', '# Draf lama\n', 'v1');
    await pumpWhisker(tester, const EditorPane(hubId: 1, path: 'README.md'));
    final es = tester
        .state<EditorPaneState>(find.byType(EditorPane))
        .editorState!;
    expect(es.document.root.children.first.delta!.toPlainText(), 'Draf lama');
    expect(find.text('Commit changes'), findsOneWidget);
  });
}
