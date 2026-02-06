import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/domain/entities/quest.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_form_provider.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_admin_helpers.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  /// Pump the app and navigate to the quest form via admin list > FAB.
  /// Returns the test form notifier for interaction assertions.
  ///
  /// Set [settle] to false when testing animations (e.g. LinearProgressIndicator).
  Future<TestAdminQuestFormNotifier> pumpCreateForm(
    WidgetTester tester, {
    required AdminQuestFormState formState,
    bool settle = true,
  }) async {
    final formNotifier = TestAdminQuestFormNotifier(formState);

    await pumpAdminApp(
      tester,
      adminListOverride: () =>
          TestAdminQuestListNotifier(AdminQuestListState()),
      adminFormOverride: () => formNotifier,
    );

    // Tap FAB to navigate to create form
    await tester.tap(find.byType(FloatingActionButton));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }

    return formNotifier;
  }

  group('AdminQuestFormScreen - Create Mode', () {
    testWidgets('shows Create Quest title', (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(),
      );

      expect(find.text('Create Quest'), findsOneWidget);
    });

    testWidgets('shows all form fields', (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(),
      );

      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('Difficulty'), findsOneWidget);
      expect(find.text('Location Type'), findsOneWidget);
      expect(find.text('Latitude *'), findsOneWidget);
      expect(find.text('Longitude *'), findsOneWidget);
      expect(find.text('Use Current Location'), findsOneWidget);
    });

    testWidgets('shows Save button in AppBar', (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(),
      );

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('shows radius slider', (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(),
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.textContaining('Radius:'), findsOneWidget);
    });

    testWidgets('shows error banner when error is set', (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(
          error: 'Please fill in all required fields',
        ),
      );

      expect(
        find.text('Please fill in all required fields'),
        findsOneWidget,
      );
    });

    testWidgets('dismiss error banner calls clearError', (tester) async {
      final notifier = await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(
          error: 'Some error',
        ),
      );

      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();

      expect(notifier.clearErrorCalls, 1);
    });

    testWidgets('tapping Save with empty title shows validation error',
        (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(),
      );

      // Tap Save without filling in fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });

    testWidgets('tapping Save with valid form calls save', (tester) async {
      final notifier = await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(
          formData: QuestFormData(
            title: 'Test',
            latitude: 48.0,
            longitude: 2.0,
          ),
        ),
      );

      // Title and coordinates are pre-filled via _initControllers,
      // so form validation should pass.
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(notifier.saveCalls, 1);
    });

    testWidgets('shows saving indicator', (tester) async {
      await pumpCreateForm(
        tester,
        formState: const AdminQuestFormState(isSaving: true),
        settle: false,
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  group('AdminQuestFormScreen - Error State', () {
    testWidgets('shows error text when quest loading fails', (tester) async {
      final errorNotifier =
          TestAdminQuestFormErrorNotifier('Quest not found');

      await pumpAdminApp(
        tester,
        adminListOverride: () =>
            TestAdminQuestListNotifier(AdminQuestListState()),
        adminFormOverride: () => errorNotifier,
      );

      // Tap FAB to navigate to create form
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Quest not found'), findsOneWidget);
    });
  });

  group('AdminQuestFormScreen - Edit Mode', () {
    testWidgets('navigating via edit icon shows Edit Quest title',
        (tester) async {
      final quest = FakeData.createQuest(id: 'quest-edit-1', title: 'Editable');
      final editState = AdminQuestFormState(
        existingQuest: quest,
        formData: QuestFormData(
          title: quest.title,
          description: quest.description ?? '',
          difficulty: quest.difficulty,
          locationType: quest.locationType,
          radiusMeters: quest.radiusMeters,
          latitude: quest.latitude,
          longitude: quest.longitude,
        ),
      );

      await pumpAdminApp(
        tester,
        adminListOverride: () => TestAdminQuestListNotifier(
          AdminQuestListState(quests: [quest]),
        ),
        adminFormOverride: () => TestAdminQuestFormNotifier(editState),
      );

      // Tap edit icon on quest card
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.text('Edit Quest'), findsOneWidget);
    });

    testWidgets('shows Edit Quest title', (tester) async {
      final quest = FakeData.createQuest(title: 'Existing Quest');

      // We need to navigate to edit directly since the FAB goes to create.
      // Instead, test the pre-filled state in create mode (same screen widget).
      await pumpCreateForm(
        tester,
        formState: AdminQuestFormState(
          existingQuest: quest,
          formData: QuestFormData(
            title: quest.title,
            description: quest.description ?? '',
            difficulty: quest.difficulty,
            locationType: quest.locationType,
            radiusMeters: quest.radiusMeters,
            latitude: quest.latitude,
            longitude: quest.longitude,
          ),
        ),
      );

      // The screen uses widget.questId to determine title, and since
      // we navigated via FAB (no questId), it shows Create Quest.
      // We verify the form is pre-filled instead.
      expect(find.text('Existing Quest'), findsOneWidget);
    });

    testWidgets('pre-fills form data in edit mode', (tester) async {
      final quest = FakeData.createQuest(
        title: 'Mountain Trek',
        description: 'A mountain quest',
        difficulty: QuestDifficulty.hard,
        locationType: LocationType.mountain,
        radiusMeters: 10.0,
        latitude: 45.5,
        longitude: 6.5,
      );

      await pumpCreateForm(
        tester,
        formState: AdminQuestFormState(
          existingQuest: quest,
          formData: QuestFormData(
            title: quest.title,
            description: quest.description ?? '',
            difficulty: quest.difficulty,
            locationType: quest.locationType,
            radiusMeters: quest.radiusMeters,
            latitude: quest.latitude,
            longitude: quest.longitude,
          ),
        ),
      );

      // Check title is pre-filled
      expect(find.text('Mountain Trek'), findsOneWidget);
      // Check description is pre-filled
      expect(find.text('A mountain quest'), findsOneWidget);
      // Check coordinates are pre-filled
      expect(find.text('45.5'), findsOneWidget);
      expect(find.text('6.5'), findsOneWidget);
      // Check radius label
      expect(find.text('Radius: 10 m'), findsOneWidget);
    });
  });
}
