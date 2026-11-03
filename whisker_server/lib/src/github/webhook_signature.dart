import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Memverifikasi header `X-Hub-Signature-256` (`sha256=<hex>`) secara
/// waktu-konstan.
bool verifyWebhookSignature(String secret, List<int> body, String? header) {
  if (header == null || !header.startsWith('sha256=')) return false;
  final expected = 'sha256=${Hmac(sha256, utf8.encode(secret)).convert(body)}';
  if (expected.length != header.length) return false;
  var diff = 0;
  for (var i = 0; i < expected.length; i++) {
    diff |= expected.codeUnitAt(i) ^ header.codeUnitAt(i);
  }
  return diff == 0;
}
