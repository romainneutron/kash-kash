import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/env_config.dart';
import 'core/utils/sentry_service.dart';
import 'presentation/theme/app_theme.dart';
import 'router/app_router.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Sentry
    await SentryService.init(
      dsn: EnvConfig.sentryDsn,
      environment: EnvConfig.environment,
    );

    runApp(
      const ProviderScope(
        child: KashKashApp(),
      ),
    );
  }, (error, stackTrace) {
    // Catch any errors that occur outside of Flutter's error handling
    SentryService.captureException(error, stackTrace);
  });
}

class KashKashApp extends ConsumerWidget {
  const KashKashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Kash-Kash',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
