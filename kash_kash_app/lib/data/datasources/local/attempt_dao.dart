import 'package:drift/drift.dart';

import 'database.dart';

part 'attempt_dao.g.dart';

/// Data Access Object for QuestAttempt operations.
@DriftAccessor(tables: [QuestAttempts])
class AttemptDao extends DatabaseAccessor<AppDatabase> with _$AttemptDaoMixin {
  AttemptDao(super.db);

  /// Get all attempts.
  Future<List<QuestAttempt>> getAll() {
    return select(questAttempts).get();
  }

  /// Get attempt by ID.
  Future<QuestAttempt?> getById(String id) {
    return (select(questAttempts)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get active (in-progress) attempt for a user.
  Future<QuestAttempt?> getActiveForUser(String userId) {
    return (select(questAttempts)
          ..where((a) => a.userId.equals(userId))
          ..where((a) => a.status.equals(AttemptStatus.inProgress.index)))
        .getSingleOrNull();
  }

  /// Get attempt history for a user (completed or abandoned).
  Future<List<QuestAttempt>> getHistoryForUser(String userId) {
    return (select(questAttempts)
          ..where((a) => a.userId.equals(userId))
          ..where((a) => a.status.isNotValue(AttemptStatus.inProgress.index))
          ..orderBy([(a) => OrderingTerm.desc(a.startedAt)]))
        .get();
  }

  /// Get all attempts for a specific quest.
  Future<List<QuestAttempt>> getForQuest(String questId) {
    return (select(questAttempts)
          ..where((a) => a.questId.equals(questId))
          ..orderBy([(a) => OrderingTerm.desc(a.startedAt)]))
        .get();
  }

  /// Watch attempt history for a user.
  Stream<List<QuestAttempt>> watchHistoryForUser(String userId) {
    return (select(questAttempts)
          ..where((a) => a.userId.equals(userId))
          ..where((a) => a.status.isNotValue(AttemptStatus.inProgress.index))
          ..orderBy([(a) => OrderingTerm.desc(a.startedAt)]))
        .watch();
  }

  /// Watch active attempt for a user.
  Stream<QuestAttempt?> watchActiveForUser(String userId) {
    return (select(questAttempts)
          ..where((a) => a.userId.equals(userId))
          ..where((a) => a.status.equals(AttemptStatus.inProgress.index)))
        .watchSingleOrNull();
  }

  /// Insert a new attempt.
  Future<void> insert(QuestAttempt attempt) {
    return into(questAttempts).insert(attempt);
  }

  /// Update an existing attempt.
  Future<bool> updateAttempt(QuestAttempt attempt) {
    return update(questAttempts).replace(attempt);
  }

  /// Insert or update an attempt.
  Future<void> upsert(QuestAttempt attempt) {
    return into(questAttempts).insertOnConflictUpdate(attempt);
  }

  /// Delete attempt by ID.
  Future<int> deleteById(String id) {
    return (delete(questAttempts)..where((a) => a.id.equals(id))).go();
  }

  /// Delete all attempts.
  Future<int> deleteAll() {
    return delete(questAttempts).go();
  }

  /// Count all attempts.
  Future<int> count() async {
    final query = selectOnly(questAttempts)
      ..addColumns([questAttempts.id.count()]);
    final result = await query.getSingle();
    return result.read(questAttempts.id.count()) ?? 0;
  }

  /// Count completed attempts for a user.
  Future<int> countCompletedForUser(String userId) async {
    final query = selectOnly(questAttempts)
      ..addColumns([questAttempts.id.count()])
      ..where(questAttempts.userId.equals(userId))
      ..where(questAttempts.status.equals(AttemptStatus.completed.index));
    final result = await query.getSingle();
    return result.read(questAttempts.id.count()) ?? 0;
  }

  /// Mark attempt as synced.
  Future<bool> markSynced(String id) {
    return (update(questAttempts)..where((a) => a.id.equals(id)))
        .write(const QuestAttemptsCompanion(synced: Value(true)))
        .then((rows) => rows > 0);
  }

  /// Get unsynced attempts.
  Future<List<QuestAttempt>> getUnsynced() {
    return (select(questAttempts)..where((a) => a.synced.equals(false))).get();
  }
}
