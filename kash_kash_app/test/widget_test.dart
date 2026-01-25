import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kash_kash_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: KashKashApp(),
      ),
    );

    expect(find.text('Kash-Kash'), findsOneWidget);
    expect(find.text('Welcome to Kash-Kash!'), findsOneWidget);
  });
}
