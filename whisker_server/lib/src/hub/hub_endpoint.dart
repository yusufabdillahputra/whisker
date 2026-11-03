import 'dart:typed_data';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../index/indexer.dart';
import '../sync/hub_events.dart';
import 'hub_service.dart';
import 'vault_import.dart';

/// Kelola Hub: daftar, buat, impor vault, indeks ulang.
class HubEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  HubService get _svc => HubService.instance;

  /// Hub tempat pengguna menjadi anggota.
  Future<List<Hub>> list(Session session) async {
    final uid = HubService.userId(session);
    final members = await HubMember.db.find(
      session,
      where: (m) => m.userId.equals(uid),
    );
    if (members.isEmpty) return [];
    return Hub.db.find(
      session,
      where: (h) => h.id.inSet(members.map((m) => m.hubId).toSet()),
      orderBy: (h) => h.name,
    );
  }

  /// Membuat Hub yang terhubung ke repo; isi repo langsung diindeks.
  Future<Hub> create(
    Session session,
    String name, {
    String? githubRepo,
    String? remoteUrl,
    int? installationId,
    String? defaultBranch,
  }) async {
    final uid = HubService.userId(session);
    final url =
        remoteUrl ??
        (githubRepo == null ? null : 'https://github.com/$githubRepo.git');
    if (name.trim().isEmpty || url == null) {
      throw WhiskerException(message: 'Nama dan repo Hub wajib diisi.');
    }
    final hub = await Hub.db.insertRow(
      session,
      Hub(
        name: name.trim(),
        slug: await _uniqueSlug(session, name),
        githubRepo: githubRepo,
        remoteUrl: url,
        installationId: installationId,
        defaultBranch: defaultBranch ?? 'main',
        ownerId: uid,
      ),
    );
    await HubMember.db.insertRow(
      session,
      HubMember(hubId: hub.id!, userId: uid, role: 'owner'),
    );
    try {
      final repo = await _svc.repoFor(hub);
      await indexHub(session, hub, repo);
    } catch (e) {
      await HubMember.db.deleteWhere(
        session,
        where: (m) => m.hubId.equals(hub.id!),
      );
      await Hub.db.deleteRow(session, hub);
      session.log('Gagal clone Hub: $e', level: LogLevel.warning);
      throw WhiskerException(message: 'Repo Hub tidak bisa di-clone.');
    }
    return (await Hub.db.findById(session, hub.id!))!;
  }

  /// Mengimpor vault Obsidian (zip) lalu commit, push, dan indeks penuh.
  Future<Hub> importVault(Session session, int hubId, ByteData zip) async {
    final hub = await _svc.requireMember(session, hubId, write: true);
    final author = await HubService.authorFor(session);
    return _svc.locks.run(hubId, () async {
      final repo = await _svc.repoFor(hub);
      final n = await extractVault(
        repo,
        zip.buffer.asUint8List(zip.offsetInBytes, zip.lengthInBytes),
      );
      if (n == 0) throw WhiskerException(message: 'Zip vault kosong.');
      await repo.commitAll(
        'chore: impor vault',
        author: author,
        committer: whiskerBot,
      );
      await repo.removeIgnored();
      if (!await _svc.pushWithRebase(hub, repo)) {
        await repo.resetHard('origin/${hub.defaultBranch}');
        throw WhiskerException(message: 'Push impor vault gagal.');
      }
      final paths = await indexHub(session, hub, repo);
      await broadcastChange(
        session,
        HubChange(hubId: hubId, headSha: (await repo.head())!, paths: paths),
      );
      return (await Hub.db.findById(session, hubId))!;
    });
  }

  /// Membangun ulang indeks Hub dari clone kerja.
  Future<Hub> reindex(Session session, int hubId) async {
    final hub = await _svc.requireMember(session, hubId, write: true);
    return _svc.locks.run(hubId, () async {
      await indexHub(session, hub, await _svc.repoFor(hub));
      return (await Hub.db.findById(session, hubId))!;
    });
  }

  /// Aliran perubahan Hub (commit dari aplikasi, push dari PC).
  Stream<HubChange> watch(Session session, int hubId) async* {
    await _svc.requireMember(session, hubId);
    yield* session.messages.createStream<HubChange>(hubChannel(hubId));
  }

  Future<String> _uniqueSlug(Session session, String name) async {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final root = base.isEmpty ? 'hub' : base;
    var slug = root;
    for (
      var i = 2;
      await Hub.db.findFirstRow(session, where: (h) => h.slug.equals(slug)) !=
          null;
      i++
    ) {
      slug = '$root-$i';
    }
    return slug;
  }
}
