import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/path_point.dart';
import '../entities/quest_attempt.dart';

/// Quest attempt repository interface
abstract class IAttemptRepository {
  /// Start a new quest attempt
  Future<Either<Failure, QuestAttempt>> startAttempt({
    required String questId,
    required String userId,
  });

  /// Complete an attempt (player won)
  Future<Either<Failure, QuestAttempt>> completeAttempt(String attemptId);

  /// Abandon an attempt (player gave up)
  Future<Either<Failure, QuestAttempt>> abandonAttempt(String attemptId);

  /// Get a single attempt by ID
  Future<Either<Failure, QuestAttempt>> getAttemptById(String id);

  /// Get the currently active attempt for a user
  Future<Either<Failure, QuestAttempt?>> getActiveAttempt(String userId);

  /// Get all attempts for a user (history)
  Future<Either<Failure, List<QuestAttempt>>> getUserAttempts(String userId);

  /// Get all attempts for a quest
  Future<Either<Failure, List<QuestAttempt>>> getQuestAttempts(String questId);

  /// Add a path point to an attempt
  Future<Either<Failure, Unit>> addPathPoint(PathPoint point);

  /// Get path points for an attempt
  Future<Either<Failure, List<PathPoint>>> getPathPoints(String attemptId);

  /// Get unsynced attempts
  Future<Either<Failure, List<QuestAttempt>>> getUnsyncedAttempts();

  /// Mark attempt as synced
  Future<Either<Failure, Unit>> markSynced(String attemptId);
}
