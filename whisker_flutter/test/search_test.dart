import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisker/features/shell/workspace_page.dart';

import 'helpers.dart';

Future<void> typeQuery(WidgetTester tester, String q) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(const Key('search-field')),
      matching: find.byType(EditableText),
    ),
    q,
  );
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ctrl_k_opens_and_navigates', (tester) async {
    await pumpWhisker(
      tester,
      const WorkspacePage(hubId: 1, docPath: 'README.md'),
    );
    expect(find.byKey(const Key('search-field')), findsNothing);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-field')), findsOneWidget);

    await typeQuery(tester, 'kucing');
    final hits = find.byKey(const Key('search-hit'));
    expect(hits, findsNWidgets(3));
    expect(find.text('Kucing Calico'), findsWidgets);
    expect(find.textContaining('tags: [kucing, warna]'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search-field')), findsNothing);
    expect(find.text('PKM/Catatan/Arsitektur.md'), findsOneWidget);
  });

  testWidgets('mobile_search_tab', (tester) async {
    await pumpWhisker(
      tester,
      const WorkspacePage(hubId: 1),
      size: const Size(390, 844),
    );
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();
    await typeQuery(tester, 'calico');
    expect(find.byKey(const Key('search-hit')), findsWidgets);
    await tester.tap(find.byKey(const Key('search-hit')).first);
    await tester.pumpAndSettle();
    expect(find.text('Commit changes'), findsOneWidget);
  });
}
