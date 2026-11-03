import 'block.dart';
import 'document.dart';

/// Tautan wiki `[[target#heading|alias]]` atau embed `![[target]]`.
class WikiLink {
  /// Nama dokumen/berkas tujuan; `''` berarti dokumen sendiri (`[[#Bagian]]`).
  final String target;
  final String? heading;
  final String? alias;
  final bool embed;

  const WikiLink({
    required this.target,
    this.heading,
    this.alias,
    this.embed = false,
  });
}

final _inlineCode = RegExp(r'(`+)[\s\S]*?\1');
final _wikilink = RegExp(
  r'(!)?\[\[([^\]\|#]*)(?:#([^\]\|]*))?(?:\|([^\]]*))?\]\]',
);

/// Semua wikilink di [doc], kecuali yang berada di fence, HTML, atau kode
/// inline.
List<WikiLink> extractWikilinks(MdDocument doc) {
  final out = <WikiLink>[];
  for (final b in doc.blocks) {
    if (b.kind == MdBlockKind.fence || b.kind == MdBlockKind.html) continue;
    final text = b.source.replaceAll(_inlineCode, '');
    for (final m in _wikilink.allMatches(text)) {
      out.add(
        WikiLink(
          target: m.group(2)!.trim(),
          heading: m.group(3)?.trim(),
          alias: m.group(4)?.trim(),
          embed: m.group(1) != null,
        ),
      );
    }
  }
  return out;
}

/// Judul dokumen: frontmatter `title` → heading level 1 pertama → nama file
/// dari [path] tanpa `.md`.
String extractTitle(MdDocument doc, String path) {
  final t = doc.frontmatter.data['title'];
  if (t != null && '$t'.trim().isNotEmpty) return '$t'.trim();
  for (final b in doc.blocks) {
    if (b.kind == MdBlockKind.heading && b.level == 1 && b.text.isNotEmpty) {
      return b.text.trim();
    }
  }
  final name = path.split(RegExp(r'[\\/]')).last;
  return name.endsWith('.md') ? name.substring(0, name.length - 3) : name;
}

/// Tag dari frontmatter `tags` (list atau string dipisah koma/spasi): di-trim,
/// tanpa `#`, unik, urutan asli.
List<String> extractTags(MdDocument doc) {
  final raw = doc.frontmatter.data['tags'];
  final Iterable<String> parts = switch (raw) {
    List l => l.map((e) => '$e'),
    String s => s.split(RegExp(r'[,\s]+')),
    _ => const [],
  };
  final seen = <String>{};
  return [
    for (final p in parts)
      if (p.trim().replaceFirst(RegExp(r'^#+'), '') case final t
          when t.isNotEmpty && seen.add(t))
        t,
  ];
}
