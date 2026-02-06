import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';
import 'package:kash_kash_app/presentation/screens/login_screen.dart';
import 'package:kash_kash_app/presentation/screens/quest_list_screen.dart';
import 'package:kash_kash_app/presentation/widgets/error_boundary.dart';
import 'package:kash_kash_app/router/app_router.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  /// Builds a test app that exercises the production redirect logic at a given
  /// [initialLocation].
  Widget buildRouterApp({
    required AuthState authState,
    required String initialLocation,
    QuestListState questState =
        const QuestListState(isLoading: false, quests: []),
  }) {
    final isAuthenticated = authState.isAuthenticated;
    final isAdmin = authState.user?.isAdmin ?? false;

    final router = GoRouter(
      initialLocation: initialLocation,
      redirect: (context, state) => appRedirect(
        state,
        isAuthenticated: isAuthenticated,
        isAdmin: isAdmin,
      ),
      routes: [
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppRoutes.questList,
          name: 'questList',
          builder: (context, state) => const ErrorBoundary(
            child: QuestListScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.questDetail,
          name: 'questDetail',
          builder: (context, state) =>
              const Scaffold(body: Text('Quest detail placeholder')),
        ),
        GoRoute(
          path: AppRoutes.activeQuest,
          name: 'activeQuest',
          builder: (context, state) =>
              const Scaffold(body: Text('Active quest placeholder')),
        ),
        GoRoute(
          path: AppRoutes.history,
          name: 'history',
          builder: (context, state) =>
              const Scaffold(body: Text('History placeholder')),
        ),
        GoRoute(
          path: AppRoutes.adminQuestList,
          name: 'adminQuestList',
          builder: (context, state) =>
              Scaffold(appBar: AppBar(title: const Text('Admin: Quests'))),
        ),
        GoRoute(
          path: AppRoutes.adminQuestCreate,
          name: 'adminQuestCreate',
          builder: (context, state) =>
              const Scaffold(body: Text('Create quest placeholder')),
        ),
        GoRoute(
          path: AppRoutes.adminQuestEdit,
          name: 'adminQuestEdit',
          builder: (context, state) =>
              const Scaffold(body: Text('Edit quest placeholder')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => TestAuthNotifier(authState)),
        questListProvider
            .overrideWith(() => TestQuestListNotifier(questState)),
        appRouterProvider.overrideWithValue(router),
      ],
      child: const KashKashApp(),
    );
  }

  group('AppRouter redirects', () {
    testWidgets('unauthenticated user on / sees LoginScreen', (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.unauthenticated,
        initialLocation: '/',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kash-Kash'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('unauthenticated user on /history redirects to LoginScreen',
        (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.unauthenticated,
        initialLocation: '/history',
      ));
      await tester.pumpAndSettle();

      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('authenticated user on /login redirects to QuestListScreen',
        (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.authenticated,
        initialLocation: '/login',
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Nearby Quests'), findsOneWidget);
    });

    testWidgets('authenticated user on / sees QuestListScreen',
        (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.authenticated,
        initialLocation: '/',
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Nearby Quests'), findsOneWidget);
    });

    testWidgets('non-admin on /admin/quests redirects to QuestListScreen',
        (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.authenticated,
        initialLocation: '/admin/quests',
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Nearby Quests'), findsOneWidget);
    });

    testWidgets('authenticated user on /history stays on history',
        (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.authenticated,
        initialLocation: '/history',
      ));
      await tester.pumpAndSettle();

      expect(find.text('History placeholder'), findsOneWidget);
    });

    testWidgets('admin on /login redirects to QuestListScreen',
        (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.authenticatedAdmin,
        initialLocation: '/login',
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Nearby Quests'), findsOneWidget);
    });

    testWidgets('admin on /admin/quests sees admin page', (tester) async {
      await tester.pumpWidget(buildRouterApp(
        authState: TestAuthStates.authenticatedAdmin,
        initialLocation: '/admin/quests',
      ));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Admin: Quests'), findsOneWidget);
    });
  });
}
