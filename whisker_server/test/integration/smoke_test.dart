import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Smoke', (sessionBuilder, endpoints) {
    test('database dapat diakses', () async {
      final session = sessionBuilder.build();
      final rows = await session.db.unsafeQuery('select 1');
      expect(rows, hasLength(1));
    });
  });
}
