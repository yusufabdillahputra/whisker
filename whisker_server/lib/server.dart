import 'dart:async';

import 'package:serverpod_auth_idp_server/core.dart';
import 'package:serverpod_auth_idp_server/providers/email.dart';
import 'package:serverpod_auth_idp_server/providers/github.dart';
import 'package:serverpod_cloud_storage/serverpod_cloud_storage.dart';

import 'src/backup/backup_job.dart';
import 'src/backup/backup_store.dart';
import 'src/doc/search_schema.dart';
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
      if (pw.containsKey('githubClientId')) GitHubIdpConfigFromPasswords(),
      // Login email untuk pengembangan lokal (kode verifikasi dicetak di log).
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

  HubService.instance = HubService(remote: remoteAccessFromPasswords(pw));

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

  schedule(pod, BackupStore? backup) {
    Timer.periodic(const Duration(minutes: 5), (_) async {
      final s = await pod.createSession();
      try {
        await reconcileAll(s);
      } finally {
        await s.close();
      }
    });
    if (backup == null) return;
    Future<void> runBackup() async {
      final s = await pod.createSession();
      var ok = false;
      try {
        ok = await runDailyBackup(s, backup, DateTime.now().toUtc());
      } finally {
        await s.close();
      }
      final wait = ok
          ? untilNextBackup(DateTime.now().toUtc())
          : const Duration(hours: 1);
      Timer(wait, runBackup);
    }

    Timer(untilNextBackup(DateTime.now().toUtc()), runBackup);
  }

  schedule(pod, MinioBackupStore.fromPasswords(pw));
}
