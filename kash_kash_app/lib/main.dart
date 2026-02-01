import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics_service.dart';
import 'core/constants/env_config.dart';
import 'core/utils/sentry_service.dart';
import 'core/utils/web_auth_handler.dart';
import 'presentation/theme/app_theme.dart';
import 'router/app_router.dart';

/// Stores web OAuth tokens extracted before app starts (cleared after use)
Map<String, String>? pendingWebAuthTokens;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // IMPORTANT: Extract web OAuth tokens BEFORE go_router initializes
    // This prevents go_router from trying to parse the fragment as a route
    pendingWebAuthTokens = getAuthTokensFromUrl();
    if (pendingWebAuthTokens != null) {
      clearAuthFragment();
    }

    // Initialize Sentry for error tracking
    await SentryService.init(
      dsn: EnvConfig.sentryDsn,
      environment: EnvConfig.environment,
    );

    // Initialize Aptabase for privacy-first analytics
    await AnalyticsService.init(appKey: EnvConfig.aptabaseKey);

    // Track app opened
    AnalyticsService.appOpened();

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
