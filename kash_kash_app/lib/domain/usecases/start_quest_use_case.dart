import 'package:fpdart/fpdart.dart';

import '../../core/errors/failures.dart';
import '../entities/quest_attempt.dart';
import '../repositories/attempt_repository.dart';

/// Use case for starting a new quest attempt.
///
/// Creates a new quest attempt with status inProgress.
/// Prevents double-start by checking for existing active attempts.
class StartQuestUseCase {
  final IAttemptRepository _repository;

  StartQuestUseCase(this._repository);

  /// Start a new quest attempt.
  ///
  /// Returns the created [QuestAttempt] or a [Failure] if:
  /// - User already has an active attempt
  /// - Quest doesn't exist
  /// - Storage error
  Future<Either<Failure, QuestAttempt>> call({
    required String questId,
    required String userId,
  }) async {
    final activeResult = await _repository.getActiveAttempt(userId);

    return activeResult.fold(
      Left.new,
      (existingAttempt) async {
        if (existingAttempt != null) {
          return const Left(
            ValidationFailure('Already have an active quest in progress'),
          );
        }
        return _repository.startAttempt(questId: questId, userId: userId);
      },
    );
  }
}
