import 'package:yaml/yaml.dart';

/// Hasil pemisahan frontmatter YAML dari body markdown.
///
/// Invariant: `raw + body` sama persis dengan input.
class FrontmatterSplit {
  /// Teks dari `---` pembuka sampai baris `---` penutup beserta newline-nya;
  /// string kosong bila dokumen tidak punya frontmatter.
  final String raw;

  /// Isi YAML yang sudah di-parse; kosong bila tidak ada atau tidak valid.
  final Map<String, Object?> data;

  /// Pesan error parse YAML, atau `null` bila valid / tidak ada frontmatter.
  final String? error;

  /// Sisa dokumen setelah frontmatter.
  final String body;

  const FrontmatterSplit({
    required this.raw,
    required this.data,
    required this.error,
    required this.body,
  });
}

/// Newline yang dipakai dokumen, ditentukan dari baris pertama.
String detectNewline(String input) {
  final i = input.indexOf('\n');
  return i > 0 && input[i - 1] == '\r' ? '\r\n' : '\n';
}

final _open = RegExp('^\uFEFF?---\\r?\\n');
final _close = RegExp(r'^---\r?$', multiLine: true);

/// Memisahkan frontmatter YAML di awal [input] tanpa mengubah teksnya.
FrontmatterSplit splitFrontmatter(String input) {
  final none = FrontmatterSplit(
    raw: '',
    data: const {},
    error: null,
    body: input,
  );
  final open = _open.matchAsPrefix(input);
  if (open == null) return none;
  final close = _close.firstMatch(input.substring(open.end));
  if (close == null) return none;

  var end = open.end + close.end;
  if (end < input.length && input[end] == '\n') end++;
  final raw = input.substring(0, end);
  final yamlText = input.substring(open.end, open.end + close.start);

  Map<String, Object?> data = const {};
  String? error;
  try {
    final parsed = loadYaml(yamlText);
    if (parsed is Map) {
      data = _toPlain(parsed) as Map<String, Object?>;
    } else if (parsed != null) {
      error = 'frontmatter bukan map YAML';
    }
  } on YamlException catch (e) {
    error = e.toString();
  }
  return FrontmatterSplit(
    raw: raw,
    data: data,
    error: error,
    body: input.substring(end),
  );
}

Object? _toPlain(Object? v) {
  if (v is Map) {
    return <String, Object?>{
      for (final e in v.entries) '${e.key}': _toPlain(e.value),
    };
  }
  if (v is List) return [for (final x in v) _toPlain(x)];
  return v;
}
