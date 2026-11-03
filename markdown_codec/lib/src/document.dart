import 'block.dart';
import 'frontmatter.dart';

/// Dokumen markdown vault: frontmatter + daftar blok.
///
/// Invariant: `MdDocument.parse(s).serialize() == s` untuk setiap `s`.
class MdDocument {
  final FrontmatterSplit frontmatter;
  final List<MdBlock> blocks;

  /// Newline dokumen (`\n` atau `\r\n`), dideteksi dari baris pertama.
  final String newline;

  const MdDocument({
    required this.frontmatter,
    required this.blocks,
    required this.newline,
  });

  static MdDocument parse(String input) {
    final fm = splitFrontmatter(input);
    return MdDocument(
      frontmatter: fm,
      blocks: List.unmodifiable(parseBlocks(fm.body)),
      newline: detectNewline(input),
    );
  }

  String serialize() => frontmatter.raw + blocks.map((b) => b.source).join();

  /// Salinan dokumen dengan blok ke-[index] diganti [block].
  MdDocument replaceBlock(int index, MdBlock block) => MdDocument(
    frontmatter: frontmatter,
    blocks: List.unmodifiable([...blocks]..[index] = block),
    newline: newline,
  );
}
