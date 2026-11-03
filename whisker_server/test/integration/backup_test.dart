import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:whisker_server/src/backup/backup_job.dart';
import 'package:whisker_server/src/backup/backup_store.dart';
import 'package:whisker_server/src/generated/protocol.dart';

import '../unit/git_test_helpers.dart';
import 'hub_test_helpers.dart';
import 'test_tools/serverpod_test_tools.dart';

class InMemoryBackupStore implements BackupStore {
  final objects = <String, List<int>>{};
  bool failPut = false;

  @override
  Future<void> put(String key, List<int> bytes) async {
    if (failPut) throw StateError('S3 mati');
    objects[key] = bytes;
  }

  @override
  Future<List<String>> list(String prefix) async =>
      objects.keys.where((k) => k.startsWith(prefix)).toList();

  @override
  Future<void> delete(String key) async => objects.remove(key);
}

void main() {
  withServerpod('Backup', (sessionBuilder, endpoints) {
    late Session s;
    late Hub hub;
    late InMemoryBackupStore store;
    // 2026-11-03 20:00 UTC = 2026-11-04 03:00 WIB.
    final now = DateTime.utc(2026, 11, 3, 20);

    setUp(() async {
      await setUpHubService(sessionBuilder);
      final me = asUser(sessionBuilder, const Uuid().v4obj());
      s = sessionBuilder.build();
      final remote = await bareRemote();
      await pushFiles(remote, {'a.md': '# A\n'});
      hub = await endpoints.hub.create(me, 'Cadangan', remoteUrl: remote);
      store = InMemoryBackupStore();
    });

    String key(String date) => 'backups/${hub.slug}/$date.zip';

    test('writes_zip_and_record', () async {
      expect(await runDailyBackup(s, store, now, hubs: [hub]), isTrue);
      expect(store.objects.keys, [key('2026-11-04')]);
      final rec = await BackupRecord.db.findFirstRow(
        s,
        where: (b) => b.hubId.equals(hub.id!),
      );
      expect([rec!.status, rec.objectKey], ['ok', key('2026-11-04')]);
      expect(rec.sizeBytes, greaterThan(0));
    });

    test('retention_keeps_seven', () async {
      for (var d = 25; d <= 31; d++) {
        store.objects[key('2026-10-$d')] = [1];
      }
      store.objects[key('2026-11-01')] = [1];
      store.objects['backups/lain/2026-01-01.zip'] = [1];
      await runDailyBackup(s, store, now, hubs: [hub]);
      final mine = (await store.list('backups/${hub.slug}/'))..sort();
      expect(mine, [
        key('2026-10-29'), key('2026-10-30'), key('2026-10-31'),
        key('2026-11-01'), key('2026-11-04'),
      ]);
      expect(store.objects.containsKey('backups/lain/2026-01-01.zip'), isTrue);
    });

    test('failure_keeps_old', () async {
      store.objects[key('2026-10-01')] = [1];
      store.failPut = true;
      expect(await runDailyBackup(s, store, now, hubs: [hub]), isFalse);
      expect(store.objects.keys, [key('2026-10-01')]);
      final rec = await BackupRecord.db.findFirstRow(
        s,
        where: (b) => b.hubId.equals(hub.id!),
      );
      expect(rec!.status, 'failed');
      expect(rec.error, contains('S3 mati'));
    });

    test('until_next_backup', () {
      expect(untilNextBackup(DateTime.utc(2026, 11, 3, 18)), const Duration(hours: 1));
      expect(untilNextBackup(DateTime.utc(2026, 11, 3, 20)), const Duration(hours: 23));
    });
  });
}
