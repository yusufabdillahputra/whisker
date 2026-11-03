import 'package:markdown_codec/markdown_codec.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../hub/hub_service.dart';
import '../index/indexer.dart';
import '../sync/hub_events.dart';
import 'safe_path.dart';

/// Pesan default `docs(<area>): update <judul>`.
String defaultCommitMessage(String path, String content) {
  final md = MdDocument.parse(content);
  final area = classifyPath(path, md.frontmatter.data).area.name;
  return 'docs($area): update ${extractTitle(md, path)}';
}

/// Alur commit spec 4.2: deteksi konflik terhadap `baseSha`, aturan Hub,
/// commit, push (rebase sekali bila remote maju), indeks ulang, siaran.
Future<CommitResult> commitDocument(Session session, CommitRequest req) async {
  final path = safePath(req.path);
  final svc = HubService.instance;
  await svc.requireMember(session, req.hubId, write: true);
  final author = await HubService.authorFor(session);

  return svc.locks.run(req.hubId, () async {
    final hub = (await Hub.db.findById(session, req.hubId))!;
    final repo = await svc.repoFor(hub);
    final url = await svc.remote.urlFor(hub);
    final branch = hub.defaultBranch;
    final remoteSha = await repo.remoteHead(url, branch);
    if (remoteSha != null) await repo.fetch(url, branch);
    final origin = remoteSha == null ? null : 'origin/$branch';

    final latestBlob = origin == null ? null : await repo.blobAt(origin, path);
    final baseBlob = req.baseSha == null
        ? null
        : await repo.blobAt(req.baseSha!, path);
    final latest = origin == null ? null : await repo.show(origin, path);
    if (latestBlob != baseBlob) {
      return CommitResult(
        status: 'conflict',
        latestContent: latest,
        latestSha: remoteSha,
      );
    }
    final reason = checkHubRules(path, latest, req.content);
    if (reason != null) return CommitResult(status: 'rejected', reason: reason);
    if (latest == req.content) {
      return CommitResult(status: 'ok', newSha: remoteSha);
    }

    if (origin != null) await repo.resetHard(origin);
    final before = hub.headSha;
    await repo.writeFile(path, req.content);
    final subject = req.message.trim().isEmpty
        ? defaultCommitMessage(path, req.content)
        : req.message.trim();
    final description = req.description?.trim() ?? '';
    await repo.commitAll(
      description.isEmpty ? subject : '$subject\n\n$description',
      author: author,
      committer: whiskerBot,
    );
    if (!await svc.pushWithRebase(hub, repo)) {
      if (origin != null) await repo.resetHard(origin);
      throw WhiskerException(message: 'Push gagal; coba lagi sebentar.');
    }
    final changed = await indexHub(session, hub, repo, fromSha: before);
    final head = (await repo.head())!;
    await broadcastChange(
      session,
      HubChange(hubId: hub.id!, headSha: head, paths: changed),
    );
    return CommitResult(status: 'ok', newSha: head);
  });
}
