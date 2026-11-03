import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/generated/protocol.dart';
import 'package:whisker_server/src/github/github_app.dart';
import 'package:whisker_server/src/github/remote_access.dart';
import 'package:whisker_server/src/github/webhook_signature.dart';

Future<(String, String)> rsaPair() async {
  final dir = await Directory.systemTemp.createTemp('rsa-');
  await Process.run('openssl', ['genrsa', '-out', '${dir.path}/k.pem', '2048']);
  await Process.run('openssl', [
    'rsa',
    '-in',
    '${dir.path}/k.pem',
    '-pubout',
    '-out',
    '${dir.path}/p.pem',
  ]);
  return (
    await File('${dir.path}/k.pem').readAsString(),
    await File('${dir.path}/p.pem').readAsString(),
  );
}

Hub hub({int? installationId}) => Hub(
  name: 'A',
  slug: 'a',
  githubRepo: 'org/repo',
  remoteUrl: 'https://github.com/org/repo.git',
  installationId: installationId,
  ownerId: const Uuid().v4obj(),
);

void main() {
  late String priv, pub;
  setUpAll(() async => (priv, pub) = await rsaPair());

  GitHubAppRemoteAccess app(http.Client c, DateTime Function() now) =>
      GitHubAppRemoteAccess(
        appId: '123',
        privateKeyPem: priv,
        client: c,
        now: now,
      );

  test('jwt_claims_and_header', () async {
    String? auth;
    final now = DateTime.utc(2026, 11, 3, 10);
    final client = MockClient((req) async {
      auth = req.headers['authorization'];
      expect(req.url.path, '/app/installations/9/access_tokens');
      return http.Response(
        jsonEncode({'token': 't1', 'expires_at': '2026-11-03T11:00:00Z'}),
        201,
      );
    });
    expect(await app(client, () => now).installationToken(9), 't1');
    final jwt = JWT.verify(
      auth!.substring('Bearer '.length),
      RSAPublicKey(pub),
      checkExpiresIn: false,
      checkNotBefore: false,
    );
    final p = jwt.payload as Map;
    expect(p['iss'], '123');
    expect(p['iat'], now.millisecondsSinceEpoch ~/ 1000 - 60);
    expect(p['exp'], now.millisecondsSinceEpoch ~/ 1000 + 540);
  });

  test('token_cached_until_expiry', () async {
    var calls = 0;
    var now = DateTime.utc(2026, 11, 3, 10);
    final client = MockClient((req) async {
      calls++;
      return http.Response(
        jsonEncode({'token': 't$calls', 'expires_at': '2026-11-03T11:00:00Z'}),
        201,
      );
    });
    final a = app(client, () => now);
    expect(await a.installationToken(9), 't1');
    now = DateTime.utc(2026, 11, 3, 10, 58);
    expect(await a.installationToken(9), 't1');
    now = DateTime.utc(2026, 11, 3, 10, 59, 30);
    expect(await a.installationToken(9), 't2');
    expect(calls, 2);
  });

  test('url_uses_token', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({'token': 'tok', 'expires_at': '2099-01-01T00:00:00Z'}),
        201,
      ),
    );
    final a = app(client, DateTime.now);
    expect(
      await a.urlFor(hub(installationId: 9)),
      'https://x-access-token:tok@github.com/org/repo.git',
    );
    expect(await a.urlFor(hub()), 'https://github.com/org/repo.git');
  });

  test('plain_uses_remote_url', () async {
    expect(
      await PlainRemoteAccess().urlFor(hub(installationId: 9)),
      'https://github.com/org/repo.git',
    );
  });

  test('signature_ok_and_bad', () {
    final body = utf8.encode('{"a":1}');
    final sig = 'sha256=${Hmac(sha256, utf8.encode('s3')).convert(body)}';
    expect(verifyWebhookSignature('s3', body, sig), isTrue);
    expect(verifyWebhookSignature('lain', body, sig), isFalse);
    expect(verifyWebhookSignature('s3', body, null), isFalse);
    expect(verifyWebhookSignature('s3', body, 'sha256=00'), isFalse);
  });

  test('installation_id_for_repo', () async {
    final client = MockClient((req) async {
      if (req.url.path == '/repos/org/repo/installation') {
        return http.Response(jsonEncode({'id': 42}), 200);
      }
      return http.Response('{}', 404);
    });
    final a = app(client, DateTime.now);
    expect(await a.installationIdFor('org/repo'), 42);
    expect(await a.installationIdFor('org/lain'), isNull);
  });
}
