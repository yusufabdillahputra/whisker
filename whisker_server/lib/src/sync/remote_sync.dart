import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../github/webhook_signature.dart';
import '../hub/hub_service.dart';
import '../index/indexer.dart';
import 'hub_events.dart';

/// Menyamakan clone kerja dengan remote (mis. setelah push dari PC), lalu
/// mengindeks file yang berubah dan menyiarkannya. `null` bila tidak ada
/// perubahan.
Future<HubChange?> syncFromRemote(Session s, Hub hub) {
  final svc = HubService.instance;
  return svc.locks.run(hub.id!, () async {
    final fresh = (await Hub.db.findById(s, hub.id!))!;
    final repo = await svc.repoFor(fresh);
    final url = await svc.remote.urlFor(fresh);
    final remoteSha = await repo.remoteHead(url, fresh.defaultBranch);
    if (remoteSha == null || remoteSha == fresh.headSha) return null;
    await repo.fetch(url, fresh.defaultBranch);
    await repo.resetHard('origin/${fresh.defaultBranch}');
    final paths = await indexHub(s, fresh, repo, fromSha: fresh.headSha);
    final change = HubChange(
      hubId: fresh.id!,
      headSha: remoteSha,
      paths: paths,
    );
    await broadcastChange(s, change);
    return change;
  });
}

/// Rekonsiliasi semua Hub (`ls-remote` vs `headSha`); mengembalikan jumlah Hub
/// yang disinkron. Error per Hub dicatat dan tidak menghentikan Hub lain.
Future<int> reconcileAll(Session s) async {
  var n = 0;
  for (final hub in await Hub.db.find(s)) {
    try {
      if (await syncFromRemote(s, hub) != null) n++;
    } catch (e) {
      s.log('Rekonsiliasi Hub ${hub.id} gagal: $e', level: LogLevel.warning);
    }
  }
  return n;
}

/// Menangani webhook GitHub; mengembalikan (status HTTP, pesan).
Future<(int, String)> handleGithubWebhook(
  Session s,
  Map<String, String> headers,
  List<int> body,
  String secret,
) async {
  if (!verifyWebhookSignature(secret, body, headers['x-hub-signature-256'])) {
    return (401, 'bad signature');
  }
  if (headers['x-github-event'] != 'push') return (202, 'ignored');
  final Map<String, dynamic> payload;
  try {
    payload = jsonDecode(utf8.decode(body)) as Map<String, dynamic>;
  } on FormatException {
    return (400, 'bad payload');
  }
  final repo = (payload['repository'] as Map?)?['full_name'] as String?;
  final ref = payload['ref'] as String?;
  if (repo == null) return (202, 'ignored');
  final hubs = await Hub.db.find(
    s,
    where: (h) => h.githubRepo.ilike(repo),
  );
  final targets = hubs.where((h) => ref == 'refs/heads/${h.defaultBranch}');
  if (targets.isEmpty) return (202, 'ignored');
  for (final hub in targets) {
    await syncFromRemote(s, hub);
  }
  return (200, 'synced');
}
