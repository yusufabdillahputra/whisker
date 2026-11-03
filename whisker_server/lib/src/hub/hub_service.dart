import 'dart:io';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';

import '../generated/protocol.dart';
import '../git/git_repo.dart';
import '../git/hub_locks.dart';
import '../github/remote_access.dart';

/// Committer untuk semua commit yang dibuat server.
const whiskerBot = GitIdentity('Whisker', 'bot@whisker.local');

/// Layanan bersama: lokasi clone kerja, antrean per Hub, akses remote, dan
/// pemeriksaan keanggotaan.
class HubService {
  static HubService instance = HubService();

  final String dataDir;
  final RemoteAccess remote;
  final HubLocks locks = HubLocks();

  /// Izinkan remote berupa path lokal (dev/test); produksi hanya GitHub.
  final bool allowLocalRemotes;

  HubService({
    String? dataDir,
    RemoteAccess? remote,
    this.allowLocalRemotes = false,
  }) : dataDir = dataDir ?? Platform.environment['WHISKER_DATA_DIR'] ?? '.data',
       remote = remote ?? PlainRemoteAccess();

  String repoDir(int hubId) => '$dataDir/hubs/$hubId';

  /// Clone kerja Hub; dibuat dari remote bila belum ada di disk.
  ///
  /// Clone pertama dibuat di direktori sementara lalu di-rename, sehingga
  /// direktori Hub hanya ada bila clone lengkap; panggilan bersamaan berbagi
  /// satu proses clone.
  Future<GitRepo> repoFor(Hub hub) async {
    final dir = repoDir(hub.id!);
    if (await Directory('$dir/.git').exists()) return GitRepo(dir);
    final pending = _cloning.putIfAbsent(hub.id!, () => _cloneFresh(hub, dir));
    try {
      return await pending;
    } finally {
      // ignore: unawaited_futures
      _cloning.remove(hub.id!);
    }
  }

  final _cloning = <int, Future<GitRepo>>{};

  Future<GitRepo> _cloneFresh(Hub hub, String dir) async {
    final tmp = '$dir.tmp-${DateTime.now().microsecondsSinceEpoch}';
    try {
      await GitRepo.clone(
        await remote.urlFor(hub),
        tmp,
        branch: hub.defaultBranch,
      );
      await Directory(dir).parent.create(recursive: true);
      await Directory(tmp).rename(dir);
      return GitRepo(dir);
    } catch (_) {
      final t = Directory(tmp);
      if (await t.exists()) await t.delete(recursive: true);
      rethrow;
    }
  }

  static UuidValue userId(Session s) {
    final auth = s.authenticated;
    if (auth == null) throw WhiskerException(message: 'Belum login.');
    return auth.authUserId;
  }

  /// Hub [hubId] bila pengguna anggota; [write] menuntut peran owner/editor.
  Future<Hub> requireMember(Session s, int hubId, {bool write = false}) async {
    final uid = userId(s);
    final member = await HubMember.db.findFirstRow(
      s,
      where: (m) => m.hubId.equals(hubId) & m.userId.equals(uid),
    );
    final hub = await Hub.db.findById(s, hubId);
    if (member == null || hub == null) {
      throw WhiskerException(message: 'Hub tidak ditemukan atau tanpa akses.');
    }
    if (write && member.role == 'viewer') {
      throw WhiskerException(message: 'Peran viewer tidak bisa mengubah Hub.');
    }
    return hub;
  }

  /// Identitas author git dari profil pengguna.
  static Future<GitIdentity> authorFor(Session s) async {
    final uid = userId(s);
    final p = await UserProfile.db.findFirstRow(
      s,
      where: (t) => t.authUserId.equals(uid),
    );
    final name = p?.fullName ?? p?.userName ?? 'Whisker User';
    final email = p?.email ?? 'user-${uid.uuid}@users.whisker.local';
    return GitIdentity(name, email);
  }

  /// Push dengan satu kali rebase bila remote maju; `false` bila tetap gagal.
  ///
  /// Error jaringan/kredensial juga dianggap gagal (`false`).
  Future<bool> pushWithRebase(Hub hub, GitRepo repo) async {
    try {
      final url = await remote.urlFor(hub);
      if (await repo.push(url, hub.defaultBranch)) return true;
      await repo.fetch(url, hub.defaultBranch);
      final rebased = await repo.rebaseOnto(
        'origin/${hub.defaultBranch}',
        committer: whiskerBot,
      );
      return rebased && await repo.push(url, hub.defaultBranch);
    } on Exception {
      return false;
    }
  }

  /// [pushWithRebase]; bila gagal, kredensial di-refresh dan dicoba sekali
  /// lagi. Tetap gagal → clone dikembalikan ke `origin` dan
  /// [WhiskerException] dilempar.
  Future<void> pushOrReset(Hub hub, GitRepo repo) async {
    if (await pushWithRebase(hub, repo)) return;
    remote.invalidate(hub);
    if (await pushWithRebase(hub, repo)) return;
    final origin = 'origin/${hub.defaultBranch}';
    if (await repo.revParse(origin) != null) await repo.resetHard(origin);
    throw WhiskerException(
      message: 'Push gagal; perubahan tidak disimpan. Coba lagi.',
    );
  }
}
