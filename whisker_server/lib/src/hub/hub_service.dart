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

  HubService({String? dataDir, RemoteAccess? remote})
    : dataDir = dataDir ?? Platform.environment['WHISKER_DATA_DIR'] ?? '.data',
      remote = remote ?? PlainRemoteAccess();

  String repoDir(int hubId) => '$dataDir/hubs/$hubId';

  /// Clone kerja Hub; dibuat dari remote bila belum ada di disk.
  Future<GitRepo> repoFor(Hub hub) async {
    final dir = repoDir(hub.id!);
    if (await Directory('$dir/.git').exists()) return GitRepo(dir);
    return GitRepo.clone(
      await remote.urlFor(hub),
      dir,
      branch: hub.defaultBranch,
    );
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
  Future<bool> pushWithRebase(Hub hub, GitRepo repo) async {
    final url = await remote.urlFor(hub);
    if (await repo.push(url, hub.defaultBranch)) return true;
    await repo.fetch(url, hub.defaultBranch);
    if (!await repo.rebaseOnto('origin/${hub.defaultBranch}')) return false;
    return repo.push(url, hub.defaultBranch);
  }
}
