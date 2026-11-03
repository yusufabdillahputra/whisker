import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:markdown_codec/markdown_codec.dart';

import '../../data/providers.dart';
import '../editor/doc_session.dart';
import '../editor/editor_pane.dart';
import '../shell/workspace_page.dart';

/// Tanggal relatif berbahasa Indonesia.
String relativeDate(DateTime date, {DateTime? now}) {
  final d = (now ?? DateTime.now()).difference(date);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inHours < 1) return '${d.inMinutes} menit lalu';
  if (d.inDays < 1) return '${d.inHours} jam lalu';
  if (d.inDays < 30) return '${d.inDays} hari lalu';
  final l = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)}';
}

/// Isi YAML di antara baris `---` frontmatter.
String frontmatterInner(String raw) {
  if (raw.isEmpty) return '';
  final first = raw.indexOf('\n') + 1;
  final lastStart = raw.lastIndexOf(
    '\n',
    raw.endsWith('\n') ? raw.length - 2 : raw.length - 1,
  );
  return lastStart < first ? '' : raw.substring(first, lastStart + 1);
}

/// Frontmatter baru dari [inner], memakai baris pembuka/penutup dan newline
/// [raw] asli bila ada.
String frontmatterFrom(String raw, String inner, String newline) {
  final body = inner.replaceAll('\r\n', '\n');
  if (body.trim().isEmpty) return '';
  final text = (body.endsWith('\n') ? body : '$body\n').replaceAll(
    '\n',
    newline,
  );
  if (raw.isEmpty) return '---$newline$text---$newline';
  final first = raw.substring(0, raw.indexOf('\n') + 1);
  final lastStart = raw.lastIndexOf(
    '\n',
    raw.endsWith('\n') ? raw.length - 2 : raw.length - 1,
  );
  return first + text + raw.substring(lastStart + 1);
}

/// Inspector dokumen: Properties (frontmatter), Backlinks, Riwayat.
class Inspector extends ConsumerWidget {
  final int hubId;
  final String path;
  final ValueChanged<String>? onOpen;
  const Inspector({
    super.key,
    required this.hubId,
    required this.path,
    this.onOpen,
  });

  void _open(BuildContext context, String p) {
    if (onOpen != null) return onOpen!(p);
    GoRouter.maybeOf(context)?.go(docLocation(hubId, p));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (hubId, path);
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final muted = typography.body.sm.copyWith(color: colors.mutedForeground);
    Widget heading(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Semantics(
        header: true,
        child: Text(
          t,
          style: typography.body.md.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );

    final backlinks = ref.watch(backlinksProvider(key));
    final history = ref.watch(historyProvider(key));

    return ListView(
      children: [
        heading('Properties'),
        _Properties(hubId: hubId, path: path),
        heading('Backlinks'),
        ...backlinks.when(
          loading: () => [const Center(child: FCircularProgress())],
          error: (e, _) => [
            Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
          ],
          data: (list) => list.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Belum ada dokumen yang menautkan ke sini.',
                      style: muted,
                    ),
                  ),
                ]
              : [
                  for (final d in list)
                    FItem(
                      prefix: const Icon(FLucideIcons.link),
                      title: Text(d.title),
                      subtitle: Text(d.path),
                      onPress: () => _open(context, d.path),
                    ),
                ],
        ),
        heading('Riwayat'),
        ...history.when(
          loading: () => [const Center(child: FCircularProgress())],
          error: (e, _) => [
            Padding(padding: const EdgeInsets.all(16), child: Text('$e')),
          ],
          data: (list) => list.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Belum ada riwayat.', style: muted),
                  ),
                ]
              : [
                  for (final h in list)
                    FItem(
                      prefix: const Icon(FLucideIcons.gitCommitHorizontal),
                      title: Text(h.message),
                      subtitle: Text(
                        '${h.authorName} · ${relativeDate(h.date)}',
                      ),
                    ),
                ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _Properties extends ConsumerStatefulWidget {
  final int hubId;
  final String path;
  const _Properties({required this.hubId, required this.path});

  @override
  ConsumerState<_Properties> createState() => _PropertiesState();
}

class _PropertiesState extends ConsumerState<_Properties> {
  final _controller = TextEditingController();
  int _generation = -1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = (widget.hubId, widget.path);
    final s = ref.watch(docSessionProvider(key));
    final muted = context.theme.typography.body.sm.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    if (s == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text('Memuat…', style: muted),
      );
    }
    if (_generation != s.generation) {
      _generation = s.generation;
      _controller.text = frontmatterInner(s.frontmatter);
    }
    final parsed = splitFrontmatter('${s.frontmatter}x');
    final readOnly = isProtectedPath(widget.path);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in parsed.data.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${e.key}: ', style: muted),
                    TextSpan(text: '${e.value}'),
                  ],
                ),
              ),
            ),
          if (parsed.error != null)
            Text(
              'YAML tidak valid: ${parsed.error}',
              style: TextStyle(color: context.theme.colors.error),
            ),
          const SizedBox(height: 8),
          FTextField.multiline(
            key: const Key('frontmatter-yaml'),
            control: FTextFieldControl.managed(
              controller: _controller,
              onChange: (v) => ref
                  .read(docSessionProvider(key).notifier)
                  .setFrontmatter(
                    frontmatterFrom(s.frontmatter, v.text, s.original.newline),
                  ),
            ),
            label: const Text('Frontmatter (YAML)'),
            readOnly: readOnly,
            minLines: 3,
          ),
        ],
      ),
    );
  }
}
