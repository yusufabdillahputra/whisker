import 'dart:async';

/// Antrean FIFO per Hub: satu operasi git per Hub sekaligus.
class HubLocks {
  final _tails = <int, Future<void>>{};

  Future<T> run<T>(int hubId, Future<T> Function() action) {
    final prev = _tails[hubId] ?? Future<void>.value();
    final done = Completer<void>();
    final next = done.future;
    _tails[hubId] = next;
    return prev.then((_) => action()).whenComplete(() {
      done.complete();
      if (identical(_tails[hubId], next)) _tails.remove(hubId);
    });
  }
}
