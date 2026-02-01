import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/analytics/analytics_service.dart';
import 'core/constants/env_config.dart';
import 'core/utils/sentry_service.dart';
import 'core/utils/web_auth_handler.dart';
import 'infrastructure/storage/secure_storage.dart';
import 'presentation/theme/app_theme.dart';
import 'router/app_router.dart';

/// Stores web OAuth tokens extracted before app starts (cleared after use)
Map<String, String>? pendingWebAuthTokens;

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // IMPORTANT: Extract web OAuth tokens BEFORE go_router initializes
    // This prevents go_router from trying to parse the fragment as a route
    final webAuthTokens = getAuthTokensFromUrl();
    if (webAuthTokens != null) {
      clearAuthFragment();

      // Save tokens to storage BEFORE app starts so auth state is ready
      await _saveWebAuthTokens(webAuthTokens);
      pendingWebAuthTokens = webAuthTokens;
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

/// Save tokens to secure storage before app starts
Future<void> _saveWebAuthTokens(Map<String, String> tokens) async {
  try {
    final storage = SecureStorage();

    final accessToken = tokens['token'];
    final refreshToken = tokens['refresh_token'];
    final userJson = tokens['user'];

    if (accessToken != null && refreshToken != null) {
      await storage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      if (userJson != null) {
        final userData = jsonDecode(userJson) as Map<String, dynamic>;
        await storage.saveUser(userData);
      }
    }
  } catch (e) {
    // Log error but don't crash - auth provider will handle
    debugPrint('Error saving web auth tokens: $e');
  }
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
