import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/domain/entities/quest_attempt.dart';
import 'package:kash_kash_app/presentation/providers/quest_history_provider.dart';

void main() {
  group('HistoryFilter', () {
    test('should have all expected values', () {
      expect(HistoryFilter.values, hasLength(3));
      expect(HistoryFilter.all, isNotNull);
      expect(HistoryFilter.completed, isNotNull);
      expect(HistoryFilter.abandoned, isNotNull);
    });
  });

  group('QuestAttemptWithQuest', () {
    test('should create with attempt and quest', () {
      final attempt = QuestAttempt(
        id: 'attempt-1',
        questId: 'quest-1',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.completed,
      );
      final quest = Quest(
        id: 'quest-1',
        title: 'Test Quest',
        latitude: 48.8566,
        longitude: 2.3522,
        createdBy: 'user-1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final attemptWithQuest = QuestAttemptWithQuest(
        attempt: attempt,
        quest: quest,
      );

      expect(attemptWithQuest.attempt, equals(attempt));
      expect(attemptWithQuest.quest, equals(quest));
    });

    test('should create with attempt and null quest', () {
      final attempt = QuestAttempt(
        id: 'attempt-1',
        questId: 'quest-1',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.completed,
      );

      final attemptWithQuest = QuestAttemptWithQuest(
        attempt: attempt,
        quest: null,
      );

      expect(attemptWithQuest.attempt, equals(attempt));
      expect(attemptWithQuest.quest, isNull);
    });
  });

  group('QuestHistoryState', () {
    test('should create with default values', () {
      const state = QuestHistoryState();

      expect(state.attempts, isEmpty);
      expect(state.filter, equals(HistoryFilter.all));
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
    });

    test('isEmpty should return true when attempts list is empty', () {
      const state = QuestHistoryState();
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty should return false when attempts list is not empty', () {
      final attempt = QuestAttempt(
        id: 'attempt-1',
        questId: 'quest-1',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.completed,
      );
      final state = QuestHistoryState(
        attempts: [QuestAttemptWithQuest(attempt: attempt)],
      );
      expect(state.isEmpty, isFalse);
    });

    test('hasError should return true when error is not null', () {
      const state = QuestHistoryState(error: 'Something went wrong');
      expect(state.hasError, isTrue);
    });

    test('hasError should return false when error is null', () {
      const state = QuestHistoryState();
      expect(state.hasError, isFalse);
    });

    group('copyWith', () {
      test('should copy with new attempts', () {
        const originalState = QuestHistoryState();
        final attempt = QuestAttempt(
          id: 'attempt-1',
          questId: 'quest-1',
          userId: 'user-1',
          startedAt: DateTime.now(),
          status: AttemptStatus.completed,
        );
        final newAttempts = [
          QuestAttemptWithQuest(attempt: attempt),
        ];

        final newState = originalState.copyWith(attempts: newAttempts);

        expect(newState.attempts, equals(newAttempts));
        expect(newState.filter, equals(originalState.filter));
      });

      test('should copy with new filter', () {
        const originalState = QuestHistoryState();
        final newState =
            originalState.copyWith(filter: HistoryFilter.completed);

        expect(newState.filter, equals(HistoryFilter.completed));
      });

      test('should copy with new loading state', () {
        const originalState = QuestHistoryState();
        final newState = originalState.copyWith(isLoading: true);

        expect(newState.isLoading, isTrue);
      });

      test('should copy with new error', () {
        const originalState = QuestHistoryState();
        final newState = originalState.copyWith(error: 'Error message');

        expect(newState.error, equals('Error message'));
      });

      test('should clear error with clearError flag', () {
        const originalState = QuestHistoryState(error: 'Original error');
        final newState = originalState.copyWith(clearError: true);

        expect(newState.error, isNull);
      });

      test('should preserve all fields when no changes', () {
        final attempt = QuestAttempt(
          id: 'attempt-1',
          questId: 'quest-1',
          userId: 'user-1',
          startedAt: DateTime.now(),
          status: AttemptStatus.completed,
        );
        final originalState = QuestHistoryState(
          attempts: [QuestAttemptWithQuest(attempt: attempt)],
          filter: HistoryFilter.completed,
          isLoading: true,
          error: 'Some error',
        );

        final newState = originalState.copyWith();

        expect(newState.attempts, equals(originalState.attempts));
        expect(newState.filter, equals(originalState.filter));
        expect(newState.isLoading, equals(originalState.isLoading));
        expect(newState.error, equals(originalState.error));
      });
    });
  });

  group('HistoryFilter filtering logic', () {
    test('should filter completed attempts correctly', () {
      final completedAttempt = QuestAttempt(
        id: 'attempt-1',
        questId: 'quest-1',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.completed,
      );
      final abandonedAttempt = QuestAttempt(
        id: 'attempt-2',
        questId: 'quest-2',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.abandoned,
      );

      final allAttempts = [completedAttempt, abandonedAttempt];

      // Filter completed
      final completedOnly =
          allAttempts.where((a) => a.status == AttemptStatus.completed).toList();
      expect(completedOnly, hasLength(1));
      expect(completedOnly.first.id, equals('attempt-1'));

      // Filter abandoned
      final abandonedOnly =
          allAttempts.where((a) => a.status == AttemptStatus.abandoned).toList();
      expect(abandonedOnly, hasLength(1));
      expect(abandonedOnly.first.id, equals('attempt-2'));
    });

    test('should show all attempts when filter is all', () {
      final completedAttempt = QuestAttempt(
        id: 'attempt-1',
        questId: 'quest-1',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.completed,
      );
      final abandonedAttempt = QuestAttempt(
        id: 'attempt-2',
        questId: 'quest-2',
        userId: 'user-1',
        startedAt: DateTime.now(),
        status: AttemptStatus.abandoned,
      );

      final allAttempts = [completedAttempt, abandonedAttempt];
      const filter = HistoryFilter.all;

      // When filter is 'all', no filtering should be applied
      final result = filter == HistoryFilter.all
          ? allAttempts
          : allAttempts.where((a) {
              return filter == HistoryFilter.completed
                  ? a.status == AttemptStatus.completed
                  : a.status == AttemptStatus.abandoned;
            }).toList();

      expect(result, hasLength(2));
    });
  });
}
