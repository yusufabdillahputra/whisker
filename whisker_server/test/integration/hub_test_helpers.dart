import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:whisker_server/src/doc/search_schema.dart';
import 'package:whisker_server/src/hub/hub_service.dart';

import 'test_tools/serverpod_test_tools.dart';

/// Builder sesi yang sudah login sebagai [userId].
TestSessionBuilder asUser(TestSessionBuilder b, UuidValue userId) =>
    b.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        userId.uuid,
        {},
      ),
    );

/// Menyiapkan HubService dengan data dir sementara dan skema FTS.
Future<void> setUpHubService(TestSessionBuilder b) async {
  final dir = await Directory.systemTemp.createTemp('whisker-data-');
  HubService.instance = HubService(dataDir: dir.path);
  await ensureSearchSchema(b.build());
}
