@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

import 'package:kash_kash_app/presentation/providers/active_quest_provider.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/screens/active_quest_screen.dart';
import 'package:kash_kash_app/presentation/widgets/game_background.dart';
import 'package:kash_kash_app/presentation/widgets/win_overlay.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  setUp(() {
    // Replace wakelock platform with a no-op fake
    WakelockPlusPlatformInterface.instance = FakeWakelockPlatform();
  });

  /// Helper to pump the ActiveQuestScreen directly (not via router).
  Future<void> pumpActiveQuestScreen(
    WidgetTester tester, {
    required AsyncValue<ActiveQuestState> state,
    String questId = 'quest-123',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => TestAuthNotifier(TestAuthStates.authenticated),
          ),
          activeQuestProvider(questId).overrideWith(
            () => TestActiveQuestNotifier(state),
          ),
        ],
        child: MaterialApp(
          home: ActiveQuestScreen(questId: questId),
        ),
      ),
    );
    // Use pump() instead of pumpAndSettle() for loading states
    // that have ongoing animations
    await tester.pump();
  }

  group('ActiveQuestScreen', () {
    testWidgets('loading state shows black screen with spinner',
        (tester) async {
      await pumpActiveQuestScreen(
        tester,
        state: const AsyncLoading(),
      );
      // Pump additional frames to let the async notifier settle into loading
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Starting quest...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error state shows error message and back button',
        (tester) async {
      await pumpActiveQuestScreen(
        tester,
        state: AsyncError(Exception('Quest not found'), StackTrace.current),
      );
      await tester.pumpAndSettle();

      expect(find.text('Failed to start quest'), findsOneWidget);
      expect(find.text('Back to Quests'), findsOneWidget);
    });

    testWidgets('gameplay state shows GameBackground and abandon button',
        (tester) async {
      final quest = FakeData.createQuest();
      final attempt = FakeData.createQuestAttempt();

      await pumpActiveQuestScreen(
        tester,
        state: AsyncData(ActiveQuestState(
          quest: quest,
          attempt: attempt,
          gameplayState: GameplayState.stationary,
          elapsed: const Duration(minutes: 2, seconds: 30),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GameBackground), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      // Elapsed time should be displayed
      expect(find.text('02:30'), findsOneWidget);
    });

    testWidgets('won state shows WinOverlay with congratulations',
        (tester) async {
      final quest = FakeData.createQuest(title: 'Golden Cache');
      final attempt = FakeData.createCompletedAttempt(
        distanceWalked: 250.0,
      );

      await pumpActiveQuestScreen(
        tester,
        state: AsyncData(ActiveQuestState(
          quest: quest,
          attempt: attempt,
          gameplayState: GameplayState.won,
          elapsed: const Duration(minutes: 5),
        )),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WinOverlay), findsOneWidget);
      expect(find.text('You Found It!'), findsOneWidget);
    });
  });
}
