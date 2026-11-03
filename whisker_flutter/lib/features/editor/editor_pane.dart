import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:whisker_client/whisker_client.dart';

import '../../data/drafts.dart';
import '../../data/providers.dart';
import '../commit/commit_dialog.dart';
import '../commit/conflict_dialog.dart';
import 'doc_session.dart';
import 'editor_codec.dart';
import 'raw_block.dart';

/// `_Format/` dan `_LLM-Wiki/` tidak bisa di-commit sama sekali; ADR
/// accepted masih boleh mengubah frontmatter `status`.
bool isProtectedPath(String path) {
  final seg = path.split('/');
  return seg.contains('_Format') || seg.contains('_LLM-Wiki');
}

/// Panel editor satu dokumen: WYSIWYG + raw block, draf lokal (debounce
/// 800 ms), dan tombol **Commit changes**.
class EditorPane extends ConsumerStatefulWidget {
  final int hubId;
  final String path;
  const EditorPane({super.key, required this.hubId, required this.path});

  @override
  ConsumerState<EditorPane> createState() => EditorPaneState();
}

class EditorPaneState extends ConsumerState<EditorPane> {
  EditorState? editorState;
  StreamSubscription<EditorTransactionValue>? _sub;
  Timer? _draftTimer;
  int _builtGeneration = -1;
  bool _starting = false;
  Object? _loadError;

  DocKey get _key => (widget.hubId, widget.path);
  DocSessionNotifier get _session =>
      ref.read(docSessionProvider(_key).notifier);

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Memuat isi server (dan draf bila ada) lalu memulai sesi.
  Future<void> _start({bool ignoreDraft = false}) async {
    if (_starting) return;
    _starting = true;
    try {
      ref.invalidate(docProvider(_key));
      final server = await ref.read(docProvider(_key).future);
      final draft = ignoreDraft
          ? null
          : await ref.read(draftStoreProvider).load(widget.hubId, widget.path);
      if (!mounted) return;
      _session.start(
        server,
        draftContent: draft?.content == server.content ? null : draft?.content,
        draftBaseSha: draft?.baseSha,
      );
      setState(() => _loadError = null);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    } finally {
      _starting = false;
    }
  }

  void _buildEditor(DocSession s) {
    _sub?.cancel();
    editorState?.dispose();
    final es = EditorState(document: editorDocumentFrom(s.original));
    es.editable = s.readOnlyReason == null;
    _sub = es.transactionStream.listen((_) => _onEdited());
    editorState = es;
    _builtGeneration = s.generation;
  }

  void _onEdited() {
    final s = ref.read(docSessionProvider(_key));
    final es = editorState;
    if (s == null || es == null) return;
    _session.setBody(bodyFromEditor(s.original, es.document));
    _scheduleDraft();
  }

  void _scheduleDraft() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 800), _saveDraft);
  }

  Future<void> _saveDraft() async {
    final s = ref.read(docSessionProvider(_key));
    if (s == null) return;
    final store = ref.read(draftStoreProvider);
    if (s.dirty) {
      await store.save(widget.hubId, widget.path, s.content, s.baseSha);
    } else {
      await store.clear(widget.hubId, widget.path);
    }
  }

  Future<void> _commit() async {
    final s = ref.read(docSessionProvider(_key));
    if (s == null) return;
    _draftTimer?.cancel();
    await _saveDraft();
    if (!mounted) return;
    final api = ref.read(apiProvider);
    final result = await showCommitDialog(
      context,
      defaultMessage: defaultCommitMessage(widget.path, s.content),
      onCommit: (message, description) => api.commit(
        CommitRequest(
          hubId: widget.hubId,
          path: widget.path,
          content: ref.read(docSessionProvider(_key))!.content,
          message: message,
          description: description,
          baseSha: ref.read(docSessionProvider(_key))!.baseSha,
        ),
      ),
    );
    if (result == null || !mounted) return;
    switch (result.status) {
      case 'ok':
        _session.committed(result.newSha);
        await ref.read(draftStoreProvider).clear(widget.hubId, widget.path);
        ref.invalidate(historyProvider(_key));
        if (mounted) {
          showFToast(
            context: context,
            title: const Text('Perubahan di-commit.'),
          );
        }
      case 'conflict':
        final choice = await showConflictDialog(
          context,
          latestContent: result.latestContent,
        );
        if (!mounted) return;
        if (choice == ConflictChoice.reload) {
          await ref.read(draftStoreProvider).clear(widget.hubId, widget.path);
          await _start(ignoreDraft: true);
        } else if (choice == ConflictChoice.keepDraft) {
          _session.rebase(result.latestSha, result.latestContent);
          await _saveDraft();
        }
      default:
        showFToast(
          context: context,
          variant: FToastVariant.destructive,
          title: const Text('Commit ditolak'),
          description: Text(result.reason ?? 'Aturan Hub menolak perubahan.'),
        );
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _sub?.cancel();
    editorState?.dispose();
    super.dispose();
  }

  EditorStyle _style(BuildContext context, bool narrow) {
    final c = context.theme.colors;
    final text = TextStyleConfiguration(
      text: TextStyle(fontSize: 16, color: c.foreground),
      href: TextStyle(color: c.primary, decoration: TextDecoration.underline),
      code: TextStyle(
        fontFamily: 'monospace',
        color: c.foreground,
        backgroundColor: c.muted,
      ),
    );
    final padding = EdgeInsets.symmetric(
      horizontal: narrow ? 16 : 40,
      vertical: 16,
    );
    final touch =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return touch
        ? EditorStyle.mobile(
            padding: padding,
            cursorColor: c.primary,
            selectionColor: c.primary.withValues(alpha: 0.25),
            dragHandleColor: c.primary,
            textStyleConfiguration: text,
          )
        : EditorStyle.desktop(
            padding: padding,
            cursorColor: c.primary,
            selectionColor: c.primary.withValues(alpha: 0.25),
            textStyleConfiguration: text,
            maxWidth: 820,
          );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(docSessionProvider(_key));
    if (_loadError != null) {
      return Center(child: Text('Gagal membuka dokumen: $_loadError'));
    }
    if (s == null) return const Center(child: FCircularProgress());
    if (_builtGeneration != s.generation) _buildEditor(s);
    final narrow = MediaQuery.sizeOf(context).width < 700;
    final canCommit = s.dirty && !isProtectedPath(widget.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.path,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.theme.typography.body.sm.copyWith(
                    color: context.theme.colors.mutedForeground,
                  ),
                ),
              ),
              if (s.dirty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FBadge(
                    variant: FBadgeVariant.secondary,
                    child: const Text('Draf'),
                  ),
                ),
              FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: canCommit ? _commit : null,
                prefix: const Icon(FLucideIcons.gitCommitHorizontal),
                child: const Text('Commit changes'),
              ),
            ],
          ),
        ),
        if (s.readOnlyReason != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FAlert(
              key: const Key('readonly-banner'),
              icon: const Icon(FLucideIcons.lock),
              title: const Text('Baca saja'),
              subtitle: Text(s.readOnlyReason!),
            ),
          ),
        Expanded(
          child: Material(
            type: MaterialType.transparency,
            child: AppFlowyEditor(
              key: ValueKey(s.generation),
              editorState: editorState!,
              editable: s.readOnlyReason == null,
              editorStyle: _style(context, narrow),
              blockComponentBuilders: {
                ...standardBlockComponentBuilderMap,
                rawBlockType: RawBlockComponentBuilder(
                  readOnly: s.readOnlyReason != null,
                ),
              },
            ),
          ),
        ),
      ],
    );
  }
}
