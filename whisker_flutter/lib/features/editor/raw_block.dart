import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'editor_codec.dart';

/// Blok yang disunting sebagai teks markdown mentah (Mermaid, callout,
/// tabel, HTML, …): label + kolom teks monospace.
class RawBlockComponentBuilder extends BlockComponentBuilder {
  RawBlockComponentBuilder({super.configuration, this.readOnly = false});

  final bool readOnly;

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return RawBlockWidget(
      key: node.key,
      node: node,
      configuration: configuration,
      readOnly: readOnly,
    );
  }

  @override
  BlockComponentValidate get validate =>
      (node) => node.children.isEmpty;
}

class RawBlockWidget extends BlockComponentStatefulWidget {
  const RawBlockWidget({
    super.key,
    required super.node,
    super.configuration = const BlockComponentConfiguration(),
    this.readOnly = false,
  });

  final bool readOnly;

  @override
  State<RawBlockWidget> createState() => _RawBlockWidgetState();
}

class _RawBlockWidgetState extends State<RawBlockWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final _boxKey = GlobalKey();
  late final _controller = TextEditingController(
    text: '${node.attributes[rawSourceKey] ?? ''}',
  );

  RenderBox? get _renderBox => context.findRenderObject() as RenderBox?;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    final editorState = context.read<EditorState>();
    final t = editorState.transaction..updateNode(node, {rawSourceKey: text});
    editorState.apply(t, withUpdateSelection: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = '${node.attributes[rawLabelKey] ?? 'Markdown'}';
    final child = Container(
      key: _boxKey,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            readOnly: widget.readOnly,
            maxLines: null,
            onChanged: _onChanged,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration.collapsed(hintText: label),
          ),
        ],
      ),
    );
    return Padding(
      padding: margin,
      child: Padding(padding: padding, child: child),
    );
  }

  @override
  Position start() => Position(path: node.path);

  @override
  Position end() => Position(path: node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) =>
      Offset.zero & (_renderBox?.size ?? Size.zero);

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) => _renderBox == null ? null : getBlockRect();

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) => _renderBox == null ? [] : [getBlockRect()];

  @override
  Selection getSelectionInRange(Offset start, Offset end) =>
      Selection.single(path: node.path, startOffset: 0, endOffset: 1);

  @override
  Offset localToGlobal(Offset offset, {bool shiftWithBaseOffset = false}) =>
      _renderBox!.localToGlobal(offset);

  @override
  TextDirection textDirection() => TextDirection.ltr;
}
