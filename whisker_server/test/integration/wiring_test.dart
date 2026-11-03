import 'package:test/test.dart';
import 'package:whisker_server/src/doc/search_schema.dart';
import 'package:whisker_server/src/sync/remote_sync.dart';

import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Wiring', (sessionBuilder, endpoints) {
    test('skema FTS dan rekonsiliasi kosong aman', () async {
      await setUpHubService(sessionBuilder);
      final s = sessionBuilder.build();
      await ensureSearchSchema(s);
      expect(await reconcileAll(s), 0);
    });
  });
}
