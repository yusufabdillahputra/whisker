import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

String hubChannel(int hubId) => 'hub-$hubId';

/// Menyiarkan perubahan Hub ke semua pendengar `watch`.
Future<void> broadcastChange(Session s, HubChange change) async {
  await s.messages.postMessage(hubChannel(change.hubId), change);
}
