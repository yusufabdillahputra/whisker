// Cek asap server dev yang sedang berjalan lewat client hasil generate.
//
//   dart run bin/main.dart --apply-migrations   # terminal lain
//   dart run tool/e2e_check.dart [http://localhost:8080/]
//
// Alur lengkap aplikasi (buat Hub, impor, cari, commit, konflik) diuji di
// test/integration/e2e_test.dart; skrip ini memastikan server yang berjalan
// melayani endpoint Whisker dan menolak akses tanpa login.
import 'dart:io';

import 'package:whisker_client/whisker_client.dart';

Future<void> main(List<String> args) async {
  final url = args.isEmpty ? 'http://localhost:8080/' : args.first;
  final client = Client(url);
  var failed = false;

  Future<void> step(String name, Future<void> Function() run) async {
    try {
      await run();
      stdout.writeln('OK   $name');
    } catch (e) {
      failed = true;
      stdout.writeln('GAGAL $name: $e');
    }
  }

  Future<void> expectDenied(Future<Object?> Function() call) async {
    try {
      await call();
    } on ServerpodClientHttpException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) return;
      rethrow;
    }
    throw StateError('akses tanpa login tidak ditolak');
  }

  await step('hub.list menolak tanpa login', () => expectDenied(client.hub.list));
  await step(
    'doc.tree menolak tanpa login',
    () => expectDenied(() => client.doc.tree(1)),
  );
  client.close();
  exit(failed ? 1 : 0);
}
