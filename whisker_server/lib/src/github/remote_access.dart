import '../generated/protocol.dart';
import 'github_app.dart';

/// Menentukan URL git (beserta kredensial bila perlu) untuk sebuah Hub.
abstract class RemoteAccess {
  Future<String> urlFor(Hub hub);
}

/// Memakai `hub.remoteUrl` apa adanya (path lokal, atau remote dengan
/// kredensial dari helper git sistem).
class PlainRemoteAccess implements RemoteAccess {
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
