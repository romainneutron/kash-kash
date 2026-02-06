import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';
import 'package:kash_kash_app/presentation/widgets/error_view.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  /// Pump the app and navigate to admin quest list screen.
  Future<void> pumpAdminQuestListScreen(
    WidgetTester tester, {
    required AdminQuestListState adminState,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => TestAuthNotifier(TestAuthStates.authenticatedAdmin),
          ),
          questListProvider.overrideWith(
            () => TestQuestListNotifier(
              const QuestListState(isLoading: false, quests: []),
            ),
          ),
          distanceFilterProvider.overrideWith(
            () => TestDistanceFilterNotifier(DistanceFilter.km5),
          ),
          adminQuestListProvider.overrideWith(
            () => TestAdminQuestListNotifier(adminState),
          ),
        ],
        child: const KashKashApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to admin screen via popup menu
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin Panel'));
    await tester.pumpAndSettle();
  }

  group('AdminQuestListScreen', () {
    testWidgets('empty state shows message', (tester) async {
      await pumpAdminQuestListScreen(
        tester,
        adminState: const AdminQuestListState(),
      );

      expect(
        find.text('No quests yet. Create your first quest!'),
        findsOneWidget,
      );
    });

    testWidgets('populated state shows quest cards with title',
        (tester) async {
      final quest = FakeData.createQuest(title: 'Admin Quest');

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      expect(find.text('Admin Quest'), findsOneWidget);
    });

    testWidgets('search filtering shows no match message', (tester) async {
      final quest = FakeData.createQuest(title: 'Forest Quest');

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(
          quests: [quest],
          searchQuery: 'nonexistent',
        ),
      );

      expect(
        find.text('No quests match your search.'),
        findsOneWidget,
      );
    });

    testWidgets('published quest shows switch on', (tester) async {
      final quest = FakeData.createQuest(published: true);

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('unpublished quest shows switch off', (tester) async {
      final quest = FakeData.createQuest(published: false);

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      final quest = FakeData.createQuest(title: 'Delete Me');

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('Delete Quest'), findsOneWidget);
      expect(
        find.text('Are you sure you want to delete "Delete Me"?'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('FAB is present for creating quest', (tester) async {
      await pumpAdminQuestListScreen(
        tester,
        adminState: const AdminQuestListState(),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('error state shows ErrorView with retry', (tester) async {
      await pumpAdminQuestListScreen(
        tester,
        adminState: const AdminQuestListState(error: 'Network error'),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('search bar is present', (tester) async {
      final quest = FakeData.createQuest();

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('quest card shows coordinates', (tester) async {
      final quest = FakeData.createQuest(
        latitude: 48.8566,
        longitude: 2.3522,
      );

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      expect(find.text('48.8566, 2.3522'), findsOneWidget);
    });

    testWidgets('quest card shows difficulty and location type',
        (tester) async {
      final quest = FakeData.createQuest(
        difficulty: QuestDifficulty.hard,
        locationType: LocationType.forest,
      );

      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      expect(find.text('hard'), findsOneWidget);
      expect(find.text('forest'), findsOneWidget);
    });
  });
}
