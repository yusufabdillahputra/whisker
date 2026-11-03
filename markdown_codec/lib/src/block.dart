/// Jenis blok markdown tingkat atas.
enum MdBlockKind {
  heading,
  paragraph,
  list,
  fence,
  blockquote,
  callout,
  table,
  thematicBreak,
  html,
  blank,
}

/// Satu blok markdown beserta teks aslinya.
///
/// [source] adalah potongan byte-identik dari dokumen, termasuk newline
/// penutupnya, sehingga gabungan `source` semua blok sama dengan body.
class MdBlock {
  final MdBlockKind kind;
  final String source;

  /// Level heading (1–6); `null` untuk jenis lain.
  final int? level;

  /// Info string fence (mis. `mermaid`) atau kepala callout (mis.
  /// `[!note] Catatan`); `null` untuk jenis lain.
  final String? info;

  /// Isi tanpa penanda, dengan newline `\n`.
  final String text;

  /// `true` bila blok dirender ulang lewat [MdBlock.edit].
  final bool edited;

  const MdBlock({
    required this.kind,
    required this.source,
    this.level,
    this.info,
    required this.text,
    this.edited = false,
  });

  /// Blok baru berisi [newText] yang dirender dengan penanda asli [original].
  ///
  /// Newline memakai [newline] (newline dokumen) bila diberikan, selain itu
  /// newline yang dipakai blok asli. Newline penutup blok asli dipertahankan.
  factory MdBlock.edit(MdBlock original, String newText, {String? newline}) {
    final nl = newline ?? (original.source.contains('\r\n') ? '\r\n' : '\n');
    final lines = _splitLines(original.source);
    final tail = lines.isEmpty ? '' : lines.last.eol;
    final body = newText.split('\n');
    String out;
    switch (original.kind) {
      case MdBlockKind.heading:
        out = '${'#' * original.level!} ${body.join(' ')}$tail';
      case MdBlockKind.fence:
        final open = lines.first.content;
        final hasClose =
            lines.length > 1 && _isFenceClose(open, lines.last.content);
        final parts = [open, ...body, if (hasClose) lines.last.content];
        out = parts.join(nl) + (hasClose ? tail : nl);
      case MdBlockKind.callout:
        out = [lines.first.content, ...body.map(_quote)].join(nl) + tail;
      case MdBlockKind.blockquote:
        out = body.map(_quote).join(nl) + tail;
      default:
        out = body.join(nl) + tail;
    }
    if (out.isNotEmpty && !out.endsWith('\n') && tail.isNotEmpty) out += tail;
    return MdBlock(
      kind: original.kind,
      source: out,
      level: original.level,
      info: original.info,
      text: newText,
      edited: true,
    );
  }
}

String _quote(String l) => l.isEmpty ? '>' : '> $l';

class _Line {
  final String content;
  final String eol;
  const _Line(this.content, this.eol);
  String get raw => content + eol;
  bool get isBlank => content.trim().isEmpty;
}

List<_Line> _splitLines(String s) {
  final out = <_Line>[];
  var start = 0;
  while (start < s.length) {
    final i = s.indexOf('\n', start);
    if (i < 0) {
      out.add(_Line(s.substring(start), ''));
      break;
    }
    final cr = i > start && s[i - 1] == '\r';
    out.add(_Line(s.substring(start, cr ? i - 1 : i), cr ? '\r\n' : '\n'));
    start = i + 1;
  }
  return out;
}

final _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
final _heading = RegExp(r'^ {0,3}(#{1,6})(?:[ \t]+(.*?))?[ \t]*$');
final _thematic = RegExp(
  r'^ {0,3}(?:(?:-[ \t]*){3,}|(?:\*[ \t]*){3,}|(?:_[ \t]*){3,})$',
);
final _listItem = RegExp(r'^ {0,3}(?:[-*+]|\d{1,9}[.)])(?:[ \t]|$)');
final _html = RegExp(r'^ {0,3}<[A-Za-z/!?]');
final _callout = RegExp(r'^ {0,3}> ?\[!');
final _quoteLine = RegExp(r'^ {0,3}>');
final _quotePrefix = RegExp(r'^ {0,3}> ?');

bool _isFenceClose(String open, String line) {
  final m = _fenceOpen.firstMatch(open);
  if (m == null) return false;
  final marker = m.group(1)!;
  final c = RegExp(
    '^ {0,3}(${RegExp.escape(marker[0])}{${marker.length},})[ \t]*\$',
  );
  return c.hasMatch(line);
}

bool _isHeading(String l) =>
    _heading.hasMatch(l) &&
    !RegExp(r'^ {0,3}#{1,6}[^ \t#]').hasMatch(l) &&
    !RegExp(r'^ {0,3}#{7}').hasMatch(l);

bool _startsBlock(String l) =>
    _fenceOpen.hasMatch(l) ||
    _isHeading(l) ||
    _quoteLine.hasMatch(l) ||
    l.startsWith('|') ||
    _thematic.hasMatch(l) ||
    _listItem.hasMatch(l) ||
    _html.hasMatch(l);

String _joinText(Iterable<String> ls) => ls.join('\n');

/// Memecah [body] menjadi blok tingkat atas.
///
/// Invariant: `parseBlocks(b).map((x) => x.source).join() == b`.
List<MdBlock> parseBlocks(String body) {
  final lines = _splitLines(body);
  final blocks = <MdBlock>[];
  var i = 0;

  String src(int from, int to) =>
      lines.sublist(from, to).map((l) => l.raw).join();

  while (i < lines.length) {
    final start = i;
    final l = lines[i].content;

    if (lines[i].isBlank) {
      while (i < lines.length && lines[i].isBlank) {
        i++;
      }
      blocks.add(
        MdBlock(kind: MdBlockKind.blank, source: src(start, i), text: ''),
      );
      continue;
    }

    final fence = _fenceOpen.firstMatch(l);
    if (fence != null &&
        !(fence.group(1)![0] == '`' && fence.group(2)!.contains('`'))) {
      i++;
      var closed = false;
      while (i < lines.length) {
        if (_isFenceClose(l, lines[i].content)) {
          closed = true;
          i++;
          break;
        }
        i++;
      }
      final inner = lines
          .sublist(start + 1, closed ? i - 1 : i)
          .map((x) => x.content);
      final info = fence.group(2)!.trim();
      blocks.add(
        MdBlock(
          kind: MdBlockKind.fence,
          source: src(start, i),
          info: info,
          text: _joinText(inner),
        ),
      );
      continue;
    }

    if (_isHeading(l)) {
      final m = _heading.firstMatch(l)!;
      final raw = (m.group(2) ?? '').replaceFirst(RegExp(r'[ \t]+#+$'), '');
      i++;
      blocks.add(
        MdBlock(
          kind: MdBlockKind.heading,
          source: src(start, i),
          level: m.group(1)!.length,
          text: raw == '#' * raw.length ? '' : raw,
        ),
      );
      continue;
    }

    if (_quoteLine.hasMatch(l)) {
      final isCallout = _callout.hasMatch(l);
      while (i < lines.length && _quoteLine.hasMatch(lines[i].content)) {
        i++;
      }
      final stripped = lines
          .sublist(start, i)
          .map((x) => x.content.replaceFirst(_quotePrefix, ''))
          .toList();
      blocks.add(
        MdBlock(
          kind: isCallout ? MdBlockKind.callout : MdBlockKind.blockquote,
          source: src(start, i),
          info: isCallout ? stripped.first : null,
          text: _joinText(isCallout ? stripped.skip(1) : stripped),
        ),
      );
      continue;
    }

    if (l.startsWith('|')) {
      while (i < lines.length && lines[i].content.startsWith('|')) {
        i++;
      }
      blocks.add(_plain(MdBlockKind.table, lines.sublist(start, i)));
      continue;
    }

    if (_thematic.hasMatch(l)) {
      i++;
      blocks.add(_plain(MdBlockKind.thematicBreak, lines.sublist(start, i)));
      continue;
    }

    if (_listItem.hasMatch(l)) {
      i++;
      while (i < lines.length &&
          !lines[i].isBlank &&
          (_listItem.hasMatch(lines[i].content) ||
              lines[i].content.startsWith(' ') ||
              lines[i].content.startsWith('\t'))) {
        i++;
      }
      blocks.add(_plain(MdBlockKind.list, lines.sublist(start, i)));
      continue;
    }

    if (_html.hasMatch(l)) {
      while (i < lines.length && !lines[i].isBlank) {
        i++;
      }
      blocks.add(_plain(MdBlockKind.html, lines.sublist(start, i)));
      continue;
    }

    i++;
    while (i < lines.length &&
        !lines[i].isBlank &&
        !_startsBlock(lines[i].content)) {
      i++;
    }
    blocks.add(_plain(MdBlockKind.paragraph, lines.sublist(start, i)));
  }
  return blocks;
}

MdBlock _plain(MdBlockKind kind, List<_Line> ls) => MdBlock(
  kind: kind,
  source: ls.map((l) => l.raw).join(),
  text: _joinText(ls.map((l) => l.content)),
);
