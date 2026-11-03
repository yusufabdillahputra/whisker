import 'block.dart';
import 'document.dart';

/// Satu potongan body hasil editor.
///
/// - `blockIndex` + `markdown == null`: blok asli tanpa perubahan.
/// - `blockIndex` + `markdown`: blok asli yang diedit (tanpa newline akhir).
/// - `blockIndex == null`: blok baru berisi `markdown`.
class BodyPiece {
  final int? blockIndex;
  final String? markdown;
  const BodyPiece({this.blockIndex, this.markdown})
    : assert(blockIndex != null || markdown != null);
}

/// Indeks blok non-`blank` di [doc], berurutan.
List<int> contentBlockIndexes(MdDocument doc) => [
  for (var i = 0; i < doc.blocks.length; i++)
    if (doc.blocks[i].kind != MdBlockKind.blank) i,
];

/// Merakit ulang body dari [pieces].
///
/// Blok asli membawa baris kosong yang mendahuluinya; blok baru dipisah satu
/// baris kosong; baris kosong di awal dan akhir body asli dipertahankan.
/// Teks baru memakai newline dokumen. Bila [pieces] berisi semua blok asli
/// tanpa perubahan, hasilnya sama persis dengan body asli.
String assembleBody(MdDocument doc, List<BodyPiece> pieces) {
  final blocks = doc.blocks;
  final nl = doc.newline;
  final content = contentBlockIndexes(doc);

  String blanksBefore(int i) {
    final parts = <String>[];
    for (var j = i - 1; j >= 0 && blocks[j].kind == MdBlockKind.blank; j--) {
      parts.insert(0, blocks[j].source);
    }
    return parts.join();
  }

  String withNl(String s) => s.replaceAll('\r\n', '\n').replaceAll('\n', nl);

  String tailOf(String source) => source.endsWith('\r\n')
      ? '\r\n'
      : source.endsWith('\n')
      ? '\n'
      : '';

  final out = StringBuffer();
  final preamble = content.isEmpty
      ? blanksBefore(blocks.length)
      : blanksBefore(content.first);
  out.write(preamble);
  var emitted = false;
  int? prevOriginal;

  void ensureLineEnd() {
    final s = out.toString();
    if (s.isNotEmpty && !s.endsWith('\n')) out.write(nl);
  }

  for (final p in pieces) {
    final i = p.blockIndex;
    if (i == null) {
      ensureLineEnd();
      if (emitted) out.write(nl);
      out.write('${withNl(p.markdown!)}$nl');
      prevOriginal = null;
    } else {
      final pos = content.indexOf(i);
      final adjacent =
          prevOriginal != null && pos > 0 && content[pos - 1] == prevOriginal;
      var lead = emitted ? blanksBefore(i) : '';
      if (emitted && !adjacent && lead.isEmpty) lead = nl;
      ensureLineEnd();
      out.write(lead);
      final src = blocks[i].source;
      out.write(p.markdown == null ? src : withNl(p.markdown!) + tailOf(src));
      prevOriginal = i;
    }
    emitted = true;
  }

  if (content.isNotEmpty) {
    for (var j = content.last + 1; j < blocks.length; j++) {
      out.write(blocks[j].source);
    }
  }
  return out.toString();
}
