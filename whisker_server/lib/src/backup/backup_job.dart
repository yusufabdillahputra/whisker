import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../hub/hub_service.dart';
import 'backup_store.dart';

const _wib = Duration(hours: 7);
const _keepDays = 7;

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Durasi sampai 02.00 WIB (19.00 UTC) berikutnya.
Duration untilNextBackup(DateTime nowUtc) {
  var next = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, 19);
  if (!next.isAfter(nowUtc)) next = next.add(const Duration(days: 1));
  return next.difference(nowUtc);
}

/// Backup zip harian semua Hub (atau [hubs]); `true` bila semua sukses.
///
/// Objek lebih tua dari 7 hari dihapus hanya untuk Hub yang backup hari ini
/// sukses.
Future<bool> runDailyBackup(
  Session s,
  BackupStore store,
  DateTime nowUtc, {
  List<Hub>? hubs,
}) async {
  final today = nowUtc.toUtc().add(_wib);
  final todayDate = DateTime.utc(today.year, today.month, today.day);
  final cutoff = _date(todayDate.subtract(const Duration(days: _keepDays - 1)));
  final svc = HubService.instance;
  var allOk = true;

  for (final hub in hubs ?? await Hub.db.find(s)) {
    final prefix = 'backups/${hub.slug}/';
    final key = '$prefix${_date(todayDate)}.zip';
    try {
      final bytes = await svc.locks.run(
        hub.id!,
        () async => (await svc.repoFor(hub)).archiveZip(),
      );
      await store.put(key, bytes);
      await BackupRecord.db.insertRow(
        s,
        BackupRecord(
          hubId: hub.id!,
          objectKey: key,
          sizeBytes: bytes.length,
          createdAt: DateTime.now().toUtc(),
          status: 'ok',
        ),
      );
      for (final old in await store.list(prefix)) {
        final name = old.substring(prefix.length).replaceFirst('.zip', '');
        if (name.compareTo(cutoff) < 0) await store.delete(old);
      }
    } catch (e) {
      allOk = false;
      s.log('Backup Hub ${hub.id} gagal: $e', level: LogLevel.error);
      await BackupRecord.db.insertRow(
        s,
        BackupRecord(
          hubId: hub.id!,
          objectKey: key,
          sizeBytes: 0,
          createdAt: DateTime.now().toUtc(),
          status: 'failed',
          error: '$e',
        ),
      );
    }
  }
  return allOk;
}
