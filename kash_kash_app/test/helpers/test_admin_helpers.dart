import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_form_provider.dart';
import 'package:kash_kash_app/presentation/providers/admin_quest_list_provider.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';

import 'fakes.dart';
import 'test_notifiers.dart';

/// Navigate to the admin panel from the home screen.
Future<void> navigateToAdminPanel(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Admin Panel'));
  await tester.pumpAndSettle();
}

/// Pump the app with admin provider overrides and navigate to admin panel.
///
/// Includes auth (admin), quest list, and distance filter overrides that
/// are shared across admin test files.
///
/// Set [settle] to false when testing widgets with ongoing animations.
Future<void> pumpAdminApp(
  WidgetTester tester, {
  AdminQuestListNotifier Function()? adminListOverride,
  AdminQuestFormNotifier Function()? adminFormOverride,
  bool settle = true,
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
        if (adminListOverride != null)
          adminQuestListProvider.overrideWith(adminListOverride),
        if (adminFormOverride != null)
          adminQuestFormProvider.overrideWith(adminFormOverride),
      ],
      child: const KashKashApp(),
    ),
  );
  await tester.pumpAndSettle();
  await navigateToAdminPanel(tester);
  if (!settle) await tester.pump();
}
