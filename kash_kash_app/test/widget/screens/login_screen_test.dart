import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/main.dart';
import 'package:kash_kash_app/presentation/providers/auth_provider.dart';

import '../../helpers/fakes.dart';
import '../../helpers/test_notifiers.dart';

void main() {
  Widget buildLoginApp(AuthState authState) {
    return ProviderScope(
      overrides: [
        authProvider.overrideWith(() => TestAuthNotifier(authState)),
      ],
      child: const KashKashApp(),
    );
  }

  group('LoginScreen', () {
    testWidgets('idle state shows title, tagline, and sign-in button',
        (tester) async {
      await tester.pumpWidget(buildLoginApp(TestAuthStates.unauthenticated));
      await tester.pumpAndSettle();

      expect(find.text('Kash-Kash'), findsOneWidget);
      expect(find.text('Find treasures near you'), findsOneWidget);
      expect(find.text('Sign in with Google'), findsOneWidget);
    });

    testWidgets('loading state shows spinner and signing-in text',
        (tester) async {
      await tester.pumpWidget(buildLoginApp(TestAuthStates.loading));
      // Use pump() instead of pumpAndSettle() since CircularProgressIndicator
      // animates indefinitely and would cause pumpAndSettle to time out
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Signing in...'), findsOneWidget);
      // Sign in button should not be visible during loading
      expect(find.text('Sign in with Google'), findsNothing);
    });

    testWidgets('error state shows error message', (tester) async {
      await tester.pumpWidget(buildLoginApp(TestAuthStates.error));
      await tester.pumpAndSettle();

      expect(find.text('Authentication failed'), findsOneWidget);
      // Sign in button should still be visible to retry
      expect(find.text('Sign in with Google'), findsOneWidget);
    });
  });
}
