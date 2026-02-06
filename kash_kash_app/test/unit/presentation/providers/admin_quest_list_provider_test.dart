import 'package:flutter_test/flutter_test.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';

import '../../../helpers/fakes.dart';

void main() {
  group('AdminQuestListState', () {
    group('filteredQuests', () {
      test('returns all quests when searchQuery is empty', () {
        final quests = [
          FakeData.createQuest(id: 'q1', title: 'Forest Trek'),
          FakeData.createQuest(id: 'q2', title: 'City Walk'),
        ];
        final state = AdminQuestListState(quests: quests);

        expect(state.filteredQuests, quests);
      });

      test('filters quests case-insensitively', () {
        final quests = [
          FakeData.createQuest(id: 'q1', title: 'Forest Trek'),
          FakeData.createQuest(id: 'q2', title: 'City Walk'),
          FakeData.createQuest(id: 'q3', title: 'FOREST Run'),
        ];
        final state = AdminQuestListState(
          quests: quests,
          searchQuery: 'forest',
        );

        expect(state.filteredQuests.length, 2);
        expect(state.filteredQuests[0].id, 'q1');
        expect(state.filteredQuests[1].id, 'q3');
      });

      test('returns empty list when no quests match', () {
        final quests = [
          FakeData.createQuest(id: 'q1', title: 'Forest Trek'),
        ];
        final state = AdminQuestListState(
          quests: quests,
          searchQuery: 'mountain',
        );

        expect(state.filteredQuests, isEmpty);
      });
    });

    group('isFilteredEmpty', () {
      test('returns true when no quests match filter', () {
        final state = AdminQuestListState(
          quests: [FakeData.createQuest(title: 'Forest')],
          searchQuery: 'zzz',
        );

        expect(state.isFilteredEmpty, isTrue);
      });

      test('returns false when quests match filter', () {
        final state = AdminQuestListState(
          quests: [FakeData.createQuest(title: 'Forest')],
          searchQuery: 'for',
        );

        expect(state.isFilteredEmpty, isFalse);
      });

      test('returns true when quests list is empty', () {
        final state = AdminQuestListState();

        expect(state.isFilteredEmpty, isTrue);
      });
    });

    group('hasNoQuests', () {
      test('returns true when quests list is empty', () {
        final state = AdminQuestListState();

        expect(state.hasNoQuests, isTrue);
      });

      test('returns false when quests exist even if filtered is empty', () {
        final state = AdminQuestListState(
          quests: [FakeData.createQuest(title: 'Forest')],
          searchQuery: 'zzz',
        );

        expect(state.hasNoQuests, isFalse);
        expect(state.isFilteredEmpty, isTrue);
      });
    });

    group('hasError', () {
      test('returns true when error is set', () {
        final state = AdminQuestListState(error: 'Something went wrong');

        expect(state.hasError, isTrue);
      });

      test('returns false when error is null', () {
        final state = AdminQuestListState();

        expect(state.hasError, isFalse);
      });
    });

    group('copyWith', () {
      test('preserves values when no arguments provided', () {
        final quests = [FakeData.createQuest()];
        final state = AdminQuestListState(
          quests: quests,
          searchQuery: 'test',
          isSaving: true,
          error: 'err',
        );
        final copy = state.copyWith();

        expect(copy.quests, quests);
        expect(copy.searchQuery, 'test');
        expect(copy.isSaving, isTrue);
        expect(copy.error, 'err');
      });

      test('clearError removes error', () {
        final state = AdminQuestListState(error: 'err');
        final copy = state.copyWith(clearError: true);

        expect(copy.error, isNull);
      });
    });

    group('equality', () {
      test('equal states are equal', () {
        final quests = [FakeData.createQuest()];
        final a = AdminQuestListState(quests: quests);
        final b = AdminQuestListState(quests: quests);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different states are not equal', () {
        final a = AdminQuestListState(
          quests: [FakeData.createQuest(id: 'q1')],
        );
        final b = AdminQuestListState(
          quests: [FakeData.createQuest(id: 'q2')],
        );

        expect(a, isNot(b));
      });
    });
  });
}
