import 'dart:typed_data';

import 'package:minio/minio.dart';

/// Penyimpanan objek untuk backup (S3-compatible).
abstract class BackupStore {
  Future<void> put(String key, List<int> bytes);
  Future<List<String>> list(String prefix);
  Future<void> delete(String key);
}

/// Object Storage S3-compatible (IDCloudHost) lewat paket `minio`.
class MinioBackupStore implements BackupStore {
  final Minio _minio;
  final String bucket;

  MinioBackupStore(this._minio, this.bucket);

  /// Dari passwords: `s3Endpoint`, `s3AccessKey`, `s3SecretKey`, `s3Bucket`,
  /// opsional `s3Region`. `null` bila belum dikonfigurasi.
  static MinioBackupStore? fromPasswords(Map<String, String> pw) {
    final endpoint = pw['s3Endpoint'];
    final access = pw['s3AccessKey'];
    final secret = pw['s3SecretKey'];
    final bucket = pw['s3Bucket'];
    if ([endpoint, access, secret, bucket].contains(null)) return null;
    return MinioBackupStore(
      Minio(
        endPoint: endpoint!,
        accessKey: access!,
        secretKey: secret!,
        region: pw['s3Region'],
        pathStyle: true,
      ),
      bucket!,
    );
  }

  @override
  Future<void> put(String key, List<int> bytes) async {
    await _minio.putObject(
      bucket,
      key,
      Stream.value(Uint8List.fromList(bytes)),
      size: bytes.length,
    );
  }

  @override
  Future<List<String>> list(String prefix) async {
    final r = await _minio.listAllObjects(
      bucket,
      prefix: prefix,
      recursive: true,
    );
    return [
      for (final o in r.objects)
        if (o.key != null) o.key!,
    ];
  }

  @override
  Future<void> delete(String key) => _minio.removeObject(bucket, key);
}
