// Database tests require libsqlite3.so on Linux.
// Install with: apt-get install libsqlite3-dev
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart';
import 'package:kash_kash_app/data/datasources/local/path_point_dao.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late PathPointDao pathPointDao;

  final now = DateTime.now();

  PathPoint createTestPathPoint({
    required String id,
    String attemptId = 'attempt-1',
    double latitude = 48.8566,
    double longitude = 2.3522,
    DateTime? timestamp,
    double accuracy = 5.0,
    double speed = 1.5,
    bool synced = false,
  }) {
    return PathPoint(
      id: id,
      attemptId: attemptId,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp ?? now,
      accuracy: accuracy,
      speed: speed,
      synced: synced,
    );
  }

  setUp(() {
    db = createTestDatabase();
    pathPointDao = db.pathPointDao;
  });

  tearDown(() async {
    await db.close();
  });

  group('PathPointDao', () {
    group('add and getById', () {
      test('should add new path point', () async {
        await pathPointDao.add(createTestPathPoint(id: 'point-1'));

        final point = await pathPointDao.getById('point-1');
        expect(point, isNotNull);
        expect(point!.id, 'point-1');
      });

      test('should return null when not found', () async {
        final point = await pathPointDao.getById('nonexistent');
        expect(point, isNull);
      });
    });

    group('getForAttempt', () {
      test('should return points for specific attempt', () async {
        await pathPointDao.add(createTestPathPoint(id: 'p1', attemptId: 'attempt-1'));
        await pathPointDao.add(createTestPathPoint(id: 'p2', attemptId: 'attempt-1'));
        await pathPointDao.add(createTestPathPoint(id: 'p3', attemptId: 'attempt-2'));

        final points = await pathPointDao.getForAttempt('attempt-1');

        expect(points.length, 2);
        expect(points.every((p) => p.attemptId == 'attempt-1'), true);
      });

      test('should order by timestamp ascending', () async {
        final earlier = now.subtract(const Duration(seconds: 30));
        await pathPointDao.add(createTestPathPoint(
          id: 'older',
          attemptId: 'attempt-1',
          timestamp: earlier,
        ));
        await pathPointDao.add(createTestPathPoint(
          id: 'newer',
          attemptId: 'attempt-1',
          timestamp: now,
        ));

        final points = await pathPointDao.getForAttempt('attempt-1');

        expect(points.first.id, 'older');
        expect(points.last.id, 'newer');
      });

      test('should return empty list when no points', () async {
        final points = await pathPointDao.getForAttempt('nonexistent');
        expect(points, isEmpty);
      });
    });

    group('addBatch', () {
      test('should insert multiple points', () async {
        await pathPointDao.addBatch([
          createTestPathPoint(id: 'p1'),
          createTestPathPoint(id: 'p2'),
          createTestPathPoint(id: 'p3'),
        ]);

        final all = await pathPointDao.getAll();
        expect(all.length, 3);
      });

      test('should handle empty list', () async {
        await pathPointDao.addBatch([]);

        final all = await pathPointDao.getAll();
        expect(all, isEmpty);
      });
    });

    group('upsert', () {
      test('should insert new point', () async {
        await pathPointDao.upsert(createTestPathPoint(id: 'new-point'));

        final point = await pathPointDao.getById('new-point');
        expect(point, isNotNull);
      });

      test('should update existing point', () async {
        await pathPointDao.add(createTestPathPoint(id: 'point-1', speed: 1.0));

        await pathPointDao.upsert(PathPoint(
          id: 'point-1',
          attemptId: 'attempt-1',
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: now,
          accuracy: 5.0,
          speed: 3.0,
          synced: false,
        ));

        final point = await pathPointDao.getById('point-1');
        expect(point!.speed, 3.0);
      });
    });

    group('deleteById', () {
      test('should remove point', () async {
        await pathPointDao.add(createTestPathPoint(id: 'point-1'));

        final deletedCount = await pathPointDao.deleteById('point-1');

        expect(deletedCount, 1);
        expect(await pathPointDao.getById('point-1'), isNull);
      });

      test('should return 0 when point does not exist', () async {
        final deletedCount = await pathPointDao.deleteById('nonexistent');
        expect(deletedCount, 0);
      });
    });

    group('deleteForAttempt', () {
      test('should remove all points for attempt', () async {
        await pathPointDao.add(createTestPathPoint(id: 'p1', attemptId: 'attempt-1'));
        await pathPointDao.add(createTestPathPoint(id: 'p2', attemptId: 'attempt-1'));
        await pathPointDao.add(createTestPathPoint(id: 'p3', attemptId: 'attempt-2'));

        final deletedCount = await pathPointDao.deleteForAttempt('attempt-1');

        expect(deletedCount, 2);
        final remaining = await pathPointDao.getAll();
        expect(remaining.length, 1);
        expect(remaining.first.attemptId, 'attempt-2');
      });
    });

    group('deleteAll', () {
      test('should remove all points', () async {
        await pathPointDao.add(createTestPathPoint(id: 'p1'));
        await pathPointDao.add(createTestPathPoint(id: 'p2'));

        await pathPointDao.deleteAll();

        final all = await pathPointDao.getAll();
        expect(all, isEmpty);
      });
    });

    group('countForAttempt', () {
      test('should return point count for attempt', () async {
        await pathPointDao.add(createTestPathPoint(id: 'p1', attemptId: 'attempt-1'));
        await pathPointDao.add(createTestPathPoint(id: 'p2', attemptId: 'attempt-1'));
        await pathPointDao.add(createTestPathPoint(id: 'p3', attemptId: 'attempt-2'));

        final count = await pathPointDao.countForAttempt('attempt-1');

        expect(count, 2);
      });
    });

    group('calculateTotalDistance', () {
      test('should calculate distance between points', () async {
        // Two points approximately 111 meters apart (1/1000 degree at equator)
        await pathPointDao.add(createTestPathPoint(
          id: 'p1',
          attemptId: 'attempt-1',
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: now.subtract(const Duration(seconds: 10)),
        ));
        await pathPointDao.add(createTestPathPoint(
          id: 'p2',
          attemptId: 'attempt-1',
          latitude: 48.8576, // ~111m north
          longitude: 2.3522,
          timestamp: now,
        ));

        final distance = await pathPointDao.calculateTotalDistance('attempt-1');

        // Should be approximately 111 meters
        expect(distance, greaterThan(100));
        expect(distance, lessThan(120));
      });

      test('should return 0 for single point', () async {
        await pathPointDao.add(createTestPathPoint(id: 'p1'));

        final distance = await pathPointDao.calculateTotalDistance('attempt-1');

        expect(distance, 0);
      });

      test('should return 0 for no points', () async {
        final distance = await pathPointDao.calculateTotalDistance('nonexistent');

        expect(distance, 0);
      });

      test('should sum distances for multiple points', () async {
        // Three points forming a path
        await pathPointDao.add(createTestPathPoint(
          id: 'p1',
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: now.subtract(const Duration(seconds: 20)),
        ));
        await pathPointDao.add(createTestPathPoint(
          id: 'p2',
          latitude: 48.8576, // ~111m north
          longitude: 2.3522,
          timestamp: now.subtract(const Duration(seconds: 10)),
        ));
        await pathPointDao.add(createTestPathPoint(
          id: 'p3',
          latitude: 48.8586, // ~111m north again
          longitude: 2.3522,
          timestamp: now,
        ));

        final distance = await pathPointDao.calculateTotalDistance('attempt-1');

        // Should be approximately 222 meters (111 + 111)
        expect(distance, greaterThan(200));
        expect(distance, lessThan(240));
      });
    });

    group('markSynced', () {
      test('should set synced to true', () async {
        await pathPointDao.add(createTestPathPoint(id: 'point-1', synced: false));

        final marked = await pathPointDao.markSynced('point-1');

        expect(marked, true);
        final point = await pathPointDao.getById('point-1');
        expect(point!.synced, true);
      });

      test('should return false for nonexistent point', () async {
        final marked = await pathPointDao.markSynced('nonexistent');
        expect(marked, false);
      });
    });

    group('getUnsynced', () {
      test('should return points with synced=false', () async {
        await pathPointDao.add(createTestPathPoint(id: 'unsynced-1', synced: false));
        await pathPointDao.add(createTestPathPoint(id: 'synced-1', synced: true));

        final unsynced = await pathPointDao.getUnsynced();

        expect(unsynced.length, 1);
        expect(unsynced.first.id, 'unsynced-1');
      });
    });

    group('getUnsyncedForAttempt', () {
      test('should return unsynced points for specific attempt', () async {
        await pathPointDao.add(createTestPathPoint(
          id: 'p1',
          attemptId: 'attempt-1',
          synced: false,
        ));
        await pathPointDao.add(createTestPathPoint(
          id: 'p2',
          attemptId: 'attempt-1',
          synced: true,
        ));
        await pathPointDao.add(createTestPathPoint(
          id: 'p3',
          attemptId: 'attempt-2',
          synced: false,
        ));

        final unsynced = await pathPointDao.getUnsyncedForAttempt('attempt-1');

        expect(unsynced.length, 1);
        expect(unsynced.first.id, 'p1');
      });
    });

    group('watchForAttempt', () {
      test('should emit on changes', () async {
        final emissions = <List<PathPoint>>[];
        final subscription =
            pathPointDao.watchForAttempt('attempt-1').listen(emissions.add);

        // Wait for initial emission
        await Future.delayed(const Duration(milliseconds: 50));
        expect(emissions.isNotEmpty, true);
        expect(emissions.last, isEmpty);

        // Add a point
        await pathPointDao.add(createTestPathPoint(id: 'p1', attemptId: 'attempt-1'));
        await Future.delayed(const Duration(milliseconds: 50));

        expect(emissions.last.length, 1);

        await subscription.cancel();
      });
    });
  });
}
