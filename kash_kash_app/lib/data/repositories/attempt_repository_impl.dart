import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/failures.dart';
import '../../domain/entities/path_point.dart' as domain;
import '../../domain/entities/quest_attempt.dart' as domain;
import '../../domain/repositories/attempt_repository.dart';
import '../datasources/local/attempt_dao.dart';
import '../datasources/local/database.dart';
import '../datasources/local/path_point_dao.dart';

/// Local-first quest attempt repository implementation.
///
/// Stores attempt data locally and tracks path points during gameplay.
/// Remote sync can be added in future sprints.
class AttemptRepositoryImpl implements IAttemptRepository {
  final AttemptDao _attemptDao;
  final PathPointDao _pathPointDao;
  final Uuid _uuid;

  AttemptRepositoryImpl({
    required AttemptDao attemptDao,
    required PathPointDao pathPointDao,
    Uuid? uuid,
  })  : _attemptDao = attemptDao,
        _pathPointDao = pathPointDao,
        _uuid = uuid ?? const Uuid();

  @override
  Future<Either<Failure, domain.QuestAttempt>> startAttempt({
    required String questId,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      final attempt = QuestAttempt(
        id: _uuid.v4(),
        questId: questId,
        userId: userId,
        startedAt: now,
        status: AttemptStatus.inProgress,
        synced: false,
      );

      await _attemptDao.insert(attempt);

      return Right(_toDomain(attempt));
    } catch (e) {
      return Left(CacheFailure('Failed to start attempt: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.QuestAttempt>> completeAttempt(
      String attemptId) async {
    return _finishAttempt(
      attemptId: attemptId,
      status: AttemptStatus.completed,
      errorPrefix: 'Failed to complete attempt',
    );
  }

  @override
  Future<Either<Failure, domain.QuestAttempt>> abandonAttempt(
      String attemptId) async {
    return _finishAttempt(
      attemptId: attemptId,
      status: AttemptStatus.abandoned,
      errorPrefix: 'Failed to abandon attempt',
    );
  }

  /// Shared logic for completing or abandoning an attempt.
  Future<Either<Failure, domain.QuestAttempt>> _finishAttempt({
    required String attemptId,
    required AttemptStatus status,
    required String errorPrefix,
  }) async {
    try {
      final existing = await _attemptDao.getById(attemptId);
      if (existing == null) {
        return const Left(CacheFailure('Attempt not found'));
      }

      final now = DateTime.now();
      final duration = now.difference(existing.startedAt).inSeconds;
      final distance = await _pathPointDao.calculateTotalDistance(attemptId);

      final updated = QuestAttempt(
        id: existing.id,
        questId: existing.questId,
        userId: existing.userId,
        startedAt: existing.startedAt,
        completedAt: status == AttemptStatus.completed ? now : null,
        abandonedAt: status == AttemptStatus.abandoned ? now : null,
        status: status,
        durationSeconds: duration,
        distanceWalked: distance,
        synced: false,
      );

      await _attemptDao.updateAttempt(updated);

      return Right(_toDomain(updated));
    } catch (e) {
      return Left(CacheFailure('$errorPrefix: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.QuestAttempt>> getAttemptById(String id) async {
    try {
      final attempt = await _attemptDao.getById(id);
      if (attempt == null) {
        return const Left(CacheFailure('Attempt not found'));
      }
      return Right(_toDomain(attempt));
    } catch (e) {
      return Left(CacheFailure('Failed to get attempt: $e'));
    }
  }

  @override
  Future<Either<Failure, domain.QuestAttempt?>> getActiveAttempt(
      String userId) async {
    try {
      final attempt = await _attemptDao.getActiveForUser(userId);
      return Right(attempt == null ? null : _toDomain(attempt));
    } catch (e) {
      return Left(CacheFailure('Failed to get active attempt: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.QuestAttempt>>> getUserAttempts(
      String userId) async {
    try {
      final attempts = await _attemptDao.getHistoryForUser(userId);
      return Right(attempts.map(_toDomain).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get user attempts: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.QuestAttempt>>> getQuestAttempts(
      String questId) async {
    try {
      final attempts = await _attemptDao.getForQuest(questId);
      return Right(attempts.map(_toDomain).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get quest attempts: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> addPathPoint(domain.PathPoint point) async {
    try {
      final dbPoint = PathPoint(
        id: point.id,
        attemptId: point.attemptId,
        latitude: point.latitude,
        longitude: point.longitude,
        timestamp: point.timestamp,
        accuracy: point.accuracy,
        speed: point.speed,
        synced: point.synced,
      );
      await _pathPointDao.add(dbPoint);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to add path point: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.PathPoint>>> getPathPoints(
      String attemptId) async {
    try {
      final points = await _pathPointDao.getForAttempt(attemptId);
      return Right(points.map(_pathPointToDomain).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get path points: $e'));
    }
  }

  @override
  Future<Either<Failure, List<domain.QuestAttempt>>> getUnsyncedAttempts() async {
    try {
      final attempts = await _attemptDao.getUnsynced();
      return Right(attempts.map(_toDomain).toList());
    } catch (e) {
      return Left(CacheFailure('Failed to get unsynced attempts: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> markSynced(String attemptId) async {
    try {
      await _attemptDao.markSynced(attemptId);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to mark attempt synced: $e'));
    }
  }

  domain.QuestAttempt _toDomain(QuestAttempt db) {
    return domain.QuestAttempt(
      id: db.id,
      questId: db.questId,
      userId: db.userId,
      startedAt: db.startedAt,
      completedAt: db.completedAt,
      abandonedAt: db.abandonedAt,
      status: _statusToDomain(db.status),
      durationSeconds: db.durationSeconds,
      distanceWalked: db.distanceWalked,
      synced: db.synced,
    );
  }

  domain.AttemptStatus _statusToDomain(AttemptStatus db) {
    return switch (db) {
      AttemptStatus.inProgress => domain.AttemptStatus.inProgress,
      AttemptStatus.completed => domain.AttemptStatus.completed,
      AttemptStatus.abandoned => domain.AttemptStatus.abandoned,
    };
  }

  domain.PathPoint _pathPointToDomain(PathPoint db) {
    return domain.PathPoint(
      id: db.id,
      attemptId: db.attemptId,
      latitude: db.latitude,
      longitude: db.longitude,
      timestamp: db.timestamp,
      accuracy: db.accuracy,
      speed: db.speed,
      synced: db.synced,
    );
  }
}
