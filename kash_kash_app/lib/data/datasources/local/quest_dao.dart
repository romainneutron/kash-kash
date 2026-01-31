import 'package:drift/drift.dart';

import 'database.dart';

part 'quest_dao.g.dart';

/// Data Access Object for Quest operations.
@DriftAccessor(tables: [Quests])
class QuestDao extends DatabaseAccessor<AppDatabase> with _$QuestDaoMixin {
  QuestDao(super.db);

  /// Get all published quests.
  Future<List<Quest>> getAllPublished() {
    return (select(quests)..where((q) => q.published.equals(true))).get();
  }

  /// Get all quests (including unpublished).
  Future<List<Quest>> getAll() {
    return select(quests).get();
  }

  /// Get quest by ID.
  Future<Quest?> getById(String id) {
    return (select(quests)..where((q) => q.id.equals(id))).getSingleOrNull();
  }

  /// Watch all published quests as a stream.
  Stream<List<Quest>> watchAllPublished() {
    return (select(quests)..where((q) => q.published.equals(true))).watch();
  }

  /// Watch all quests as a stream.
  Stream<List<Quest>> watchAll() {
    return select(quests).watch();
  }

  /// Insert or update a quest.
  Future<void> upsert(Quest quest) {
    return into(quests).insertOnConflictUpdate(quest);
  }

  /// Batch insert or update multiple quests.
  ///
  /// Set [markAsSynced] to true when data is fetched from remote and should
  /// be marked as synchronized. Set to false when caching local changes that
  /// still need to be synced to the server.
  Future<void> batchUpsert(
    List<Quest> questList, {
    bool markAsSynced = false,
  }) async {
    await batch((batch) {
      for (final quest in questList) {
        batch.insert(
          quests,
          quest,
          onConflict: DoUpdate(
            (old) => QuestsCompanion(
              title: Value(quest.title),
              description: Value(quest.description),
              latitude: Value(quest.latitude),
              longitude: Value(quest.longitude),
              radiusMeters: Value(quest.radiusMeters),
              createdBy: Value(quest.createdBy),
              published: Value(quest.published),
              difficulty: Value(quest.difficulty),
              locationType: Value(quest.locationType),
              updatedAt: Value(quest.updatedAt),
              syncedAt: markAsSynced ? Value(DateTime.now()) : const Value.absent(),
            ),
          ),
        );
      }
    });
  }

  /// Insert a new quest.
  Future<void> insertQuest(Quest quest) {
    return into(quests).insert(quest);
  }

  /// Update an existing quest.
  Future<bool> updateQuest(Quest quest) {
    return update(quests).replace(quest);
  }

  /// Delete quest by ID.
  Future<int> deleteById(String id) {
    return (delete(quests)..where((q) => q.id.equals(id))).go();
  }

  /// Delete all quests.
  Future<int> deleteAll() {
    return delete(quests).go();
  }

  /// Get quests created by a specific user.
  Future<List<Quest>> getByCreator(String userId) {
    return (select(quests)..where((q) => q.createdBy.equals(userId))).get();
  }

  /// Count all quests.
  Future<int> count() async {
    final query = selectOnly(quests)..addColumns([quests.id.count()]);
    final result = await query.getSingle();
    return result.read(quests.id.count()) ?? 0;
  }

  /// Count published quests.
  Future<int> countPublished() async {
    final query = selectOnly(quests)
      ..addColumns([quests.id.count()])
      ..where(quests.published.equals(true));
    final result = await query.getSingle();
    return result.read(quests.id.count()) ?? 0;
  }

  /// Mark quest as synced with current timestamp.
  Future<bool> markSynced(String id) {
    return (update(quests)..where((q) => q.id.equals(id)))
        .write(QuestsCompanion(syncedAt: Value(DateTime.now())))
        .then((rows) => rows > 0);
  }

  /// Get quests that need syncing (syncedAt is null or before updatedAt).
  Future<List<Quest>> getUnsyncedQuests() async {
    return (select(quests)
          ..where((q) =>
              q.syncedAt.isNull() | q.syncedAt.isSmallerThan(q.updatedAt)))
        .get();
  }
}
