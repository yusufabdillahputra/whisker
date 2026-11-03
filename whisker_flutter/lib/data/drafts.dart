import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Draf lokal satu dokumen.
class Draft {
  final String content;
  final String? baseSha;

  /// Isi server saat draf mulai dibuat; beda dengan isi server sekarang
  /// berarti draf berasal dari versi lama.
  final String? baseContent;
  const Draft(this.content, this.baseSha, {this.baseContent});
}

/// Draf per (`hubId`, `path`) di `shared_preferences`; tetap ada saat
/// konflik dan baru dihapus setelah commit berhasil atau dibuang pengguna.
class DraftStore {
  String _key(int hubId, String path) => 'whisker.draft.$hubId.$path';

  Future<void> save(
    int hubId,
    String path,
    String content,
    String? baseSha, {
    String? baseContent,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key(hubId, path),
      jsonEncode({
        'content': content,
        'baseSha': baseSha,
        'baseContent': baseContent,
      }),
    );
  }

  Future<Draft?> load(int hubId, String path) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key(hubId, path));
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return Draft(
      m['content'] as String,
      m['baseSha'] as String?,
      baseContent: m['baseContent'] as String?,
    );
  }

  Future<void> clear(int hubId, String path) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key(hubId, path));
  }
}

final draftStoreProvider = Provider<DraftStore>((ref) => DraftStore());
