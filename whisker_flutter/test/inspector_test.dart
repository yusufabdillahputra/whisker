import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisker/features/editor/editor_pane.dart';
import 'package:whisker/features/inspector/inspector.dart';

import 'helpers.dart';

const adr = 'PKM/ADR/ADR-0001 Pakai Git.md';

Widget both(String path, {ValueChanged<String>? onOpen}) => Row(
  children: [
    Expanded(child: EditorPane(hubId: 1, path: path)),
    SizedBox(
      width: 340,
      child: Inspector(hubId: 1, path: path, onOpen: onOpen),
    ),
  ],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('backlinks_and_history_listed', (tester) async {
    final opened = <String>[];
    await pumpWhisker(tester, both('README.md', onOpen: opened.add));
    expect(find.text('Backlinks'), findsOneWidget);
    expect(find.text('Kucing Calico'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('chore: isi awal'), findsOneWidget);
    expect(find.textContaining('Whisker'), findsWidgets);

    await tester.tap(find.text('Kucing Calico'));
    await tester.pumpAndSettle();
    expect(opened, ['PKM/Catatan/Kucing Calico.md']);
  });

  testWidgets('readonly_banner_and_status_edit', (tester) async {
    final api = await pumpWhisker(tester, both(adr));
    expect(find.byKey(const Key('readonly-banner')), findsOneWidget);
    final es = tester.state<EditorPaneState>(find.byType(EditorPane)).editorState!;
    expect(es.editable, isFalse);

    bool commitEnabled() => tester
        .widget<Semantics>(
          find.ancestor(
            of: find.text('Commit changes'),
            matching: find.byWidgetPredicate(
              (w) => w is Semantics && w.properties.enabled != null,
            ),
          ).first,
        )
        .properties
        .enabled!;
    expect(commitEnabled(), isFalse);

    final yaml = find.byKey(const Key('frontmatter-yaml'));
    expect(yaml, findsOneWidget);
    await tester.enterText(
      find.descendant(of: yaml, matching: find.byType(EditableText)),
      'type: adr\nstatus: superseded\n',
    );
    await tester.pumpAndSettle();
    expect(commitEnabled(), isTrue);

    await tester.tap(find.text('Commit changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commit'));
    await tester.pumpAndSettle();
    final saved = (await api.read(1, adr)).content;
    expect(saved, startsWith('---\ntype: adr\nstatus: superseded\n---\n'));
    expect(saved, endsWith('Sumber kebenaran Hub adalah repo git.\n'));
  });
}
