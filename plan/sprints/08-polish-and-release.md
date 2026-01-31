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

### S8-T4: Widget Tests
**Type**: test
**Dependencies**: All features

**Description**:
Widget tests for critical UI components. Note: Unit tests should already be written in earlier sprints. This task focuses on widget/UI tests.

**Acceptance Criteria**:
- [ ] LoginScreen: loading, error, success states
- [ ] QuestListScreen: empty, loading, populated states
- [ ] QuestCard: renders correctly with data
- [ ] GameBackground: correct colors for each state
- [ ] HistoryCard: displays attempt info correctly
- [ ] WinOverlay: shows stats and animation

**Test structure**:
```
test/widget/
├── screens/
│   ├── login_screen_test.dart
│   ├── quest_list_screen_test.dart
│   ├── active_quest_screen_test.dart
│   └── quest_history_screen_test.dart
└── widgets/
    ├── quest_card_test.dart
    ├── game_background_test.dart
    ├── win_overlay_test.dart
    └── history_card_test.dart
```

**Example test**:
```dart
testWidgets('GameBackground shows red when getting closer', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameBackground(state: GameplayState.gettingCloser),
    ),
  );

  final container = tester.widget<AnimatedContainer>(
    find.byType(AnimatedContainer),
  );
  expect((container.decoration as BoxDecoration).color, AppColors.red);
});
```

**Commands**:
```bash
flutter test --coverage
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

## Human Testing & QA Tasks

### S8-T11: Full Regression Test
**Type**: qa
**Dependencies**: All previous sprints

**Description**:
Complete end-to-end testing of all features.

**Checklist**:

**Authentication**:
- [ ] Sign in with Google (new account)
- [ ] Sign in with Google (existing account)
- [ ] Session persists across app restart
- [ ] Sign out clears session
- [ ] Offline auth with cached credentials

**Quest List**:
- [ ] List loads with distances
- [ ] Distance filter tabs work (2, 5, 10, 20 km)
- [ ] Pull-to-refresh fetches new data
- [ ] Works offline with cached quests
- [ ] Empty state when no quests nearby

**Gameplay**:
- [ ] Start quest shows black screen
- [ ] Walking toward target → RED
- [ ] Walking away from target → BLUE
- [ ] Standing still → BLACK
- [ ] Win detection at ~3m
- [ ] Win overlay shows correct stats
- [ ] Abandon with confirmation works
- [ ] Screen stays awake during play

**History**:
- [ ] Completed quests appear
- [ ] Abandoned quests appear
- [ ] Filters work correctly
- [ ] Stats displayed correctly

**Admin** (as admin user):
- [ ] Create quest with map picker
- [ ] Edit existing quest
- [ ] Delete quest with confirmation
- [ ] Publish/unpublish toggle
- [ ] Non-admin blocked from admin routes

**Sync**:
- [ ] Offline changes sync when online
- [ ] Sync status indicator works
- [ ] Manual sync trigger works

**Error Handling**:
- [ ] Network errors show friendly messages
- [ ] GPS errors handled gracefully
- [ ] App recovers from errors without crash

---

### S8-T12: Device Matrix Test
**Type**: qa
**Dependencies**: All features

**Description**:
Test on multiple device types and OS versions.

**Device Matrix**:

| Device | OS Version | Status | Notes |
|--------|------------|--------|-------|
| iPhone 15 Pro | iOS 17 | [ ] | |
| iPhone SE (2nd gen) | iOS 16 | [ ] | Small screen |
| iPhone 12 | iOS 15 | [ ] | Minimum supported |
| iPad Air | iPadOS 17 | [ ] | Tablet layout |
| Pixel 8 | Android 14 | [ ] | |
| Samsung Galaxy S21 | Android 13 | [ ] | |
| OnePlus Nord | Android 12 | [ ] | |
| Budget Android | Android 10 | [ ] | Performance check |

**For each device check**:
- [ ] App installs and launches
- [ ] GPS works correctly
- [ ] Performance acceptable (60fps gameplay)
- [ ] UI renders correctly (no overflow/clipping)
- [ ] Text readable on all screen sizes

---

### S8-T13: Accessibility Audit
**Type**: qa
**Dependencies**: S8-T3

**Description**:
Verify app is accessible to users with disabilities.

**Acceptance Criteria**:
- [ ] All interactive elements have semantic labels
- [ ] Screen reader (VoiceOver/TalkBack) can navigate app
- [ ] Color contrast meets WCAG AA guidelines
- [ ] Touch targets minimum 48x48 dp
- [ ] Gameplay states announced to screen reader
- [ ] No information conveyed by color alone

**Tools**:
- iOS: Accessibility Inspector
- Android: Accessibility Scanner
- Manual: Test with VoiceOver/TalkBack enabled

---

### S8-T14: Performance Profiling
**Type**: qa
**Dependencies**: S8-T2

**Description**:
Profile app performance and fix any issues.

**Acceptance Criteria**:
- [ ] App startup < 3 seconds cold start
- [ ] Quest list scroll at 60fps
- [ ] Gameplay color transitions at 60fps
- [ ] No memory leaks over extended use (30min)
- [ ] Battery drain acceptable (<5% per 15min gameplay)

**Tools**:
- Flutter DevTools (Performance tab)
- Android Studio Profiler
- Xcode Instruments

**Profile scenarios**:
- [ ] App startup
- [ ] Quest list scrolling (50+ items)
- [ ] 15-minute gameplay session
- [ ] Background/foreground cycling

---

### S8-T15: Security Review
**Type**: qa
**Dependencies**: All features

**Description**:
Review app for security vulnerabilities.

**Checklist**:
- [ ] No secrets in git history
- [ ] API keys not in compiled app (use env vars)
- [ ] Tokens stored in secure storage (not SharedPreferences)
- [ ] HTTPS used for all API calls
- [ ] JWT tokens validated correctly
- [ ] No debug logs in release build
- [ ] ProGuard/R8 enabled for Android release

**Tools**:
- `git log -p | grep -i "secret\|password\|key"`
- APK decompilation check

---

### S8-T16: Beta Tester Feedback
**Type**: qa
**Dependencies**: S8-T9

**Description**:
Distribute to beta testers and collect feedback.

**Acceptance Criteria**:
- [ ] Distribute via TestFlight (iOS)
- [ ] Distribute via Internal/Closed Track (Android)
- [ ] Minimum 5 testers complete at least one quest
- [ ] Collect feedback via form or messages
- [ ] Triage and prioritize issues
- [ ] Fix showstopper bugs before public release

**Feedback questions**:
1. Did the app crash? When?
2. Was the color feedback (red/blue/black) clear?
3. How accurate was the win detection?
4. What was confusing or frustrating?
5. What would you improve?
6. Would you recommend this to a friend?

---

### S8-T17: App Store Screenshots
**Type**: qa
**Dependencies**: S8-T7

**Description**:
Capture screenshots for store listings.

**Required screenshots**:

**iPhone 6.5" (required)**:
- [ ] Login screen
- [ ] Quest list with nearby quests
- [ ] Gameplay (red/close state)
- [ ] Win overlay
- [ ] Quest history

**iPhone 5.5" (required)**:
- [ ] Same 5 screenshots

**Android Phone**:
- [ ] Same 5 screenshots

**Optional**:
- [ ] iPad screenshots
- [ ] Android tablet screenshots

---

### S8-T18: CI Coverage Gate
**Type**: infrastructure
**Dependencies**: All test tasks

**Description**:
Enforce test coverage thresholds in CI.

**Acceptance Criteria**:
- [ ] CI fails if Flutter coverage < 70%
- [ ] CI fails if Symfony coverage < 75%
- [ ] Coverage badge in README
- [ ] Coverage report uploaded to Codecov (or similar)

**Implementation**:
```yaml
- name: Check coverage threshold
  run: |
    COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oP '\d+\.\d+')
    echo "Coverage: $COVERAGE%"
    if (( $(echo "$COVERAGE < 70" | bc -l) )); then
      echo "Coverage below 70% threshold!"
      exit 1
    fi
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
- [ ] All automated tests passing (S8-T4, S8-T5, S8-T6)
- [ ] Full regression test passed (S8-T11)
- [ ] Device matrix tested (S8-T12)
- [ ] Accessibility audit passed (S8-T13)
- [ ] Performance profiling done (S8-T14)
- [ ] Security review passed (S8-T15)
- [ ] Beta tester feedback addressed (S8-T16)
- [ ] No critical bugs outstanding
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
- [ ] CI coverage gate enforced (S8-T18)

**Release checklist**:
- [ ] Android AAB uploaded to Play Console
- [ ] iOS archive uploaded to App Store Connect
- [ ] Beta testers notified
- [ ] Store listings complete
- [ ] Screenshots uploaded (S8-T17)
- [ ] Release notes written
- [ ] Version tagged in git

---

## Risk Notes

- App Store review can take 1-7 days
- Google Play review typically faster
- iOS may require additional privacy details
- First release may surface unexpected issues
- Plan for hotfix capability
