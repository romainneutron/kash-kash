# Sprint 8: Polish & Release

**Goal**: Final polish, comprehensive testing, performance optimization, and deployment preparation.

**Deliverable**: Production-ready app and backend deployed and functional.

**Prerequisites**: Sprint 7 completed (all features working with sync)

---

## Tasks

### S8-T1: Error Handling & Logging
**Type**: infrastructure
**Dependencies**: All previous sprints, S1-T9 (Sentry Flutter Integration)

**Description**:
Ensure comprehensive error handling integrates with Sentry (configured in Sprint 1).

**Acceptance Criteria**:
- [ ] Global error handler captures all uncaught exceptions to Sentry
- [ ] Structured logging with levels
- [ ] Sentry receives all error reports with context
- [ ] User-friendly error messages displayed
- [ ] Debug mode: verbose logging, no Sentry reports

**Implementation**:
```dart
// lib/core/errors/error_handler.dart
// Note: Sentry is already initialized in main.dart (Sprint 1)
// This handler adds additional local logging and context

class ErrorHandler {
  static void init() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _reportError(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack);
      return true;
    };
  }

  static void _reportError(Object error, StackTrace? stack) {
    // Log locally in debug mode
    debugPrint('ERROR: $error');
    if (stack != null) debugPrint('STACK: $stack');

    // Report to Sentry (production only - handled by SentryService)
    SentryService.captureException(error, stack, extras: {
      'handler': 'global_error_handler',
    });
  }
}

// lib/core/utils/logger.dart
enum LogLevel { debug, info, warning, error }

class AppLogger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  static void debug(String message) => _log(LogLevel.debug, message);
  static void info(String message) => _log(LogLevel.info, message);
  static void warning(String message) {
    _log(LogLevel.warning, message);
    SentryService.addBreadcrumb(message, category: 'warning');
  }
  static void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message);
    if (error != null) {
      SentryService.captureException(error, stack, extras: {'message': message});
    }
  }

  static void _log(LogLevel level, String message) {
    if (level.index < _minLevel.index) return;
    final prefix = '[${level.name.toUpperCase()}]';
    debugPrint('$prefix $message');
  }
}
```

---

### S8-T2: Performance Optimization
**Type**: infrastructure
**Dependencies**: All previous sprints

**Description**:
Optimize app performance for smooth gameplay.

**Acceptance Criteria**:
- [ ] Profile and fix jank in gameplay screen
- [ ] Optimize database queries
- [ ] Lazy load screens
- [ ] Image caching
- [ ] Memory leak check

**Implementation**:
```dart
// Optimize GPS updates to not rebuild entire tree
class GameplayOptimizations {
  // Use const widgets where possible
  // Separate position updates from UI updates
  // Use ValueNotifier for high-frequency updates
}

// Database query optimization
class OptimizedQuestDao {
  // Add indexes in Drift
  // Use batch operations
  // Limit query results
}

// Lazy loading with go_router
GoRoute(
  path: '/admin/quests',
  builder: (_, __) => const AdminQuestListScreen(),
  // Preload only when needed
)
```

**Profiling checklist**:
- [ ] Run `flutter run --profile` and use DevTools
- [ ] Check for unnecessary rebuilds
- [ ] Verify 60fps during gameplay
- [ ] Check memory usage over time

---

### S8-T3: Accessibility
**Type**: feature
**Dependencies**: All screens

**Description**:
Ensure app is accessible.

**Acceptance Criteria**:
- [ ] All interactive elements have semantic labels
- [ ] Color contrast meets WCAG guidelines
- [ ] Screen reader compatible
- [ ] Touch targets minimum 48x48

**Implementation**:
```dart
// Add semantics to gameplay screen
Semantics(
  label: 'Gameplay area. ${_getStateDescription(state)}',
  child: GameBackground(state: state),
)

String _getStateDescription(GameplayState state) {
  switch (state) {
    case GameplayState.stationary:
      return 'You are not moving. Start walking to find the target.';
    case GameplayState.gettingCloser:
      return 'You are getting closer to the target!';
    case GameplayState.gettingFarther:
      return 'You are moving away from the target.';
    case GameplayState.won:
      return 'Congratulations! You found the target!';
    default:
      return '';
  }
}
```

---

### S8-T4: Unit & Widget Tests
**Type**: test
**Dependencies**: All features

**Description**:
Comprehensive test coverage.

**Acceptance Criteria**:
- [ ] Domain layer: 80%+ coverage
- [ ] Data layer: 70%+ coverage
- [ ] Critical widgets tested
- [ ] Edge cases covered

**Test structure**:
```
test/
├── unit/
│   ├── domain/
│   │   ├── usecases/
│   │   │   ├── start_quest_test.dart
│   │   │   ├── complete_quest_test.dart
│   │   │   └── ...
│   │   └── entities/
│   ├── data/
│   │   ├── repositories/
│   │   └── datasources/
│   └── core/
│       └── utils/
│           └── distance_calculator_test.dart
├── widget/
│   ├── screens/
│   │   ├── login_screen_test.dart
│   │   ├── quest_list_screen_test.dart
│   │   └── active_quest_screen_test.dart
│   └── widgets/
└── integration/
    └── gameplay_flow_test.dart
```

**Commands**:
```bash
flutter test --coverage
flutter test --coverage --coverage-path=coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

### S8-T5: Integration Tests
**Type**: test
**Dependencies**: All features

**Description**:
End-to-end integration tests.

**Acceptance Criteria**:
- [ ] Full auth flow
- [ ] Quest list and filter
- [ ] Start and complete quest
- [ ] History screen
- [ ] Admin CRUD (if testable)

**Implementation**:
```dart
// integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end tests', () {
    testWidgets('Complete gameplay flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      expect(find.text('Sign in with Google'), findsOneWidget);
      await tester.tap(find.text('Sign in with Google'));
      await tester.pumpAndSettle();

      // Wait for quest list
      expect(find.text('Nearby Quests'), findsOneWidget);

      // Select a quest
      await tester.tap(find.byType(QuestCard).first);
      await tester.pumpAndSettle();

      // Verify gameplay screen
      expect(find.byType(GameBackground), findsOneWidget);

      // Simulate GPS movement would require mocking
    });
  });
}
```

**Run**:
```bash
flutter test integration_test/app_test.dart
```

---

### S8-T6: Backend Tests
**Type**: test
**Dependencies**: Backend features

**Description**:
Symfony backend test coverage.

**Acceptance Criteria**:
- [ ] API endpoint tests
- [ ] Auth flow tests
- [ ] Sync endpoint tests
- [ ] Repository tests

**Implementation**:
```php
// tests/Controller/QuestControllerTest.php
class QuestControllerTest extends ApiTestCase
{
    public function testGetNearbyQuests(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/quests/nearby?lat=48.8566&lng=2.3522&radius=5');

        $this->assertResponseIsSuccessful();
        $this->assertJsonContains(['data' => []]);
    }

    public function testCreateQuestRequiresAdmin(): void
    {
        $client = static::createClient();
        $client->request('POST', '/api/quests', [
            'json' => ['title' => 'Test', 'latitude' => 48.8566, 'longitude' => 2.3522]
        ]);

        $this->assertResponseStatusCodeSame(401);
    }
}
```

**Run**:
```bash
php bin/phpunit
```

---

### S8-T7: App Store Preparation
**Type**: infrastructure
**Dependencies**: All features tested

**Description**:
Prepare for app store submission.

**Acceptance Criteria**:
- [ ] App icons for all sizes
- [ ] Splash screen
- [ ] App name and bundle ID finalized
- [ ] Privacy policy
- [ ] Screenshots for store listing
- [ ] App description

**Assets needed**:
```
assets/
├── icons/
│   ├── app_icon.png (1024x1024)
│   └── app_icon_foreground.png (for adaptive)
├── splash/
│   └── splash.png
└── screenshots/
    ├── iphone_6.5/
    └── android_phone/
```

**Configuration**:
```yaml
# pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icons/app_icon.png"
  adaptive_icon_foreground: "assets/icons/app_icon_foreground.png"
  adaptive_icon_background: "#FFFFFF"

flutter_native_splash:
  color: "#000000"
  image: "assets/splash/splash.png"
```

**Commands**:
```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

### S8-T8: Backend Deployment
**Type**: infrastructure
**Dependencies**: Backend complete, S1-T12 (Sentry Symfony Integration)

**Description**:
Deploy Symfony backend to production with Sentry monitoring.

**Acceptance Criteria**:
- [ ] Production server setup (VPS or PaaS)
- [ ] HTTPS configured
- [ ] Database migrated
- [ ] Environment variables secured (including SENTRY_DSN)
- [ ] Sentry monitoring active and receiving events
- [ ] Performance monitoring enabled (Sentry APM)

**Docker production compose**:
```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  php:
    build:
      context: .
      dockerfile: docker/php/Dockerfile.prod
    environment:
      APP_ENV: prod
      APP_SECRET: ${APP_SECRET}
      DATABASE_URL: ${DATABASE_URL}
      SENTRY_DSN: ${SENTRY_DSN}
    depends_on:
      - db

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./docker/nginx/prod.conf:/etc/nginx/conf.d/default.conf
      - ./certbot/conf:/etc/letsencrypt
    depends_on:
      - php

  db:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data

volumes:
  db_data:
```

**Deployment options**:
- VPS (DigitalOcean, Hetzner): ~$10/month
- Platform.sh: Symfony-optimized
- Railway: Easy deploy from Git

---

### S8-T9: App Build & Release
**Type**: infrastructure
**Dependencies**: S8-T7

**Description**:
Build release versions for stores.

**Acceptance Criteria**:
- [ ] Android release APK/AAB signed
- [ ] iOS archive for App Store
- [ ] Version numbers set
- [ ] Release notes prepared

**Commands**:
```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

**Android signing**:
```properties
# android/key.properties
storePassword=xxx
keyPassword=xxx
keyAlias=upload
storeFile=upload-keystore.jks
```

---

### S8-T10: Documentation
**Type**: documentation
**Dependencies**: All features

**Description**:
Create user and developer documentation.

**Acceptance Criteria**:
- [ ] README with setup instructions
- [ ] API documentation (auto-generated)
- [ ] Developer onboarding guide
- [ ] User FAQ

**Documentation structure**:
```
docs/
├── README.md           # Project overview
├── SETUP.md            # Development setup
├── API.md              # API documentation
├── DEPLOYMENT.md       # Deployment guide
└── FAQ.md              # User FAQ
```

---

## Sprint 8 Validation

**Pre-release checklist**:
- [ ] All tests passing
- [ ] No critical bugs
- [ ] Performance acceptable (60fps gameplay)
- [ ] Offline mode working
- [ ] Sync working reliably
- [ ] App icons and splash screen correct
- [ ] Privacy policy published
- [ ] Backend deployed and reachable
- [ ] HTTPS working
- [ ] Database backups configured
- [ ] Sentry DSN configured for production (both Flutter and Symfony)
- [ ] Sentry alerts configured (Slack/Email for critical errors)
- [ ] Release health monitoring enabled in Sentry

**Release checklist**:
- [ ] Android AAB uploaded to Play Console
- [ ] iOS archive uploaded to App Store Connect
- [ ] Beta testers notified
- [ ] Store listings complete
- [ ] Screenshots uploaded
- [ ] Release notes written

---

## Risk Notes

- App Store review can take 1-7 days
- Google Play review typically faster
- iOS may require additional privacy details
- First release may surface unexpected issues
- Plan for hotfix capability
