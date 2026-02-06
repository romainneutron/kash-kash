import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/domain/entities/quest_attempt.dart';
import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_history_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  /// Pump the app and navigate to history screen.
  Future<void> pumpHistoryScreen(
    WidgetTester tester, {
    required QuestHistoryState historyState,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => TestAuthNotifier(TestAuthStates.authenticated),
          ),
          questListProvider.overrideWith(
            () => TestQuestListNotifier(
              const QuestListState(isLoading: false, quests: []),
            ),
          ),
          questHistoryProvider.overrideWith(
            () => TestQuestHistoryNotifier(historyState),
          ),
          historyFilterProvider.overrideWith(
            () => TestHistoryFilterNotifier(historyState.filter),
          ),
        ],
        child: const KashKashApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to history screen via the history icon button
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
  }

  group('QuestHistoryScreen', () {
    testWidgets('empty state (all filter) shows message', (tester) async {
      await pumpHistoryScreen(
        tester,
        historyState: const QuestHistoryState(),
      );

      expect(
        find.text(
            'No quest history yet. Start playing to see your attempts here.'),
        findsOneWidget,
      );
    });

    testWidgets('empty state (completed filter) shows message',
        (tester) async {
      await pumpHistoryScreen(
        tester,
        historyState:
            const QuestHistoryState(filter: HistoryFilter.completed),
      );

      expect(
        find.text('No completed quests yet. Keep exploring!'),
        findsOneWidget,
      );
    });

    testWidgets('empty state (abandoned filter) shows message',
        (tester) async {
      await pumpHistoryScreen(
        tester,
        historyState:
            const QuestHistoryState(filter: HistoryFilter.abandoned),
      );

      expect(
        find.text('No abandoned quests. Great job sticking with it!'),
        findsOneWidget,
      );
    });

    testWidgets('populated state shows history card with quest title',
        (tester) async {
      final quest = FakeData.createQuest(title: 'Park Adventure');
      final attempt = FakeData.createCompletedAttempt(
        durationSeconds: 600,
        distanceWalked: 450.0,
      );

      await pumpHistoryScreen(
        tester,
        historyState: QuestHistoryState(
          attempts: [
            QuestAttemptWithQuest(attempt: attempt, quest: quest),
          ],
        ),
      );

      expect(find.text('Park Adventure'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Distance'), findsOneWidget);
    });

    testWidgets('completed attempt shows green check icon', (tester) async {
      final quest = FakeData.createQuest();
      final attempt = FakeData.createCompletedAttempt();

      await pumpHistoryScreen(
        tester,
        historyState: QuestHistoryState(
          attempts: [
            QuestAttemptWithQuest(attempt: attempt, quest: quest),
          ],
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('abandoned attempt shows orange cancel icon', (tester) async {
      final quest = FakeData.createQuest();
      final attempt = FakeData.createQuestAttempt(
        status: AttemptStatus.abandoned,
        abandonedAt: DateTime(2024, 1, 1, 10, 10),
        durationSeconds: 600,
      );

      await pumpHistoryScreen(
        tester,
        historyState: QuestHistoryState(
          attempts: [
            QuestAttemptWithQuest(attempt: attempt, quest: quest),
          ],
        ),
      );

      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('filter chips show All, Completed, Abandoned', (tester) async {
      await pumpHistoryScreen(
        tester,
        historyState: const QuestHistoryState(),
      );

      expect(find.byType(ChoiceChip), findsNWidgets(3));
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Abandoned'), findsOneWidget);
    });
  });
}
