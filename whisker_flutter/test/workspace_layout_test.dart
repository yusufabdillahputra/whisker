import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whisker/features/shell/workspace_page.dart';

import 'helpers.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('layout_breakpoints', (tester) async {
    const page = WorkspacePage(hubId: 1, docPath: 'README.md');

    await pumpWhisker(tester, page, size: const Size(1280, 800));
    expect(find.byKey(const Key('tree-pane')), findsOneWidget);
    expect(find.byKey(const Key('editor-pane')), findsOneWidget);
    expect(find.byKey(const Key('inspector-pane')), findsOneWidget);
    expect(find.byType(FBottomNavigationBar), findsNothing);

    await pumpWhisker(tester, page, size: const Size(900, 800));
    expect(find.byKey(const Key('tree-pane')), findsOneWidget);
    expect(find.byKey(const Key('editor-pane')), findsOneWidget);
    expect(find.byKey(const Key('inspector-pane')), findsNothing);
    expect(find.bySemanticsLabel('Inspector'), findsOneWidget);

    await pumpWhisker(tester, page, size: const Size(390, 844));
    expect(find.byType(FBottomNavigationBar), findsOneWidget);
    for (final label in ['Beranda', 'Dokumen', 'Cari', 'Tracking']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    await tester.tap(find.text('Tracking'));
    await tester.pumpAndSettle();
    expect(find.text('Segera hadir'), findsOneWidget);
  });
}
