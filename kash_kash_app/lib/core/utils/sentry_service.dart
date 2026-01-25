import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service wrapper for Sentry error tracking and performance monitoring
class SentryService {
  static bool _initialized = false;

  /// Initialize Sentry SDK
  static Future<void> init({
    required String dsn,
    required String environment,
    double tracesSampleRate = 1.0,
  }) async {
    if (_initialized || dsn.isEmpty) return;

    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.environment = environment;
      options.tracesSampleRate = tracesSampleRate;
      options.attachScreenshot = true;
      options.sendDefaultPii = false;
      options.debug = kDebugMode;

      // Don't send events in debug mode
      if (kDebugMode) {
        options.beforeSend = (event, hint) {
          debugPrint('Sentry would send: ${event.eventId}');
          return null; // Don't send in debug
        };
      }
    });

    _initialized = true;
  }

  /// Capture an exception with optional stack trace and extras
  static Future<void> captureException(
    dynamic exception,
    StackTrace? stackTrace, {
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      debugPrint('Sentry not initialized. Exception: $exception');
      return;
    }

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: extras != null
          ? (scope) {
              scope.setContexts('extras', extras);
            }
          : null,
    );
  }

  /// Capture a message
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extras,
  }) async {
    if (!_initialized) {
      debugPrint('Sentry not initialized. Message: $message');
      return;
    }

    await Sentry.captureMessage(
      message,
      level: level,
      withScope: extras != null
          ? (scope) {
              scope.setContexts('extras', extras);
            }
          : null,
    );
  }

  /// Add a breadcrumb for debugging context
  static void addBreadcrumb(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    if (!_initialized) return;

    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Set user context for error tracking
  static void setUser({
    required String id,
    String? email,
    String? username,
  }) {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        id: id,
        email: email,
        username: username,
      ));
    });
  }

  /// Clear user context (on logout)
  static void clearUser() {
    if (!_initialized) return;

    Sentry.configureScope((scope) {
      scope.setUser(null);
    });
  }

  /// Start a transaction for performance monitoring
  static ISentrySpan? startTransaction(String name, String operation) {
    if (!_initialized) return null;

    return Sentry.startTransaction(
      name,
      operation,
      bindToScope: true,
    );
  }
}
