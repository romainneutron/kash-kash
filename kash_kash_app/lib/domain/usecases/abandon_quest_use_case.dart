import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/quest_attempt.dart';
import '../repositories/attempt_repository.dart';

/// Use case for abandoning a quest attempt (player gave up).
///
/// Updates the attempt status to abandoned and records abandonment time.
class AbandonQuestUseCase {
  final IAttemptRepository _repository;

  AbandonQuestUseCase(this._repository);

  /// Abandon the quest attempt.
  ///
  /// Returns the updated [QuestAttempt] or a [Failure] if:
  /// - Attempt not found
  /// - Attempt is not in progress
  /// - Storage error
  Future<Either<Failure, QuestAttempt>> call(String attemptId) async {
    final attemptResult = await _repository.getAttemptById(attemptId);

    return attemptResult.fold(
      Left.new,
      (attempt) async {
        if (!attempt.isInProgress) {
          return const Left(ValidationFailure('Attempt is not in progress'));
        }
        return _repository.abandonAttempt(attemptId);
      },
    );
  }
}
