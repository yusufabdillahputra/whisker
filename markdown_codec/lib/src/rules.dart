import 'dart:convert';

import 'classify.dart';
import 'frontmatter.dart';

const _lockedKeys = {'status', 'superseded_by'};

String? _protectedReason(String path) {
  final seg = path.split('/');
  if (seg.contains('_LLM-Wiki')) {
    return 'Dokumen _LLM-Wiki adalah mirror dan tidak bisa diedit.';
  }
  if (seg.contains('_Format')) {
    return 'Dokumen _Format adalah template dan tidak bisa diedit.';
  }
  return null;
}

bool _isAcceptedAdr(String path, FrontmatterSplit fm) =>
    classifyPath(path, fm.data).type == 'adr' &&
    fm.data['status'] == 'accepted';

/// Alasan dokumen dibuka baca saja di editor, atau `null` bila bisa diedit.
String? readOnlyReason(String path, String content) {
  final p = _protectedReason(path);
  if (p != null) return p;
  if (_isAcceptedAdr(path, splitFrontmatter(content))) {
    return 'ADR berstatus accepted terkunci; hanya status dan superseded_by '
        'yang bisa diubah.';
  }
  return null;
}

/// Memeriksa perubahan [oldContent] → [newContent] pada [path] terhadap
/// aturan Hub. `null` berarti boleh; selain itu alasan penolakan.
String? checkHubRules(String path, String? oldContent, String newContent) {
  final p = _protectedReason(path);
  if (p != null) return p;
  if (oldContent == null) return null;
  final before = splitFrontmatter(oldContent);
  if (!_isAcceptedAdr(path, before)) return null;
  final after = splitFrontmatter(newContent);
  String rest(FrontmatterSplit f) => jsonEncode({
    for (final e in f.data.entries)
      if (!_lockedKeys.contains(e.key)) e.key: e.value,
  });
  if (before.body != after.body || rest(before) != rest(after)) {
    return 'ADR berstatus accepted hanya boleh mengubah status dan '
        'superseded_by.';
  }
  return null;
}
