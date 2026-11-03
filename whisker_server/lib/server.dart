import 'dart:async';
import 'dart:io';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/github.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/backup/backup_job.dart';
import 'src/backup/backup_store.dart';
import 'src/doc/search_schema.dart';
import 'src/generated/protocol.dart';
import 'src/generated/serverpod.dart';
import 'src/github/remote_access.dart';
import 'src/hub/hub_service.dart';
import 'src/sync/remote_sync.dart';
import 'src/sync/webhook_route.dart';

/// Kunci passwords Whisker (lihat Guides/Serverpod.md).
const _passwordKeys = [
  'githubClientId',
  'githubAppId',
  'githubAppPrivateKey',
  'githubWebhookSecret',
  's3Endpoint',
  's3AccessKey',
  's3SecretKey',
  's3Bucket',
  's3Region',
];

/// Whisker MVP single-user: hanya ID pengguna GitHub di `githubAllowedUserIds`
/// (dipisah koma) yang boleh login. Tanpa daftar, semua login ditolak.
GitHubAccountDetailsValidation _allowGithubAccount(String? ids) {
  final allowed = (ids ?? '').split(',').map((e) => e.trim()).toSet()
    ..remove('');
  return (details) {
    GitHubIdpConfig.validateGitHubAccountDetails(details);
    if (!allowed.contains(details.userIdentifier)) {
      throw StateError('Akun GitHub ini tidak diizinkan.');
    }
  };
}

/// Titik awal server Whisker.
void run(List<String> args) async {
  final pod = Serverpod(args);
  final pw = {
    for (final k in _passwordKeys)
      if (pod.getPassword(k) case final v?) k: v,
  };

  pod.initializeAuthServices(
    tokenManagerBuilders: [JwtConfigFromPasswords()],
    identityProviderBuilders: [
      if (pw.containsKey('githubClientId'))
        GitHubIdpConfigFromPasswords(
          githubAccountDetailsValidation: _allowGithubAccount(
            pod.getPassword('githubAllowedUserIds'),
          ),
        ),
      // Login email hanya untuk pengembangan lokal (kode dicetak di log).
      if (pod.runMode == 'development')
        ServerpodCloudEmailIdpConfig(appDisplayName: 'Whisker'),
    ],
  );

  pod.addCloudStorage(
    await ServerpodCloudProvider.private(
      fallback: () => DatabaseCloudStorage('private'),
    ),
  );
  pod.addCloudStorage(
    await ServerpodCloudProvider.public(
      fallback: () => DatabaseCloudStorage('public'),
    ),
  );

  HubService.instance = HubService(
    remote: remoteAccessFromPasswords(pw),
    allowLocalRemotes: pod.runMode == 'development',
  );

  final webhookSecret = pw['githubWebhookSecret'];
  if (webhookSecret != null) {
    pod.webServer.addRoute(
      GithubWebhookRoute(webhookSecret),
      '/webhooks/github',
    );
  }

  await pod.start();

  final boot = await pod.createSession();
  await ensureSearchSchema(boot);
  await boot.close();

  _scheduleJobs(pod, MinioBackupStore.fromPasswords(pw));
}

/// Menjalankan [job] dengan sesi baru; error dicatat, tidak mematikan proses.
Future<T?> _guarded<T>(Serverpod pod, Future<T> Function(Session) job) async {
  Session? s;
  try {
    s = await pod.createSession();
    return await job(s);
  } catch (e, st) {
    stderr.writeln('Job terjadwal gagal: $e\n$st');
    return null;
  } finally {
    await s?.close();
  }
}

void _scheduleJobs(Serverpod pod, BackupStore? backup) {
  Timer.periodic(const Duration(minutes: 5), (_) {
    _guarded(pod, reconcileAll);
  });
  if (backup == null) return;

  // Backup penuh tiap 02.00 WIB; Hub yang gagal dicoba ulang tiap jam.
  Future<void> retry(List<Hub> failed) async {
    final still = await _guarded(
      pod,
      (s) => runDailyBackup(s, backup, DateTime.now().toUtc(), hubs: failed),
    );
    if (still == null || still.isNotEmpty) {
      Timer(const Duration(hours: 1), () => retry(still ?? failed));
    }
  }

  Future<void> daily() async {
    final failed = await _guarded(
      pod,
      (s) => runDailyBackup(s, backup, DateTime.now().toUtc()),
    );
    if (failed == null) {
      Timer(const Duration(hours: 1), daily);
      return;
    }
    if (failed.isNotEmpty) {
      Timer(const Duration(hours: 1), () => retry(failed));
    }
    Timer(untilNextBackup(DateTime.now().toUtc()), daily);
  }

  Timer(untilNextBackup(DateTime.now().toUtc()), daily);
}
