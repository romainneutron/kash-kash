import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';

/// Sync state
enum SyncState { idle, syncing, error }

/// Sync result
class SyncResult {
  final int pushedAttempts;
  final int pushedPathPoints;
  final int pulledQuests;
  final DateTime timestamp;

  const SyncResult({
    required this.pushedAttempts,
    required this.pushedPathPoints,
    required this.pulledQuests,
    required this.timestamp,
  });
}

/// Sync repository interface
abstract class ISyncRepository {
  /// Perform a full sync (push local changes, pull remote updates)
  Future<Either<Failure, SyncResult>> sync();

  /// Push local changes to server
  Future<Either<Failure, Unit>> push();

  /// Pull remote updates from server
  Future<Either<Failure, Unit>> pull();

  /// Get sync state stream
  Stream<SyncState> get stateStream;

  /// Get last sync time
  Future<DateTime?> get lastSyncTime;

  /// Check if there are pending sync operations
  Future<bool> get hasPendingOperations;
}
