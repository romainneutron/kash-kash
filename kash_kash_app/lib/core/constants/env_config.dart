/// Environment configuration loaded from compile-time defines
abstract class EnvConfig {
  /// Sentry DSN for error tracking
  static const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: '',
  );

  /// Environment name (development, staging, production)
  static const environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// API base URL
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Whether we're in production
  static bool get isProduction => environment == 'production';

  /// Whether we're in development
  static bool get isDevelopment => environment == 'development';
}
