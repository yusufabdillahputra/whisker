import 'dart:typed_data';

import 'package:whisker_client/whisker_client.dart';

import 'whisker_api.dart';

/// [WhiskerApi] lewat client Serverpod.
class ServerpodWhiskerApi implements WhiskerApi {
  final Client client;
  ServerpodWhiskerApi(this.client);

  @override
  Future<List<Hub>> hubs() => client.hub.list();

  @override
  Future<Hub> createHub(
    String name, {
    String? githubRepo,
    String? remoteUrl,
    int? installationId,
  }) => client.hub.create(
    name,
    githubRepo: githubRepo,
    remoteUrl: remoteUrl,
    installationId: installationId,
  );

  @override
  Future<Hub> importVault(int hubId, Uint8List zip) =>
      client.hub.importVault(hubId, ByteData.sublistView(zip));

  @override
  Future<List<DocSummary>> tree(int hubId) => client.doc.tree(hubId);

  @override
  Future<DocContent> read(int hubId, String path) =>
      client.doc.read(hubId, path);

  @override
  Future<List<SearchHit>> search(int hubId, String query) =>
      client.doc.search(hubId, query);

  @override
  Future<List<DocSummary>> backlinks(int hubId, String path) =>
      client.doc.backlinks(hubId, path);

  @override
  Future<List<HistoryEntry>> history(int hubId, String path) =>
      client.doc.history(hubId, path);

  @override
  Future<CommitResult> commit(CommitRequest request) =>
      client.doc.commit(request);

  @override
  Stream<HubChange> watch(int hubId) => client.hub.watch(hubId);
}
