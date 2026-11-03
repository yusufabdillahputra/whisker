/// Area dokumen di Hub, mengikuti konvensi vault (lihat Guides/Konsep-Hub.md).
enum DocArea { knowledge, tracking, guide, other }

/// Hasil klasifikasi: area dari path, tipe dari path atau frontmatter `type`.
class DocClass {
  final DocArea area;
  final String? type;

  const DocClass(this.area, this.type);
}

const _pkm = {
  'ADR': 'adr',
  'API': 'api',
  'Architecture': 'architecture',
  'Business': 'business',
  'Database': 'entity',
  'Domain': 'domain',
  'Glosarium': 'glossary',
};

const _featureKinds = {'Plan': 'plan', 'Task': 'task'};
const _testKinds = {'Scenario': 'scenario', 'Run': 'run'};
const _topTracking = {
  'Confirmation': 'confirmation',
  'Question': 'question',
  'Dashboard': 'dashboard',
};

/// Klasifikasi dokumen dari [path] relatif ke akar Hub. Frontmatter `type`
/// (string) selalu menang untuk `type`.
DocClass classifyPath(String path, Map<String, Object?> frontmatter) {
  final c = _fromPath(path.split('/'));
  final t = frontmatter['type'];
  return t is String && t.trim().isNotEmpty ? DocClass(c.area, t.trim()) : c;
}

DocClass _fromPath(List<String> seg) {
  if (seg.contains('_LLM-Wiki')) return const DocClass(DocArea.other, 'mirror');
  if (seg.contains('_Format')) return const DocClass(DocArea.other, 'template');
  final dirs = seg.sublist(0, seg.length - 1);
  if (dirs.isEmpty) {
    return seg.single == 'CLAUDE.md'
        ? const DocClass(DocArea.guide, null)
        : const DocClass(DocArea.other, null);
  }
  final top = dirs.first;
  String? sub(Map<String, String> m) => dirs
      .skip(1)
      .map((d) => m[d])
      .firstWhere((x) => x != null, orElse: () => null);
  switch (top) {
    case 'PKM':
      return DocClass(
        DocArea.knowledge,
        dirs.length > 1 ? _pkm[dirs[1]] : null,
      );
    case 'Features':
      return DocClass(DocArea.tracking, sub(_featureKinds));
    case 'Test':
      return DocClass(DocArea.tracking, sub(_testKinds));
    case 'Guides':
      return const DocClass(DocArea.guide, null);
  }
  final t = _topTracking[top];
  return t != null
      ? DocClass(DocArea.tracking, t)
      : const DocClass(DocArea.other, null);
}
