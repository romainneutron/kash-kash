import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/router/app_router.dart';

/// Test auth state that returns authenticated
class AuthenticatedAuthState extends AuthState {
  @override
  bool build() => true;
}

void main() {
  testWidgets('App initializes with login screen when not authenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KashKashApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should redirect to login since not authenticated - check AppBar
    expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
  });

  testWidgets('App shows quest list when authenticated', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => AuthenticatedAuthState()),
        ],
        child: const KashKashApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Should show quest list when authenticated - check AppBar
    expect(find.widgetWithText(AppBar, 'Nearby Quests'), findsOneWidget);
  });
}
