import 'dart:async';
import 'dart:typed_data';

import 'package:markdown_codec/markdown_codec.dart';
import 'package:whisker_client/whisker_client.dart';

import 'whisker_api.dart';

/// [WhiskerApi] di memori untuk test dan mode demo; isi contoh sintetis.
///
/// Tiap file menyimpan riwayat versinya; `sha` versi berbentuk `v<n>` global
/// sehingga deteksi konflik meniru server (bandingkan versi terbaru file
/// dengan versi pada `baseSha`).
class FakeWhiskerApi implements WhiskerApi {
  final _hubs = <int, Hub>{};
  final _files = <int, Map<String, List<_Version>>>{};
  final _controllers = <int, StreamController<HubChange>>{};
  var _seq = 0;

  /// Permintaan commit yang diterima (untuk test).
  final commits = <CommitRequest>[];

  FakeWhiskerApi();

  /// Satu Hub (id 1) berisi dokumen contoh yang menyentuh semua jenis blok.
  factory FakeWhiskerApi.sample() {
    final api = FakeWhiskerApi();
    api.addHub(
      Hub(
        id: 1,
        name: 'Hub Contoh',
        slug: 'hub-contoh',
        remoteUrl: 'https://github.com/contoh/hub-contoh.git',
        defaultBranch: 'main',
        ownerId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
      ),
      sampleFiles,
    );
    return api;
  }

  void addHub(Hub hub, Map<String, String> files) {
    _hubs[hub.id!] = hub;
    final m = _files[hub.id!] = {};
    for (final e in files.entries) {
      m[e.key] = [_Version(_nextSha(), e.value, 'chore: isi awal', 'Whisker')];
    }
  }

  String _nextSha() => 'v${++_seq}';

  String get _head => 'v$_seq';

  Map<String, List<_Version>> _hub(int hubId) {
    final m = _files[hubId];
    if (m == null) throw WhiskerException(message: 'Hub tidak ditemukan.');
    return m;
  }

  _Version? _latest(int hubId, String path) {
    final v = _hub(hubId)[path];
    return v == null || v.isEmpty ? null : v.last;
  }

  /// Versi file [path] pada commit [sha] (versi terakhir yang `<= sha`).
  _Version? _at(int hubId, String path, String sha) {
    final n = int.parse(sha.substring(1));
    _Version? found;
    for (final v in _hub(hubId)[path] ?? const <_Version>[]) {
      if (int.parse(v.sha.substring(1)) <= n) found = v;
    }
    return found;
  }

  /// Mensimulasikan push dari PC: file berubah tanpa lewat aplikasi.
  void externalEdit(int hubId, String path, String content) {
    _hub(hubId)
        .putIfAbsent(path, () => [])
        .add(
          _Version(_nextSha(), content, 'docs: edit dari PC', 'PC'),
        );
    _emit(hubId, [path]);
  }

  void _emit(int hubId, List<String> paths) {
    _controllers[hubId]?.add(
      HubChange(hubId: hubId, headSha: _head, paths: paths),
    );
  }

  DocSummary _summary(String path, String content) {
    final md = MdDocument.parse(content);
    final fm = md.frontmatter.data;
    final c = classifyPath(path, fm);
    return DocSummary(
      path: path,
      title: extractTitle(md, path),
      area: c.area.name,
      type: c.type,
      status: fm['status']?.toString(),
    );
  }

  @override
  Future<List<Hub>> hubs() async => _hubs.values.toList();

  @override
  Future<Hub> createHub(
    String name, {
    String? githubRepo,
    String? remoteUrl,
    int? installationId,
  }) async {
    final id =
        (_hubs.keys.isEmpty ? 0 : _hubs.keys.reduce((a, b) => a > b ? a : b)) +
        1;
    final hub = Hub(
      id: id,
      name: name,
      slug: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      githubRepo: githubRepo,
      remoteUrl: remoteUrl ?? 'https://github.com/$githubRepo.git',
      defaultBranch: 'main',
      ownerId: UuidValue.fromString('00000000-0000-4000-8000-000000000001'),
    );
    addHub(hub, const {'README.md': '# Hub baru\n'});
    return hub;
  }

  @override
  Future<Hub> importVault(int hubId, Uint8List zip) async => _hubs[hubId]!;

  @override
  Future<List<DocSummary>> tree(int hubId) async {
    final out = [
      for (final e in _hub(hubId).entries)
        if (e.value.isNotEmpty) _summary(e.key, e.value.last.content),
    ];
    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }

  @override
  Future<DocContent> read(int hubId, String path) async {
    final v = _latest(hubId, path);
    if (v == null) {
      throw WhiskerException(message: 'Dokumen tidak ditemukan: $path');
    }
    return DocContent(
      path: path,
      content: v.content,
      blobSha: v.sha,
      baseSha: _head,
      readOnlyReason: readOnlyReason(path, v.content),
    );
  }

  @override
  Future<List<SearchHit>> search(int hubId, String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final hits = <SearchHit>[];
    for (final e in _hub(hubId).entries) {
      if (e.value.isEmpty) continue;
      final text = e.value.last.content;
      final i = text.toLowerCase().indexOf(q);
      if (i < 0) continue;
      final from = (i - 40).clamp(0, text.length);
      final to = (i + q.length + 40).clamp(0, text.length);
      hits.add(
        SearchHit(
          path: e.key,
          title: _summary(e.key, text).title,
          snippet: text.substring(from, to).replaceAll('\n', ' '),
          rank: 1,
        ),
      );
    }
    hits.sort((a, b) => a.path.compareTo(b.path));
    return hits;
  }

  @override
  Future<List<DocSummary>> backlinks(int hubId, String path) async {
    final name = path.split('/').last.replaceAll(RegExp(r'\.md$'), '');
    final noExt = path.replaceAll(RegExp(r'\.md$'), '');
    final out = <DocSummary>[];
    for (final e in _hub(hubId).entries) {
      if (e.key == path || e.value.isEmpty) continue;
      final md = MdDocument.parse(e.value.last.content);
      final hit = extractWikilinks(md).any(
        (l) => l.target == name || l.target == noExt || l.target == path,
      );
      if (hit) out.add(_summary(e.key, e.value.last.content));
    }
    return out;
  }

  @override
  Future<List<HistoryEntry>> history(int hubId, String path) async {
    final versions = _hub(hubId)[path] ?? const <_Version>[];
    return [
      for (final v in versions.reversed)
        HistoryEntry(
          sha: v.sha,
          message: v.message,
          authorName: v.author,
          date: v.date,
        ),
    ];
  }

  @override
  Future<CommitResult> commit(CommitRequest r) async {
    commits.add(r);
    final latest = _latest(r.hubId, r.path);
    final base = r.baseSha == null ? null : _at(r.hubId, r.path, r.baseSha!);
    if (latest?.sha != base?.sha) {
      return CommitResult(
        status: 'conflict',
        latestContent: latest?.content,
        latestSha: _head,
      );
    }
    final reason = checkHubRules(r.path, latest?.content, r.content);
    if (reason != null) return CommitResult(status: 'rejected', reason: reason);
    if (latest?.content == r.content) {
      return CommitResult(status: 'ok', newSha: _head);
    }
    final msg = r.message.trim().isEmpty
        ? 'docs: update ${r.path}'
        : r.message.trim();
    _hub(r.hubId)
        .putIfAbsent(r.path, () => [])
        .add(
          _Version(_nextSha(), r.content, msg, 'Kamu'),
        );
    _emit(r.hubId, [r.path]);
    return CommitResult(status: 'ok', newSha: _head);
  }

  @override
  Stream<HubChange> watch(int hubId) => _controllers
      .putIfAbsent(hubId, () => StreamController<HubChange>.broadcast())
      .stream;
}

class _Version {
  final String sha;
  final String content;
  final String message;
  final String author;
  final DateTime date;
  _Version(this.sha, this.content, this.message, this.author)
    : date = DateTime.now();
}

/// Isi contoh sintetis (bukan konten klien).
const sampleFiles = <String, String>{
  'README.md': '''# Hub Contoh

Selamat datang di Hub contoh Whisker. Mulai dari [[Kucing Calico]] atau
lihat keputusan di [[ADR-0001 Pakai Git]].

- Pengetahuan ada di `PKM/Catatan/`
- Keputusan ada di `PKM/ADR/`
''',
  'PKM/Catatan/Kucing Calico.md': '''---
title: Kucing Calico
tags: [kucing, warna]
---
# Kucing Calico

Kucing calico punya tiga warna bulu: putih, oranye, dan hitam.

> [!note] Catatan
> Hampir semua kucing calico betina.

| Warna | Token |
| --- | --- |
| Oranye | ginger |
| Hitam | ink |

- bulu putih
- bulu oranye
- bulu hitam

Lihat juga [[README]].
''',
  'PKM/Catatan/Arsitektur.md': '''# Arsitektur

Alur sinkron Hub:

```mermaid
flowchart LR
  App --> Server --> GitHub
  PC --> GitHub
```

Server adalah satu-satunya penulis dari aplikasi. Lihat [[Kucing Calico]].
''',
  'PKM/ADR/ADR-0001 Pakai Git.md': '''---
type: adr
status: accepted
---
# ADR-0001 Pakai Git

Sumber kebenaran Hub adalah repo git.
''',
  'Features/_Format/Template Fitur.md': '''# Template Fitur

## Tujuan

## Kriteria sukses
''',
};
