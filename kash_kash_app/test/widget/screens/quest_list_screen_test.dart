import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';
import 'package:kash_kash_app/presentation/widgets/error_view.dart';
import 'package:kash_kash_app/presentation/widgets/offline_banner.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  Widget buildApp(QuestListState questState) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(
          () => TestAuthNotifier(TestAuthStates.authenticated),
        ),
        questListProvider.overrideWith(
          () => TestQuestListNotifier(questState),
        ),
        distanceFilterProvider.overrideWith(
          () => TestDistanceFilterNotifier(DistanceFilter.km5),
        ),
      ],
      child: const KashKashApp(),
    );
  }

  group('QuestListScreen', () {
    testWidgets('loading state shows skeleton cards', (tester) async {
      await tester.pumpWidget(
        buildApp(const QuestListState(isLoading: true)),
      );
      // Use pump() instead of pumpAndSettle() since skeleton cards
      // could gain shimmer animations that would cause a timeout
      await tester.pump();

      // Skeleton shows 5 Card widgets
      expect(find.byType(Card), findsNWidgets(5));
    });

    testWidgets('empty state shows message and refresh button',
        (tester) async {
      await tester.pumpWidget(
        buildApp(const QuestListState(isLoading: false, quests: [])),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
            'No quests nearby. Try increasing the search radius or check back later for new quests.'),
        findsOneWidget,
      );
      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('error state shows ErrorView with retry', (tester) async {
      await tester.pumpWidget(
        buildApp(const QuestListState(
            isLoading: false, error: 'GPS permission denied')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('GPS permission denied'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('populated state shows quest cards with title and distance',
        (tester) async {
      final quest = FakeData.createQuest(title: 'Treasure in the Park');
      await tester.pumpWidget(
        buildApp(QuestListState(
          isLoading: false,
          quests: [
            QuestWithDistance(quest: quest, distanceMeters: 350.0),
          ],
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treasure in the Park'), findsOneWidget);
      // 350m should be formatted as "350 m"
      expect(find.text('350 m'), findsOneWidget);
    });

    testWidgets('offline state shows OfflineBanner', (tester) async {
      await tester.pumpWidget(
        buildApp(
            const QuestListState(isLoading: false, quests: [], isOffline: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
    });

    testWidgets('filter tabs show all distance options', (tester) async {
      await tester.pumpWidget(
        buildApp(const QuestListState(isLoading: false, quests: [])),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text('2 km'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('10 km'), findsOneWidget);
      expect(find.text('20 km'), findsOneWidget);
    });

    testWidgets('AppBar has history icon and menu', (tester) async {
      await tester.pumpWidget(
        buildApp(const QuestListState(isLoading: false, quests: [])),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('popup menu shows Sign Out', (tester) async {
      await tester.pumpWidget(
        buildApp(const QuestListState(isLoading: false, quests: [])),
      );
      await tester.pumpAndSettle();

      // Tap the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
