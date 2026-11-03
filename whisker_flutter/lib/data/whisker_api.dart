import 'dart:typed_data';

import 'package:whisker_client/whisker_client.dart';

/// Semua yang dibutuhkan aplikasi dari server Whisker.
abstract class WhiskerApi {
  Future<List<Hub>> hubs();
  Future<Hub> createHub(
    String name, {
    String? githubRepo,
    String? remoteUrl,
    int? installationId,
  });
  Future<Hub> importVault(int hubId, Uint8List zip);
  Future<List<DocSummary>> tree(int hubId);
  Future<DocContent> read(int hubId, String path);
  Future<List<SearchHit>> search(int hubId, String query);
  Future<List<DocSummary>> backlinks(int hubId, String path);
  Future<List<HistoryEntry>> history(int hubId, String path);
  Future<CommitResult> commit(CommitRequest request);
  Stream<HubChange> watch(int hubId);
}
