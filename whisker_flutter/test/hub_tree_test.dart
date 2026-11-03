import 'package:flutter_test/flutter_test.dart';
import 'package:whisker/features/hub_tree/hub_tree.dart';
import 'package:whisker_client/whisker_client.dart';

import 'helpers.dart';

DocSummary doc(String path, String title, String area) =>
    DocSummary(path: path, title: title, area: area);

void main() {
  testWidgets('tree_groups_folders', (tester) async {
    final opened = <String>[];
    await pumpWhisker(
      tester,
      HubTree(
        docs: [
          doc('PKM/ADR/a.md', 'Keputusan A', 'knowledge'),
          doc('PKM/API/b.md', 'API B', 'knowledge'),
          doc('README.md', 'Beranda', 'other'),
        ],
        activePath: 'PKM/API/b.md',
        onOpen: opened.add,
      ),
    );
    expect(find.text('PKM'), findsOneWidget);
    expect(find.text('ADR'), findsOneWidget);
    expect(find.text('API'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);

    await tester.tap(find.text('Keputusan A'));
    expect(opened, ['PKM/ADR/a.md']);

    // Folder bisa dilipat.
    await tester.tap(find.text('ADR'));
    await tester.pumpAndSettle();
    expect(find.text('Keputusan A'), findsNothing);
    expect(find.text('API B'), findsOneWidget);
  });
}
