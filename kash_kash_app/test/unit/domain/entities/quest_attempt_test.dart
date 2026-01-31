import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/domain/entities/quest_attempt.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('QuestAttempt', () {
    group('creation', () {
      test('should create attempt with required fields', () {
        final attempt = FakeData.createQuestAttempt();

        expect(attempt.id, 'attempt-123');
        expect(attempt.questId, 'quest-123');
        expect(attempt.userId, 'user-123');
        expect(attempt.status, AttemptStatus.inProgress);
        expect(attempt.synced, isFalse);
      });

      test('should create in-progress attempt', () {
        final attempt = FakeData.createQuestAttempt(
          status: AttemptStatus.inProgress,
        );

        expect(attempt.isInProgress, isTrue);
        expect(attempt.isComplete, isFalse);
        expect(attempt.isAbandoned, isFalse);
        expect(attempt.completedAt, isNull);
        expect(attempt.abandonedAt, isNull);
      });

      test('should create completed attempt', () {
        final attempt = FakeData.createCompletedAttempt();

        expect(attempt.isComplete, isTrue);
        expect(attempt.isInProgress, isFalse);
        expect(attempt.isAbandoned, isFalse);
        expect(attempt.completedAt, isNotNull);
        expect(attempt.durationSeconds, 300);
        expect(attempt.distanceWalked, 150.0);
      });

      test('should create abandoned attempt', () {
        final startedAt = DateTime(2024, 1, 1, 10, 0);
        final abandonedAt = DateTime(2024, 1, 1, 10, 5);
        final attempt = FakeData.createQuestAttempt(
          status: AttemptStatus.abandoned,
          startedAt: startedAt,
          abandonedAt: abandonedAt,
          durationSeconds: 300,
        );

        expect(attempt.isAbandoned, isTrue);
        expect(attempt.isComplete, isFalse);
        expect(attempt.isInProgress, isFalse);
        expect(attempt.abandonedAt, abandonedAt);
      });
    });

    group('status helpers', () {
      test('isComplete should return true only for completed status', () {
        final completed = FakeData.createQuestAttempt(status: AttemptStatus.completed);
        final inProgress = FakeData.createQuestAttempt(status: AttemptStatus.inProgress);
        final abandoned = FakeData.createQuestAttempt(status: AttemptStatus.abandoned);

        expect(completed.isComplete, isTrue);
        expect(inProgress.isComplete, isFalse);
        expect(abandoned.isComplete, isFalse);
      });

      test('isAbandoned should return true only for abandoned status', () {
        final completed = FakeData.createQuestAttempt(status: AttemptStatus.completed);
        final inProgress = FakeData.createQuestAttempt(status: AttemptStatus.inProgress);
        final abandoned = FakeData.createQuestAttempt(status: AttemptStatus.abandoned);

        expect(abandoned.isAbandoned, isTrue);
        expect(completed.isAbandoned, isFalse);
        expect(inProgress.isAbandoned, isFalse);
      });

      test('isInProgress should return true only for inProgress status', () {
        final completed = FakeData.createQuestAttempt(status: AttemptStatus.completed);
        final inProgress = FakeData.createQuestAttempt(status: AttemptStatus.inProgress);
        final abandoned = FakeData.createQuestAttempt(status: AttemptStatus.abandoned);

        expect(inProgress.isInProgress, isTrue);
        expect(completed.isInProgress, isFalse);
        expect(abandoned.isInProgress, isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with modified status', () {
        final attempt = FakeData.createQuestAttempt(status: AttemptStatus.inProgress);
        final copy = attempt.copyWith(status: AttemptStatus.completed);

        expect(copy.status, AttemptStatus.completed);
        expect(copy.id, attempt.id);
      });

      test('should create copy with completion data', () {
        final attempt = FakeData.createQuestAttempt();
        final completedAt = DateTime.now();
        final copy = attempt.copyWith(
          status: AttemptStatus.completed,
          completedAt: completedAt,
          durationSeconds: 600,
          distanceWalked: 250.5,
        );

        expect(copy.status, AttemptStatus.completed);
        expect(copy.completedAt, completedAt);
        expect(copy.durationSeconds, 600);
        expect(copy.distanceWalked, 250.5);
      });

      test('should create copy with synced flag', () {
        final attempt = FakeData.createQuestAttempt(synced: false);
        final copy = attempt.copyWith(synced: true);

        expect(copy.synced, isTrue);
      });

      test('should preserve all fields when no changes', () {
        final attempt = FakeData.createCompletedAttempt();
        final copy = attempt.copyWith();

        expect(copy.id, attempt.id);
        expect(copy.questId, attempt.questId);
        expect(copy.userId, attempt.userId);
        expect(copy.status, attempt.status);
        expect(copy.durationSeconds, attempt.durationSeconds);
        expect(copy.distanceWalked, attempt.distanceWalked);
      });
    });

    group('equality', () {
      test('should be equal when ids match', () {
        final attempt1 = FakeData.createQuestAttempt(id: 'same-id');
        final attempt2 = FakeData.createQuestAttempt(
          id: 'same-id',
          status: AttemptStatus.completed,
        );

        expect(attempt1, equals(attempt2));
      });

      test('should not be equal when ids differ', () {
        final attempt1 = FakeData.createQuestAttempt(id: 'id-1');
        final attempt2 = FakeData.createQuestAttempt(id: 'id-2');

        expect(attempt1, isNot(equals(attempt2)));
      });

      test('should have same hashCode for equal attempts', () {
        final attempt1 = FakeData.createQuestAttempt(id: 'same-id');
        final attempt2 = FakeData.createQuestAttempt(id: 'same-id');

        expect(attempt1.hashCode, equals(attempt2.hashCode));
      });
    });
  });

  group('AttemptStatus', () {
    test('should have all expected values', () {
      expect(
        AttemptStatus.values,
        containsAll([
          AttemptStatus.inProgress,
          AttemptStatus.completed,
          AttemptStatus.abandoned,
        ]),
      );
      expect(AttemptStatus.values.length, 3);
    });
  });
}
