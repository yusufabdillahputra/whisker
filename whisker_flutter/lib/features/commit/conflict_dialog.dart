import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// Pilihan pengguna saat commit konflik.
enum ConflictChoice { reload, keepDraft }

/// Dokumen sudah berubah di remote: tampilkan isi terbaru, pilih **Muat ulang
/// (buang draf)** atau **Tetap pakai draf saya**. Draf tidak dihapus di sini.
Future<ConflictChoice?> showConflictDialog(
  BuildContext context, {
  required String? latestContent,
}) => showFDialog<ConflictChoice>(
  context: context,
  builder: (context, style, animation) => FDialog(
    style: style,
    animation: animation,
    semanticsLabel: 'Konflik',
    constraints: const BoxConstraints(minWidth: 280, maxWidth: 720),
    builder: (context, style) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Konflik: dokumen sudah berubah',
            style: context.theme.typography.body.lg.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Seseorang mengubah dokumen ini sejak kamu membukanya. '
            'Drafmu tetap tersimpan.',
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: context.theme.colors.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Text(
                  latestContent ?? '(dokumen dihapus di remote)',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                onPress: () => Navigator.of(context).pop(ConflictChoice.reload),
                child: const Text('Muat ulang (buang draf)'),
              ),
              FButton(
                mainAxisSize: MainAxisSize.min,
                onPress: () =>
                    Navigator.of(context).pop(ConflictChoice.keepDraft),
                child: const Text('Tetap pakai draf saya'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);
