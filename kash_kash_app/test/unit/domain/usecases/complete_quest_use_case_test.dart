import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/domain/entities/quest_attempt.dart';
import 'package:kash_kash_app/domain/repositories/attempt_repository.dart';
import 'package:kash_kash_app/domain/usecases/complete_quest_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAttemptRepository extends Mock implements IAttemptRepository {}

void main() {
  late MockAttemptRepository mockRepository;
  late CompleteQuestUseCase useCase;

  final now = DateTime.now();

  QuestAttempt createTestAttempt({
    required String id,
    AttemptStatus status = AttemptStatus.inProgress,
  }) {
    return QuestAttempt(
      id: id,
      questId: 'quest-1',
      userId: 'user-1',
      startedAt: now,
      status: status,
    );
  }

  setUp(() {
    mockRepository = MockAttemptRepository();
    useCase = CompleteQuestUseCase(mockRepository);
  });

  group('CompleteQuestUseCase', () {
    test('should complete attempt when in progress', () async {
      const attemptId = 'attempt-1';
      final inProgressAttempt = createTestAttempt(
        id: attemptId,
        status: AttemptStatus.inProgress,
      );
      final completedAttempt = createTestAttempt(
        id: attemptId,
        status: AttemptStatus.completed,
      );

      when(() => mockRepository.getAttemptById(attemptId))
          .thenAnswer((_) async => Right(inProgressAttempt));

      when(() => mockRepository.completeAttempt(attemptId))
          .thenAnswer((_) async => Right(completedAttempt));

      final result = await useCase(attemptId);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (attempt) {
          expect(attempt.id, attemptId);
          expect(attempt.status, AttemptStatus.completed);
        },
      );

      verify(() => mockRepository.getAttemptById(attemptId)).called(1);
      verify(() => mockRepository.completeAttempt(attemptId)).called(1);
    });

    test('should return failure when attempt is already completed', () async {
      const attemptId = 'attempt-1';
      final completedAttempt = createTestAttempt(
        id: attemptId,
        status: AttemptStatus.completed,
      );

      when(() => mockRepository.getAttemptById(attemptId))
          .thenAnswer((_) async => Right(completedAttempt));

      final result = await useCase(attemptId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('not in progress'));
        },
        (attempt) => fail('Expected Left but got Right'),
      );

      verifyNever(() => mockRepository.completeAttempt(any()));
    });

    test('should return failure when attempt is abandoned', () async {
      const attemptId = 'attempt-1';
      final abandonedAttempt = createTestAttempt(
        id: attemptId,
        status: AttemptStatus.abandoned,
      );

      when(() => mockRepository.getAttemptById(attemptId))
          .thenAnswer((_) async => Right(abandonedAttempt));

      final result = await useCase(attemptId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (attempt) => fail('Expected Left but got Right'),
      );

      verifyNever(() => mockRepository.completeAttempt(any()));
    });

    test('should return failure when attempt not found', () async {
      const attemptId = 'nonexistent';

      when(() => mockRepository.getAttemptById(attemptId))
          .thenAnswer((_) async => const Left(CacheFailure('Not found')));

      final result = await useCase(attemptId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (attempt) => fail('Expected Left but got Right'),
      );
    });

    test('should return failure when completeAttempt fails', () async {
      const attemptId = 'attempt-1';
      final inProgressAttempt = createTestAttempt(
        id: attemptId,
        status: AttemptStatus.inProgress,
      );

      when(() => mockRepository.getAttemptById(attemptId))
          .thenAnswer((_) async => Right(inProgressAttempt));

      when(() => mockRepository.completeAttempt(attemptId))
          .thenAnswer((_) async => const Left(CacheFailure('Update failed')));

      final result = await useCase(attemptId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (attempt) => fail('Expected Left but got Right'),
      );
    });
  });
}
