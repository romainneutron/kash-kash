// Database tests require libsqlite3.so on Linux.
// CI installs this via: apt-get install libsqlite3-dev
// Locally: apt-get install libsqlite3-dev OR run with --exclude-tags=sqlite
@TestOn('vm')
@Tags(['sqlite'])

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('AppDatabase', () {
    group('initialization', () {
      test('should open without errors', () {
        expect(db, isNotNull);
        expect(db.schemaVersion, 1);
      });

      test('should have all required tables', () async {
        // Verify we can select from all tables (they exist)
        await db.select(db.users).get();
        await db.select(db.quests).get();
        await db.select(db.questAttempts).get();
        await db.select(db.pathPoints).get();
        await db.select(db.syncQueue).get();

        // If we get here, all tables exist
        expect(true, isTrue);
      });
    });

    group('Users table', () {
      test('should insert and retrieve user', () async {
        final user = UsersCompanion.insert(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.into(db.users).insert(user);

        final users = await db.select(db.users).get();
        expect(users.length, 1);
        expect(users.first.email, 'test@example.com');
        expect(users.first.displayName, 'Test User');
        expect(users.first.role, UserRole.user);
      });

      test('should update user', () async {
        await db.into(db.users).insert(UsersCompanion.insert(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await (db.update(db.users)..where((u) => u.id.equals('user-1')))
          .write(const UsersCompanion(displayName: Value('Updated User')));

        final user = await (db.select(db.users)..where((u) => u.id.equals('user-1')))
          .getSingle();
        expect(user.displayName, 'Updated User');
      });

      test('should delete user', () async {
        await db.into(db.users).insert(UsersCompanion.insert(
          id: 'user-1',
          email: 'test@example.com',
          displayName: 'Test User',
          role: UserRole.user,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await (db.delete(db.users)..where((u) => u.id.equals('user-1'))).go();

        final users = await db.select(db.users).get();
        expect(users, isEmpty);
      });
    });

    group('Quests table', () {
      test('should insert and retrieve quest', () async {
        final quest = QuestsCompanion.insert(
          id: 'quest-1',
          title: 'Test Quest',
          latitude: 48.8566,
          longitude: 2.3522,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await db.into(db.quests).insert(quest);

        final quests = await db.select(db.quests).get();
        expect(quests.length, 1);
        expect(quests.first.title, 'Test Quest');
        expect(quests.first.latitude, 48.8566);
        expect(quests.first.longitude, 2.3522);
        expect(quests.first.radiusMeters, 3.0); // Default value
        expect(quests.first.published, isFalse); // Default value
      });

      test('should store and retrieve enum values', () async {
        await db.into(db.quests).insert(QuestsCompanion.insert(
          id: 'quest-1',
          title: 'Test Quest',
          latitude: 0,
          longitude: 0,
          createdBy: 'user-1',
          difficulty: Value(QuestDifficulty.hard),
          locationType: Value(LocationType.forest),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final quest = await (db.select(db.quests)..where((q) => q.id.equals('quest-1')))
          .getSingle();
        expect(quest.difficulty, QuestDifficulty.hard);
        expect(quest.locationType, LocationType.forest);
      });

      test('should filter published quests', () async {
        await db.into(db.quests).insert(QuestsCompanion.insert(
          id: 'published-1',
          title: 'Published Quest',
          latitude: 0,
          longitude: 0,
          createdBy: 'user-1',
          published: const Value(true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        await db.into(db.quests).insert(QuestsCompanion.insert(
          id: 'unpublished-1',
          title: 'Unpublished Quest',
          latitude: 0,
          longitude: 0,
          createdBy: 'user-1',
          published: const Value(false),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));

        final published = await (db.select(db.quests)
          ..where((q) => q.published.equals(true))).get();
        expect(published.length, 1);
        expect(published.first.id, 'published-1');
      });
    });

    group('QuestAttempts table', () {
      test('should insert and retrieve attempt', () async {
        await db.into(db.questAttempts).insert(QuestAttemptsCompanion.insert(
          id: 'attempt-1',
          questId: 'quest-1',
          userId: 'user-1',
          startedAt: DateTime.now(),
          status: AttemptStatus.inProgress,
        ));

        final attempts = await db.select(db.questAttempts).get();
        expect(attempts.length, 1);
        expect(attempts.first.status, AttemptStatus.inProgress);
        expect(attempts.first.synced, isFalse); // Default value
      });

      test('should filter by status', () async {
        await db.into(db.questAttempts).insert(QuestAttemptsCompanion.insert(
          id: 'attempt-1',
          questId: 'quest-1',
          userId: 'user-1',
          startedAt: DateTime.now(),
          status: AttemptStatus.inProgress,
        ));

        await db.into(db.questAttempts).insert(QuestAttemptsCompanion.insert(
          id: 'attempt-2',
          questId: 'quest-2',
          userId: 'user-1',
          startedAt: DateTime.now(),
          status: AttemptStatus.completed,
        ));

        final inProgress = await (db.select(db.questAttempts)
          ..where((a) => a.status.equals(AttemptStatus.inProgress.index))).get();
        expect(inProgress.length, 1);
        expect(inProgress.first.id, 'attempt-1');
      });
    });

    group('PathPoints table', () {
      test('should insert and retrieve path point', () async {
        await db.into(db.pathPoints).insert(PathPointsCompanion.insert(
          id: 'point-1',
          attemptId: 'attempt-1',
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          speed: 1.5,
        ));

        final points = await db.select(db.pathPoints).get();
        expect(points.length, 1);
        expect(points.first.latitude, 48.8566);
        expect(points.first.accuracy, 5.0);
        expect(points.first.speed, 1.5);
      });

      test('should get points for specific attempt', () async {
        await db.into(db.pathPoints).insert(PathPointsCompanion.insert(
          id: 'point-1',
          attemptId: 'attempt-1',
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          speed: 1.0,
        ));

        await db.into(db.pathPoints).insert(PathPointsCompanion.insert(
          id: 'point-2',
          attemptId: 'attempt-2',
          latitude: 0,
          longitude: 0,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          speed: 1.0,
        ));

        final attempt1Points = await (db.select(db.pathPoints)
          ..where((p) => p.attemptId.equals('attempt-1'))).get();
        expect(attempt1Points.length, 1);
        expect(attempt1Points.first.id, 'point-1');
      });
    });

    group('SyncQueue table', () {
      test('should insert and retrieve sync item', () async {
        await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
          targetTable: 'quests',
          recordId: 'quest-1',
          operation: 'INSERT',
          payload: '{"title": "Test"}',
          createdAt: DateTime.now(),
        ));

        final items = await db.select(db.syncQueue).get();
        expect(items.length, 1);
        expect(items.first.targetTable, 'quests');
        expect(items.first.operation, 'INSERT');
        expect(items.first.processed, isFalse); // Default value
      });

      test('should mark item as processed', () async {
        await db.into(db.syncQueue).insert(SyncQueueCompanion.insert(
          targetTable: 'quests',
          recordId: 'quest-1',
          operation: 'INSERT',
          payload: '{}',
          createdAt: DateTime.now(),
        ));

        await (db.update(db.syncQueue)..where((s) => s.recordId.equals('quest-1')))
          .write(const SyncQueueCompanion(processed: Value(true)));

        final item = await (db.select(db.syncQueue)
          ..where((s) => s.recordId.equals('quest-1'))).getSingle();
        expect(item.processed, isTrue);
      });
    });
  });
}
