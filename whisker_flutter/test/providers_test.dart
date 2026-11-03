import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker/data/fake_api.dart';
import 'package:whisker/data/providers.dart';
import 'package:whisker_client/whisker_client.dart';

void main() {
  test('tree terurut dan dimuat ulang saat HubChange', () async {
    final api = FakeWhiskerApi.sample();
    final c = ProviderContainer(
      overrides: [apiProvider.overrideWithValue(api)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(treeProvider(1), (_, _) {});
    final tree = await c.read(treeProvider(1).future);
    final paths = tree.map((d) => d.path).toList();
    expect(paths, [...paths]..sort());
    expect(paths, contains('README.md'));

    await api.commit(
      CommitRequest(
        hubId: 1,
        path: 'Baru.md',
        content: '# Baru\n',
        message: 'tambah',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final again = await c.read(treeProvider(1).future);
    expect(again.map((d) => d.path), contains('Baru.md'));
    sub.close();
  });
}
