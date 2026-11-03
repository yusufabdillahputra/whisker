import '../generated/protocol.dart';
import 'github_app.dart';

/// Menentukan URL git (beserta kredensial bila perlu) untuk sebuah Hub.
abstract class RemoteAccess {
  Future<String> urlFor(Hub hub);

  /// Lupakan kredensial yang di-cache untuk [hub] (mis. setelah push gagal).
  void invalidate(Hub hub) {}
}

final _githubUrl = RegExp(r'^https://github\.com/[\w.-]+/[\w.-]+?(\.git)?$');
final _githubRepo = RegExp(r'^[\w.-]+/[\w.-]+$');

/// `null` bila [url] boleh dipakai sebagai remote Hub, selain itu alasannya.
/// Produksi hanya `https://github.com/<owner>/<repo>`; [allowLocal] juga
/// mengizinkan path absolut lokal (dev/test).
String? validateRemoteUrl(String url, {bool allowLocal = false}) {
  if (url.startsWith('-') || url.contains('::')) {
    return 'URL remote tidak valid.';
  }
  if (_githubUrl.hasMatch(url)) return null;
  if (allowLocal && url.startsWith('/')) return null;
  return 'Remote harus https://github.com/<owner>/<repo>.';
}

/// `true` bila [repo] berbentuk `owner/name`.
bool isGithubRepoName(String repo) => _githubRepo.hasMatch(repo);

/// Memakai `hub.remoteUrl` apa adanya (path lokal, atau remote dengan
/// kredensial dari helper git sistem).
class PlainRemoteAccess extends RemoteAccess {
  @override
  Future<String> urlFor(Hub hub) async => hub.remoteUrl;
}

/// GitHub App bila `githubAppId` dan `githubAppPrivateKey` ada di passwords,
/// selain itu [PlainRemoteAccess].
RemoteAccess remoteAccessFromPasswords(Map<String, String> pw) {
  final id = pw['githubAppId'];
  final key = pw['githubAppPrivateKey'];
  if (id == null || key == null) return PlainRemoteAccess();
  return GitHubAppRemoteAccess(appId: id, privateKeyPem: key);
}
