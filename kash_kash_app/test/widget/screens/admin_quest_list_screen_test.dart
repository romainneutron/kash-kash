import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';
import 'package:kash_kash_app/presentation/widgets/error_view.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_admin_helpers.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  /// Pump the app and navigate to admin quest list screen.
  /// Returns the test notifier for interaction assertions.
  Future<TestAdminQuestListNotifier> pumpAdminQuestListScreen(
    WidgetTester tester, {
    required AdminQuestListState adminState,
  }) async {
    final notifier = TestAdminQuestListNotifier(adminState);

    await pumpAdminApp(
      tester,
      adminListOverride: () => notifier,
    );

    return notifier;
  }

  group('AdminQuestListScreen', () {
    testWidgets('empty state shows message', (tester) async {
      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(),
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

    testWidgets('toggle switch calls togglePublished', (tester) async {
      final quest = FakeData.createQuest(published: false);

      final notifier = await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(notifier.togglePublishedCalls, hasLength(1));
      expect(notifier.togglePublishedCalls.first.id, quest.id);
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

    testWidgets('confirming delete calls deleteQuest', (tester) async {
      final quest = FakeData.createQuest(title: 'Delete Me');

      final notifier = await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Tap the Delete button in the dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(notifier.deleteQuestCalls, hasLength(1));
      expect(notifier.deleteQuestCalls.first, quest.id);
    });

    testWidgets('cancelling delete does not call deleteQuest', (tester) async {
      final quest = FakeData.createQuest(title: 'Keep Me');

      final notifier = await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(quests: [quest]),
      );

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Tap Cancel in the dialog
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(notifier.deleteQuestCalls, isEmpty);
    });

    testWidgets('FAB is present for creating quest', (tester) async {
      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('error state shows ErrorView with retry', (tester) async {
      await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(error: 'Network error'),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Network error'), findsOneWidget);
    });

    testWidgets('dismiss error banner calls clearError', (tester) async {
      final quest = FakeData.createQuest();

      final notifier = await pumpAdminQuestListScreen(
        tester,
        adminState: AdminQuestListState(
          quests: [quest],
          error: 'Something went wrong',
        ),
      );

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(notifier.clearErrorCalls, 1);
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
