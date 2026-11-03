import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:markdown_codec/markdown_codec.dart';
import 'package:whisker_client/whisker_client.dart';

/// Pesan default `docs(<area>): update <judul>` (sama dengan server).
String defaultCommitMessage(String path, String content) {
  final md = MdDocument.parse(content);
  final area = classifyPath(path, md.frontmatter.data).area.name;
  return 'docs($area): update ${extractTitle(md, path)}';
}

/// Dialog **Commit changes** ala GitHub web: Pesan (terisi default) dan
/// Deskripsi opsional. [onCommit] dipanggil saat **Commit** ditekan;
/// hasilnya dikembalikan, atau `null` bila dibatalkan.
Future<CommitResult?> showCommitDialog(
  BuildContext context, {
  required String defaultMessage,
  required Future<CommitResult> Function(String message, String? description)
  onCommit,
}) {
  final message = TextEditingController(text: defaultMessage);
  final description = TextEditingController();
  return showFDialog<CommitResult>(
    context: context,
    builder: (context, style, animation) {
      var busy = false;
      String? error;
      return StatefulBuilder(
        builder: (context, setState) => FDialog(
          style: style,
          animation: animation,
          semanticsLabel: 'Commit changes',
          builder: (context, style) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Commit changes',
                  style: context.theme.typography.body.lg.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                FTextField(
                  key: const Key('commit-message'),
                  control: FTextFieldControl.managed(controller: message),
                  label: const Text('Pesan commit'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                FTextField.multiline(
                  key: const Key('commit-description'),
                  control: FTextFieldControl.managed(controller: description),
                  label: const Text('Deskripsi (opsional)'),
                  minLines: 3,
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(color: context.theme.colors.error),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FButton(
                      variant: FButtonVariant.outline,
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    FButton(
                      mainAxisSize: MainAxisSize.min,
                      onPress: busy
                          ? null
                          : () async {
                              setState(() {
                                busy = true;
                                error = null;
                              });
                              try {
                                final d = description.text.trim();
                                final r = await onCommit(
                                  message.text.trim().isEmpty
                                      ? defaultMessage
                                      : message.text.trim(),
                                  d.isEmpty ? null : d,
                                );
                                if (context.mounted) {
                                  Navigator.of(context).pop(r);
                                }
                              } catch (e) {
                                setState(() {
                                  busy = false;
                                  error = e is WhiskerException
                                      ? e.message
                                      : '$e';
                                });
                              }
                            },
                      child: const Text('Commit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
