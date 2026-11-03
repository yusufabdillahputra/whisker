import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whisker_client/whisker_client.dart';

import 'whisker_api.dart';

/// Diganti di `main` (Serverpod) atau test/demo (`FakeWhiskerApi`).
final apiProvider = Provider<WhiskerApi>(
  (ref) => throw UnimplementedError('apiProvider belum di-override'),
);

/// `true` saat dijalankan dengan `--dart-define=WHISKER_DEMO=true`.
final demoModeProvider = Provider<bool>((ref) => false);

typedef DocKey = (int hubId, String path);

final hubsProvider = FutureProvider<List<Hub>>(
  (ref) => ref.watch(apiProvider).hubs(),
);

/// Aliran `HubChange` per Hub. Tree, backlinks, dan riwayat menontonnya
/// sehingga dimuat ulang tiap ada perubahan; editor dan `local_sync`
/// mendengarnya untuk tahu dokumen terbuka berubah di remote.
final hubWatchProvider = StreamProvider.family<HubChange, int>(
  (ref, hubId) => ref.watch(apiProvider).watch(hubId),
);

final treeProvider = FutureProvider.family<List<DocSummary>, int>((ref, hubId) {
  ref.watch(hubWatchProvider(hubId));
  return ref.watch(apiProvider).tree(hubId);
});

final docProvider = FutureProvider.family<DocContent, DocKey>(
  (ref, key) => ref.watch(apiProvider).read(key.$1, key.$2),
);

final backlinksProvider = FutureProvider.family<List<DocSummary>, DocKey>(
  (ref, key) {
    ref.watch(hubWatchProvider(key.$1));
    return ref.watch(apiProvider).backlinks(key.$1, key.$2);
  },
);

final historyProvider = FutureProvider.family<List<HistoryEntry>, DocKey>(
  (ref, key) {
    ref.watch(hubWatchProvider(key.$1));
    return ref.watch(apiProvider).history(key.$1, key.$2);
  },
);
