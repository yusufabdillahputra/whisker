import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker/features/hubs/hubs_page.dart';

import 'helpers.dart';

void main() {
  testWidgets('hubs_listed_and_created', (tester) async {
    final api = await pumpWhisker(tester, const HubsPage());
    expect(find.text('Hub Contoh'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Hub baru'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'Riset');
    await tester.enterText(find.byType(EditableText).at(1), 'saya/riset');
    await tester.tap(find.text('Buat Hub'));
    await tester.pumpAndSettle();
    expect((await api.hubs()).map((h) => h.name), contains('Riset'));
    expect(find.text('Riset'), findsOneWidget);
  });
}
