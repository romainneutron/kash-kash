// Database tests require libsqlite3.so on Linux.
// Install with: apt-get install libsqlite3-dev
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/data/datasources/local/attempt_dao.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late AttemptDao attemptDao;

  final now = DateTime.now();

  QuestAttempt createTestAttempt({
    required String id,
    String questId = 'quest-1',
    String userId = 'user-1',
    AttemptStatus status = AttemptStatus.inProgress,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? abandonedAt,
    int? durationSeconds,
    double? distanceWalked,
    bool synced = false,
  }) {
    return QuestAttempt(
      id: id,
      questId: questId,
      userId: userId,
      startedAt: startedAt ?? now,
      completedAt: completedAt,
      abandonedAt: abandonedAt,
      status: status,
      durationSeconds: durationSeconds,
      distanceWalked: distanceWalked,
      synced: synced,
    );
  }

  setUp(() {
    db = createTestDatabase();
    attemptDao = db.attemptDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('AttemptDao', () {
    group('insert and getById', () {
      test('should insert new attempt', () async {
        await attemptDao.insert(createTestAttempt(id: 'attempt-1'));

        final attempt = await attemptDao.getById('attempt-1');
        expect(attempt, isNotNull);
        expect(attempt!.id, 'attempt-1');
      });

      test('should return null when not found', () async {
        final attempt = await attemptDao.getById('nonexistent');
        expect(attempt, isNull);
      });
    });

    group('getActiveForUser', () {
      test('should return in-progress attempt', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'active-1',
          userId: 'user-1',
          status: AttemptStatus.inProgress,
        ));

        final active = await attemptDao.getActiveForUser('user-1');

        expect(active, isNotNull);
        expect(active!.id, 'active-1');
        expect(active.status, AttemptStatus.inProgress);
      });

      test('should return null when no active attempt', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'completed-1',
          userId: 'user-1',
          status: AttemptStatus.completed,
        ));

        final active = await attemptDao.getActiveForUser('user-1');

        expect(active, isNull);
      });

      test('should return null for different user', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'active-1',
          userId: 'user-1',
          status: AttemptStatus.inProgress,
        ));

        final active = await attemptDao.getActiveForUser('user-2');

        expect(active, isNull);
      });
    });

    group('getHistoryForUser', () {
      test('should return completed and abandoned attempts', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'completed-1',
          userId: 'user-1',
          status: AttemptStatus.completed,
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'abandoned-1',
          userId: 'user-1',
          status: AttemptStatus.abandoned,
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'active-1',
          userId: 'user-1',
          status: AttemptStatus.inProgress,
        ));

        final history = await attemptDao.getHistoryForUser('user-1');

        expect(history.length, 2);
        expect(history.every((a) => a.status != AttemptStatus.inProgress), true);
      });

      test('should exclude in-progress attempts', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'active-1',
          userId: 'user-1',
          status: AttemptStatus.inProgress,
        ));

        final history = await attemptDao.getHistoryForUser('user-1');

        expect(history, isEmpty);
      });

      test('should order by startedAt descending', () async {
        final earlier = now.subtract(const Duration(hours: 1));
        await attemptDao.insert(createTestAttempt(
          id: 'older',
          userId: 'user-1',
          status: AttemptStatus.completed,
          startedAt: earlier,
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'newer',
          userId: 'user-1',
          status: AttemptStatus.completed,
          startedAt: now,
        ));

        final history = await attemptDao.getHistoryForUser('user-1');

        expect(history.first.id, 'newer');
        expect(history.last.id, 'older');
      });
    });

    group('getForQuest', () {
      test('should return all attempts for a quest', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'attempt-1',
          questId: 'quest-1',
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'attempt-2',
          questId: 'quest-1',
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'attempt-3',
          questId: 'quest-2',
        ));

        final attempts = await attemptDao.getForQuest('quest-1');

        expect(attempts.length, 2);
        expect(attempts.every((a) => a.questId == 'quest-1'), true);
      });
    });

    group('updateAttempt', () {
      test('should update existing attempt', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'attempt-1',
          status: AttemptStatus.inProgress,
        ));

        final updated = await attemptDao.updateAttempt(QuestAttempt(
          id: 'attempt-1',
          questId: 'quest-1',
          userId: 'user-1',
          startedAt: now,
          status: AttemptStatus.completed,
          completedAt: now,
          durationSeconds: 120,
          distanceWalked: 250.5,
          synced: false,
        ));

        expect(updated, true);
        final attempt = await attemptDao.getById('attempt-1');
        expect(attempt!.status, AttemptStatus.completed);
        expect(attempt.durationSeconds, 120);
        expect(attempt.distanceWalked, 250.5);
      });

      test('should return false when attempt does not exist', () async {
        final updated = await attemptDao.updateAttempt(createTestAttempt(
          id: 'nonexistent',
        ));

        expect(updated, false);
      });
    });

    group('upsert', () {
      test('should insert new attempt', () async {
        await attemptDao.upsert(createTestAttempt(id: 'new-attempt'));

        final attempt = await attemptDao.getById('new-attempt');
        expect(attempt, isNotNull);
      });

      test('should update existing attempt', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'attempt-1',
          status: AttemptStatus.inProgress,
        ));

        await attemptDao.upsert(QuestAttempt(
          id: 'attempt-1',
          questId: 'quest-1',
          userId: 'user-1',
          startedAt: now,
          status: AttemptStatus.completed,
          synced: false,
        ));

        final attempt = await attemptDao.getById('attempt-1');
        expect(attempt!.status, AttemptStatus.completed);
      });
    });

    group('deleteById', () {
      test('should remove attempt', () async {
        await attemptDao.insert(createTestAttempt(id: 'attempt-1'));

        final deletedCount = await attemptDao.deleteById('attempt-1');

        expect(deletedCount, 1);
        expect(await attemptDao.getById('attempt-1'), isNull);
      });

      test('should return 0 when attempt does not exist', () async {
        final deletedCount = await attemptDao.deleteById('nonexistent');
        expect(deletedCount, 0);
      });
    });

    group('deleteAll', () {
      test('should remove all attempts', () async {
        await attemptDao.insert(createTestAttempt(id: 'attempt-1'));
        await attemptDao.insert(createTestAttempt(id: 'attempt-2'));

        await attemptDao.deleteAll();

        final all = await attemptDao.getAll();
        expect(all, isEmpty);
      });
    });

    group('count', () {
      test('should return total attempt count', () async {
        await attemptDao.insert(createTestAttempt(id: 'attempt-1'));
        await attemptDao.insert(createTestAttempt(id: 'attempt-2'));

        final count = await attemptDao.count();

        expect(count, 2);
      });
    });

    group('countCompletedForUser', () {
      test('should return only completed count for user', () async {
        await attemptDao.insert(createTestAttempt(
          id: 'completed-1',
          userId: 'user-1',
          status: AttemptStatus.completed,
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'completed-2',
          userId: 'user-1',
          status: AttemptStatus.completed,
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'abandoned-1',
          userId: 'user-1',
          status: AttemptStatus.abandoned,
        ));
        await attemptDao.insert(createTestAttempt(
          id: 'other-user',
          userId: 'user-2',
          status: AttemptStatus.completed,
        ));

        final count = await attemptDao.countCompletedForUser('user-1');

        expect(count, 2);
      });
    });

    group('markSynced', () {
      test('should set synced to true', () async {
        await attemptDao.insert(createTestAttempt(id: 'attempt-1', synced: false));

        final marked = await attemptDao.markSynced('attempt-1');

        expect(marked, true);
        final attempt = await attemptDao.getById('attempt-1');
        expect(attempt!.synced, true);
      });

      test('should return false for nonexistent attempt', () async {
        final marked = await attemptDao.markSynced('nonexistent');
        expect(marked, false);
      });
    });

    group('getUnsynced', () {
      test('should return attempts with synced=false', () async {
        await attemptDao.insert(createTestAttempt(id: 'unsynced-1', synced: false));
        await attemptDao.insert(createTestAttempt(id: 'synced-1', synced: true));

        final unsynced = await attemptDao.getUnsynced();

        expect(unsynced.length, 1);
        expect(unsynced.first.id, 'unsynced-1');
      });
    });

    group('watchHistoryForUser', () {
      test('should emit on changes', () async {
        final emissions = <List<QuestAttempt>>[];
        final subscription =
            attemptDao.watchHistoryForUser('user-1').listen(emissions.add);

        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 50));
        expect(emissions.isNotEmpty, true);
        expect(emissions.last, isEmpty);

        // Add a completed attempt
        await attemptDao.insert(createTestAttempt(
          id: 'completed-1',
          userId: 'user-1',
          status: AttemptStatus.completed,
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emissions.last.length, 1);

        await subscription.cancel();
      });
    });

    group('watchActiveForUser', () {
      test('should emit on active attempt changes', () async {
        final emissions = <QuestAttempt?>[];
        final subscription =
            attemptDao.watchActiveForUser('user-1').listen(emissions.add);

        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 50));
        expect(emissions.isNotEmpty, true);
        expect(emissions.last, isNull);

        // Add an active attempt
        await attemptDao.insert(createTestAttempt(
          id: 'active-1',
          userId: 'user-1',
          status: AttemptStatus.inProgress,
        ));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emissions.last, isNotNull);
        expect(emissions.last!.id, 'active-1');

        await subscription.cancel();
      });
    });
  });
}
