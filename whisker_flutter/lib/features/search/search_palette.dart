import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:whisker_client/whisker_client.dart';

import '../../data/providers.dart';

/// Kolom cari + hasil (judul dan snippet). Debounce 250 ms; Enter membuka
/// hasil pertama. Dipakai palet `Ctrl K` dan tab **Cari** di ponsel.
class SearchPanel extends ConsumerStatefulWidget {
  final int hubId;
  final ValueChanged<String> onOpen;
  final bool autofocus;
  const SearchPanel({
    super.key,
    required this.hubId,
    required this.onOpen,
    this.autofocus = true,
  });

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  Timer? _debounce;
  List<SearchHit> _hits = const [];
  String _query = '';
  bool _loading = false;
  int _seq = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _changed(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(q));
  }

  Future<void> _run(String q) async {
    final seq = ++_seq;
    setState(() {
      _query = q.trim();
      _loading = _query.isNotEmpty;
    });
    if (_query.isEmpty) {
      setState(() => _hits = const []);
      return;
    }
    try {
      final hits = await ref.read(apiProvider).search(widget.hubId, _query);
      if (mounted && seq == _seq) {
        setState(() {
          _hits = hits;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = context.theme.typography.body.sm.copyWith(
      color: context.theme.colors.mutedForeground,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: FTextField(
            key: const Key('search-field'),
            autofocus: widget.autofocus,
            hint: 'Cari di Hub…',
            textInputAction: TextInputAction.done,
            control: FTextFieldControl.managed(
              onChange: (v) => _changed(v.text),
            ),
            onSubmit: (_) {
              if (_hits.isNotEmpty) widget.onOpen(_hits.first.path);
            },
          ),
        ),
        Flexible(
          child: _loading && _hits.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: FCircularProgress()),
                )
              : _query.isNotEmpty && _hits.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Tidak ada hasil untuk "$_query".', style: muted),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final h in _hits)
                      FItem(
                        key: const Key('search-hit'),
                        prefix: const Icon(FLucideIcons.fileText),
                        title: Text(h.title),
                        subtitle: Text(
                          h.snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        details: Text(h.path, style: muted),
                        onPress: () => widget.onOpen(h.path),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Palet pencarian `Ctrl K`; mengembalikan path dokumen terpilih.
Future<String?> showSearchPalette(BuildContext context, int hubId) =>
    showFDialog<String>(
      context: context,
      builder: (context, style, animation) => FDialog(
        style: style,
        animation: animation,
        semanticsLabel: 'Cari',
        constraints: const BoxConstraints(
          minWidth: 280,
          maxWidth: 640,
          maxHeight: 520,
        ),
        builder: (context, style) => SearchPanel(
          hubId: hubId,
          onOpen: (p) => Navigator.of(context).pop(p),
        ),
      ),
    );
