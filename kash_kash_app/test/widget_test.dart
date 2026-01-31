import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';
import 'package:kash_kash_app/presentation/providers/quest_provider.dart';

void main() {
  testWidgets('App initializes with login screen when not authenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _UnauthenticatedAuthNotifier(),
          ),
        ],
        child: const KashKashApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should redirect to login since not authenticated
    expect(find.text('Kash-Kash'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('App shows quest list when authenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(
            () => _AuthenticatedAuthNotifier(),
          ),
          questListProvider.overrideWith(
            () => _MockQuestListNotifier(),
          ),
        ],
        child: const KashKashApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should show quest list when authenticated - check AppBar
    expect(find.widgetWithText(AppBar, 'Nearby Quests'), findsOneWidget);
  });
}

/// Test auth notifier that returns unauthenticated state
class _UnauthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Test auth notifier that returns authenticated state
class _AuthenticatedAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    return const AuthState(status: AuthStatus.authenticated);
  }
}

/// Mock quest list notifier that returns empty state (no GPS calls)
class _MockQuestListNotifier extends QuestListNotifier {
  @override
  QuestListState build() {
    return const QuestListState(
      isLoading: false,
      quests: [],
    );
  }
}
