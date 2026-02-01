import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/data/datasources/local/attempt_dao.dart';
import 'package:kash_kash_app/data/datasources/local/database.dart' as db;
import 'package:kash_kash_app/data/datasources/local/path_point_dao.dart';
import 'package:kash_kash_app/data/repositories/attempt_repository_impl.dart';
import 'package:kash_kash_app/domain/entities/path_point.dart' as domain;
import 'package:kash_kash_app/domain/entities/quest_attempt.dart' as domain;
import 'package:mocktail/mocktail.dart';

class MockAttemptDao extends Mock implements AttemptDao {}

class MockPathPointDao extends Mock implements PathPointDao {}

void main() {
  late AttemptRepositoryImpl repository;
  late MockAttemptDao mockAttemptDao;
  late MockPathPointDao mockPathPointDao;

  final now = DateTime.now();

  final testDbAttempt = db.QuestAttempt(
    id: 'attempt-1',
    questId: 'quest-1',
    userId: 'user-1',
    startedAt: now,
    completedAt: null,
    abandonedAt: null,
    status: db.AttemptStatus.inProgress,
    durationSeconds: null,
    distanceWalked: null,
    synced: false,
  );

  final testDbAttemptCompleted = db.QuestAttempt(
    id: 'attempt-2',
    questId: 'quest-1',
    userId: 'user-1',
    startedAt: now.subtract(const Duration(minutes: 30)),
    completedAt: now,
    abandonedAt: null,
    status: db.AttemptStatus.completed,
    durationSeconds: 1800,
    distanceWalked: 500.0,
    synced: false,
  );

  final testDbAttemptAbandoned = db.QuestAttempt(
    id: 'attempt-3',
    questId: 'quest-2',
    userId: 'user-1',
    startedAt: now.subtract(const Duration(minutes: 15)),
    completedAt: null,
    abandonedAt: now,
    status: db.AttemptStatus.abandoned,
    durationSeconds: 900,
    distanceWalked: 200.0,
    synced: false,
  );

  final testDbPathPoint = db.PathPoint(
    id: 'point-1',
    attemptId: 'attempt-1',
    latitude: 48.8566,
    longitude: 2.3522,
    timestamp: now,
    accuracy: 10.0,
    speed: 1.5,
    synced: false,
  );

  setUp(() {
    mockAttemptDao = MockAttemptDao();
    mockPathPointDao = MockPathPointDao();

    repository = AttemptRepositoryImpl(
      attemptDao: mockAttemptDao,
      pathPointDao: mockPathPointDao,
    );
  });

  setUpAll(() {
    registerFallbackValue(testDbAttempt);
    registerFallbackValue(testDbPathPoint);
    registerFallbackValue(domain.PathPoint(
      id: 'point-1',
      attemptId: 'attempt-1',
      latitude: 48.8566,
      longitude: 2.3522,
      timestamp: now,
      accuracy: 10.0,
      speed: 1.5,
    ));
  });

  group('AttemptRepositoryImpl', () {
    group('startAttempt', () {
      test('should create new attempt and return it', () async {
        when(() => mockAttemptDao.insert(any())).thenAnswer((_) async {});

        final result = await repository.startAttempt(
          questId: 'quest-1',
          userId: 'user-1',
        );

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempt) {
            expect(attempt.questId, 'quest-1');
            expect(attempt.userId, 'user-1');
            expect(attempt.status, domain.AttemptStatus.inProgress);
            expect(attempt.synced, false);
          },
        );
        verify(() => mockAttemptDao.insert(any())).called(1);
      });

      test('should return CacheFailure when dao throws', () async {
        when(() => mockAttemptDao.insert(any()))
            .thenThrow(Exception('Database error'));

        final result = await repository.startAttempt(
          questId: 'quest-1',
          userId: 'user-1',
        );

        expect(result.isLeft(), true);
        result.fold(
          (failure) => expect(failure, isA<CacheFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });

    group('completeAttempt', () {
      test('should update attempt status to completed', () async {
        when(() => mockAttemptDao.getById('attempt-1'))
            .thenAnswer((_) async => testDbAttempt);
        when(() => mockPathPointDao.calculateTotalDistance('attempt-1'))
            .thenAnswer((_) async => 500.0);
        when(() => mockAttemptDao.updateAttempt(any()))
            .thenAnswer((_) async => true);

        final result = await repository.completeAttempt('attempt-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempt) {
            expect(attempt.status, domain.AttemptStatus.completed);
            expect(attempt.completedAt, isNotNull);
            expect(attempt.distanceWalked, 500.0);
          },
        );
      });

      test('should return CacheFailure when attempt not found', () async {
        when(() => mockAttemptDao.getById('attempt-1'))
            .thenAnswer((_) async => null);

        final result = await repository.completeAttempt('attempt-1');

        expect(result.isLeft(), true);
        result.fold(
          (failure) {
            expect(failure, isA<CacheFailure>());
            expect(failure.message, 'Attempt not found');
          },
          (_) => fail('Expected Left'),
        );
      });
    });

    group('abandonAttempt', () {
      test('should update attempt status to abandoned', () async {
        when(() => mockAttemptDao.getById('attempt-1'))
            .thenAnswer((_) async => testDbAttempt);
        when(() => mockPathPointDao.calculateTotalDistance('attempt-1'))
            .thenAnswer((_) async => 200.0);
        when(() => mockAttemptDao.updateAttempt(any()))
            .thenAnswer((_) async => true);

        final result = await repository.abandonAttempt('attempt-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempt) {
            expect(attempt.status, domain.AttemptStatus.abandoned);
            expect(attempt.abandonedAt, isNotNull);
          },
        );
      });
    });

    group('getUserAttempts (history)', () {
      test('should return all finished attempts for user sorted by date', () async {
        when(() => mockAttemptDao.getHistoryForUser('user-1'))
            .thenAnswer((_) async => [testDbAttemptCompleted, testDbAttemptAbandoned]);

        final result = await repository.getUserAttempts('user-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempts) {
            expect(attempts.length, 2);
            expect(attempts[0].status, domain.AttemptStatus.completed);
            expect(attempts[1].status, domain.AttemptStatus.abandoned);
          },
        );
      });

      test('should return empty list when no history', () async {
        when(() => mockAttemptDao.getHistoryForUser('user-1'))
            .thenAnswer((_) async => []);

        final result = await repository.getUserAttempts('user-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempts) {
            expect(attempts.isEmpty, true);
          },
        );
      });

      test('should not include in-progress attempts', () async {
        when(() => mockAttemptDao.getHistoryForUser('user-1'))
            .thenAnswer((_) async => [testDbAttemptCompleted]);

        final result = await repository.getUserAttempts('user-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempts) {
            expect(attempts.length, 1);
            expect(attempts.every((a) => !a.isInProgress), true);
          },
        );
      });
    });

    group('getUnsyncedAttempts', () {
      test('should return only unsynced attempts', () async {
        when(() => mockAttemptDao.getUnsynced())
            .thenAnswer((_) async => [testDbAttemptCompleted, testDbAttemptAbandoned]);

        final result = await repository.getUnsyncedAttempts();

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempts) {
            expect(attempts.length, 2);
            expect(attempts.every((a) => !a.synced), true);
          },
        );
      });
    });

    group('markSynced', () {
      test('should mark attempt as synced', () async {
        when(() => mockAttemptDao.markSynced('attempt-1'))
            .thenAnswer((_) async => true);

        final result = await repository.markSynced('attempt-1');

        expect(result.isRight(), true);
        verify(() => mockAttemptDao.markSynced('attempt-1')).called(1);
      });
    });

    group('getActiveAttempt', () {
      test('should return active attempt for user', () async {
        when(() => mockAttemptDao.getActiveForUser('user-1'))
            .thenAnswer((_) async => testDbAttempt);

        final result = await repository.getActiveAttempt('user-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempt) {
            expect(attempt, isNotNull);
            expect(attempt!.status, domain.AttemptStatus.inProgress);
          },
        );
      });

      test('should return null when no active attempt', () async {
        when(() => mockAttemptDao.getActiveForUser('user-1'))
            .thenAnswer((_) async => null);

        final result = await repository.getActiveAttempt('user-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (attempt) {
            expect(attempt, isNull);
          },
        );
      });
    });

    group('addPathPoint', () {
      test('should add path point to attempt', () async {
        when(() => mockPathPointDao.add(any())).thenAnswer((_) async {});

        final pathPoint = domain.PathPoint(
          id: 'point-1',
          attemptId: 'attempt-1',
          latitude: 48.8566,
          longitude: 2.3522,
          timestamp: now,
          accuracy: 10.0,
          speed: 1.5,
        );

        final result = await repository.addPathPoint(pathPoint);

        expect(result.isRight(), true);
        expect(result.getRight().toNullable(), unit);
        verify(() => mockPathPointDao.add(any())).called(1);
      });
    });

    group('getPathPoints', () {
      test('should return path points for attempt', () async {
        when(() => mockPathPointDao.getForAttempt('attempt-1'))
            .thenAnswer((_) async => [testDbPathPoint]);

        final result = await repository.getPathPoints('attempt-1');

        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Expected Right, got Left: $failure'),
          (points) {
            expect(points.length, 1);
            expect(points.first.latitude, 48.8566);
          },
        );
      });
    });
  });
}
