import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kash_kash_app/core/errors/failures.dart';
import 'package:kash_kash_app/domain/entities/quest_attempt.dart';
import 'package:kash_kash_app/domain/repositories/attempt_repository.dart';
import 'package:kash_kash_app/domain/usecases/start_quest_use_case.dart';
import 'package:mocktail/mocktail.dart';

class MockAttemptRepository extends Mock implements IAttemptRepository {}

void main() {
  late MockAttemptRepository mockRepository;
  late StartQuestUseCase useCase;

  final now = DateTime.now();

  QuestAttempt createTestAttempt({
    required String id,
    String questId = 'quest-1',
    String userId = 'user-1',
    AttemptStatus status = AttemptStatus.inProgress,
  }) {
    return QuestAttempt(
      id: id,
      questId: questId,
      userId: userId,
      startedAt: now,
      status: status,
    );
  }

  setUp(() {
    mockRepository = MockAttemptRepository();
    useCase = StartQuestUseCase(mockRepository);
  });

  group('StartQuestUseCase', () {
    test('should create new attempt when no active attempt exists', () async {
      const questId = 'quest-1';
      const userId = 'user-1';
      final newAttempt = createTestAttempt(id: 'new-attempt');

      when(() => mockRepository.getActiveAttempt(userId))
          .thenAnswer((_) async => const Right(null));

      when(() => mockRepository.startAttempt(
            questId: questId,
            userId: userId,
          )).thenAnswer((_) async => Right(newAttempt));

      final result = await useCase(questId: questId, userId: userId);

      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Expected Right but got Left'),
        (attempt) {
          expect(attempt.id, 'new-attempt');
          expect(attempt.questId, questId);
          expect(attempt.userId, userId);
        },
      );

      verify(() => mockRepository.getActiveAttempt(userId)).called(1);
      verify(() => mockRepository.startAttempt(
            questId: questId,
            userId: userId,
          )).called(1);
    });

    test('should return failure when user already has active attempt', () async {
      const questId = 'quest-1';
      const userId = 'user-1';
      final existingAttempt = createTestAttempt(id: 'existing-attempt');

      when(() => mockRepository.getActiveAttempt(userId))
          .thenAnswer((_) async => Right(existingAttempt));

      final result = await useCase(questId: questId, userId: userId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) {
          expect(failure, isA<ValidationFailure>());
          expect(failure.message, contains('active quest'));
        },
        (attempt) => fail('Expected Left but got Right'),
      );

      verify(() => mockRepository.getActiveAttempt(userId)).called(1);
      verifyNever(() => mockRepository.startAttempt(
            questId: any(named: 'questId'),
            userId: any(named: 'userId'),
          ));
    });

    test('should return failure when getActiveAttempt fails', () async {
      const questId = 'quest-1';
      const userId = 'user-1';

      when(() => mockRepository.getActiveAttempt(userId))
          .thenAnswer((_) async => const Left(CacheFailure('Database error')));

      final result = await useCase(questId: questId, userId: userId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (attempt) => fail('Expected Left but got Right'),
      );
    });

    test('should return failure when startAttempt fails', () async {
      const questId = 'quest-1';
      const userId = 'user-1';

      when(() => mockRepository.getActiveAttempt(userId))
          .thenAnswer((_) async => const Right(null));

      when(() => mockRepository.startAttempt(
            questId: questId,
            userId: userId,
          )).thenAnswer((_) async => const Left(CacheFailure('Insert failed')));

      final result = await useCase(questId: questId, userId: userId);

      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (attempt) => fail('Expected Left but got Right'),
      );
    });
  });
}
