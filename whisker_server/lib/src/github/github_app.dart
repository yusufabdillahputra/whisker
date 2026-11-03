import 'dart:convert';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

import '../generated/protocol.dart';
import 'remote_access.dart';

/// Akses repo lewat token instalasi GitHub App (berumur pendek, di-cache).
class GitHubAppRemoteAccess implements RemoteAccess {
  final String appId;
  final String privateKeyPem;
  final http.Client _client;
  final DateTime Function() _now;
  final _cache = <int, (String, DateTime)>{};

  GitHubAppRemoteAccess({
    required this.appId,
    required this.privateKeyPem,
    http.Client? client,
    DateTime Function()? now,
  }) : _client = client ?? http.Client(),
       _now = now ?? DateTime.now;

  String _appJwt() {
    final iat = _now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return JWT({
      'iat': iat - 60,
      'exp': iat + 540,
      'iss': appId,
    }).sign(
      RSAPrivateKey(privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
      noIssueAt: true,
    );
  }

  /// Token instalasi; diperbarui 60 detik sebelum kedaluwarsa.
  Future<String> installationToken(int installationId) async {
    final cached = _cache[installationId];
    final now = _now().toUtc();
    if (cached != null &&
        now.isBefore(cached.$2.subtract(const Duration(seconds: 60)))) {
      return cached.$1;
    }
    final res = await _client.post(
      Uri.https(
        'api.github.com',
        '/app/installations/$installationId/access_tokens',
      ),
      headers: {
        'authorization': 'Bearer ${_appJwt()}',
        'accept': 'application/vnd.github+json',
        'x-github-api-version': '2022-11-28',
      },
    );
    if (res.statusCode != 201) {
      throw StateError('Token GitHub App gagal (${res.statusCode})');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final token = body['token'] as String;
    _cache[installationId] = (
      token,
      DateTime.parse(body['expires_at'] as String).toUtc(),
    );
    return token;
  }

  @override
  Future<String> urlFor(Hub hub) async {
    if (hub.installationId == null || hub.githubRepo == null) {
      return hub.remoteUrl;
    }
    final token = await installationToken(hub.installationId!);
    return 'https://x-access-token:$token@github.com/${hub.githubRepo}.git';
  }
}
