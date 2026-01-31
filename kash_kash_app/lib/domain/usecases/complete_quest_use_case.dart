import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/quest_attempt.dart';
import '../repositories/attempt_repository.dart';

/// Use case for completing a quest attempt (player won).
///
/// Updates the attempt status to completed, records completion time,
/// and calculates duration and distance walked.
class CompleteQuestUseCase {
  final IAttemptRepository _repository;

  CompleteQuestUseCase(this._repository);

  /// Complete the quest attempt.
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
        return _repository.completeAttempt(attemptId);
      },
    );
  }
}
