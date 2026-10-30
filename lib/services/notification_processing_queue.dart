import 'dart:async';

/// Serializes jobs that acquire their own card reservation. Borrowed channels
/// must run inline with their owner so they cannot wait on their own reservation.
class NotificationProcessingQueue {
  Future<void> _tail = Future.value();

  Future<void> run(Future<void> Function() action) {
    // Do not inherit a caller's reentrant adapter reservation into a later job.
    final next = _tail.then((_) => Zone.root.run(action));
    _tail = next.catchError((Object error) {});
    return next;
  }
}
