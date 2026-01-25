# Kash-Kash: Testing & CI/CD Plan

## Overview

This document outlines the testing strategy and CI/CD pipeline for Kash-Kash, ensuring high confidence in code quality before deployment.

**Deployment targets**:
- **Backend (Symfony)**: Upsun (Platform.sh)
- **Mobile (Flutter)**: Google Play Store + Apple App Store

**Versioning**: CalVer (`YYYY.MM.DD.BUILD`)

**Release philosophy**: Release soon, release often

---

## Part 1: Testing Strategy

### 1.1 Testing Pyramid

```
                    /\
                   /  \
                  / E2E \        <- Few, slow, high confidence
                 /--------\
                /  Widget  \     <- Medium amount, moderate speed
               /------------\
              /    Unit      \   <- Many, fast, focused
             /________________\
```

### 1.2 Coverage Targets

| Layer | Target | Rationale |
|-------|--------|-----------|
| Domain (entities, use cases) | 90%+ | Pure business logic, easy to test |
| Data (repositories, models) | 80%+ | Critical data handling |
| Infrastructure (GPS, sync) | 70%+ | Harder to test, use mocks |
| Presentation (providers) | 70%+ | State management logic |
| Widgets | 50%+ | Key user flows only |
| Integration/E2E | Key flows | Login, gameplay, history |

---

## Part 2: Flutter Testing

### 2.1 Unit Tests

**What to test**:
- Domain entities (validation, copyWith)
- Use cases (StartQuest, CompleteQuest, AbandonQuest)
- Distance calculator (Haversine formula)
- Movement detector (threshold logic)
- Direction detector (closer/farther logic)

**Example structure**:
```
test/
├── unit/
│   ├── domain/
│   │   ├── entities/
│   │   │   └── quest_test.dart
│   │   └── usecases/
│   │       ├── start_quest_test.dart
│   │       ├── complete_quest_test.dart
│   │       └── abandon_quest_test.dart
│   ├── core/
│   │   └── utils/
│   │       └── distance_calculator_test.dart
│   └── infrastructure/
│       ├── movement_detector_test.dart
│       └── direction_detector_test.dart
```

**Tools**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0  # Simpler than mockito, no codegen
  fake_async: ^1.3.0  # For time-based testing
```

### 2.2 Widget Tests

**What to test**:
- Login screen states (loading, error, success)
- Quest list rendering and filtering
- Game background color changes
- Win overlay display
- History screen with filters

**Example**:
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
  expect(container.decoration, hasColor(AppColors.red));
});
```

### 2.3 Integration Tests

**What to test**:
- Full authentication flow (mocked OAuth)
- Quest selection → gameplay → win
- Quest selection → gameplay → abandon
- Offline mode with cached data
- Sync after coming online

**Structure**:
```
integration_test/
├── auth_flow_test.dart
├── gameplay_flow_test.dart
├── offline_mode_test.dart
└── app_test.dart  # Full smoke test
```

**Tools**:
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  patrol: ^3.0.0  # Optional: better native interaction
```

### 2.4 Mocking Strategy

| Dependency | Mock Approach |
|------------|---------------|
| API Client | `MockApiClient` with predefined responses |
| GPS Service | `FakeGpsService` emitting fake positions |
| Secure Storage | In-memory `FakeSecureStorage` |
| Connectivity | `FakeConnectivityService` (online/offline toggle) |
| Database | Drift in-memory database |

---

## Part 3: Symfony Testing

### 3.1 Test Types

| Type | Tool | Purpose |
|------|------|---------|
| Unit | PHPUnit | Services, utilities |
| Functional | PHPUnit + WebTestCase | Controllers, API endpoints |
| Integration | PHPUnit + Doctrine | Repository queries |

### 3.2 Coverage Targets

| Layer | Target |
|-------|--------|
| Controllers | 80%+ |
| Services | 90%+ |
| Repositories | 80%+ |
| Entities | 70%+ (validation) |

### 3.3 Test Structure

```
tests/
├── Unit/
│   ├── Service/
│   │   └── GeoServiceTest.php
│   └── Util/
│       └── DistanceCalculatorTest.php
├── Functional/
│   ├── Controller/
│   │   ├── AuthControllerTest.php
│   │   ├── QuestControllerTest.php
│   │   └── SyncControllerTest.php
│   └── Api/
│       └── QuestApiTest.php
└── Integration/
    └── Repository/
        └── QuestRepositoryTest.php
```

### 3.4 API Testing

```php
class QuestControllerTest extends ApiTestCase
{
    public function testGetNearbyQuestsRequiresAuth(): void
    {
        $client = static::createClient();
        $client->request('GET', '/api/quests/nearby?lat=48.8&lng=2.3');
        $this->assertResponseStatusCodeSame(401);
    }

    public function testGetNearbyQuestsReturnsQuests(): void
    {
        $client = static::createClient();
        $client->loginUser($this->getTestUser());
        $client->request('GET', '/api/quests/nearby?lat=48.8&lng=2.3&radius=5');

        $this->assertResponseIsSuccessful();
        $this->assertJsonContains(['hydra:member' => []]);
    }
}
```

---

## Part 4: CI/CD Pipeline

### 4.1 Pipeline Overview

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Commit    │───▶│    Test     │───▶│    Build    │───▶│   Deploy    │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                         │                   │                   │
                    ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
                    │ Lint    │         │ Flutter │         │ Upsun   │
                    │ Unit    │         │ APK/IPA │         │ (auto)  │
                    │ Widget  │         │ Symfony │         │         │
                    │ Backend │         │ (Upsun) │         │ Stores  │
                    └─────────┘         └─────────┘         │ (manual)│
                                                            └─────────┘
```

### 4.2 GitHub Actions Workflows

#### Option A: Separate Workflows (Recommended)

**Pros**:
- Clear separation of concerns
- Can run in parallel
- Easier to debug failures
- Can have different triggers

**Cons**:
- More files to maintain
- Slightly more complex setup

```
.github/workflows/
├── flutter-ci.yml         # Flutter lint, test, build
├── symfony-ci.yml         # Symfony lint, test
├── flutter-internal.yml   # Daily internal releases (on merge to main)
├── flutter-beta.yml       # Scheduled beta promotion (Mon/Wed/Fri)
├── flutter-production.yml # Manual production release
└── upsun-deploy.yml       # Backend deployment (or auto via integration)
```

#### Option B: Monorepo Workflow

**Pros**:
- Single file to maintain
- Unified view of pipeline status

**Cons**:
- Long running workflows
- All-or-nothing runs
- Harder to parallelize

```
.github/workflows/
└── ci-cd.yml  # Everything in one file
```

**Recommendation**: **Option A** - Separate workflows for clarity and parallelization.

---

### 4.3 Flutter CI Workflow

```yaml
# .github/workflows/flutter-ci.yml
name: Flutter CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'mobile/**'
      - '.github/workflows/flutter-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'mobile/**'

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get
        working-directory: mobile

      - name: Analyze code
        run: flutter analyze --fatal-infos
        working-directory: mobile

      - name: Check formatting
        run: dart format --set-exit-if-changed .
        working-directory: mobile

  test:
    runs-on: ubuntu-latest
    needs: analyze
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Install dependencies
        run: flutter pub get
        working-directory: mobile

      - name: Run tests with coverage
        run: flutter test --coverage
        working-directory: mobile

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oP '\d+\.\d+')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 70" | bc -l) )); then
            echo "Coverage below 70% threshold!"
            exit 1
          fi
        working-directory: mobile

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: mobile/coverage/lcov.info
          flags: flutter

  build-android:
    runs-on: ubuntu-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Build APK
        run: flutter build apk --release
        working-directory: mobile

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: app-release.apk
          path: mobile/build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    runs-on: macos-latest
    needs: test
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'
          cache: true

      - name: Build iOS (no signing)
        run: flutter build ios --release --no-codesign
        working-directory: mobile
```

### 4.4 Symfony CI Workflow

```yaml
# .github/workflows/symfony-ci.yml
name: Symfony CI

on:
  push:
    branches: [main, develop]
    paths:
      - 'backend/**'
      - '.github/workflows/symfony-ci.yml'
  pull_request:
    branches: [main, develop]
    paths:
      - 'backend/**'

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgis/postgis:16-3.4
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: kash_kash_test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: pdo_pgsql, intl
          coverage: xdebug

      - name: Install dependencies
        run: composer install --prefer-dist --no-progress
        working-directory: backend

      - name: Run PHPStan
        run: vendor/bin/phpstan analyse src --level=6
        working-directory: backend

      - name: Run PHP CS Fixer
        run: vendor/bin/php-cs-fixer fix --dry-run --diff
        working-directory: backend

      - name: Run tests with coverage
        run: |
          php bin/console doctrine:database:create --env=test --if-not-exists
          php bin/console doctrine:migrations:migrate --env=test --no-interaction
          vendor/bin/phpunit --coverage-clover coverage.xml
        working-directory: backend
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/kash_kash_test

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v4
        with:
          files: backend/coverage.xml
          flags: symfony
```

### 4.5 Upsun Deployment

#### Option A: Native Upsun GitHub Integration (Recommended)

**How it works**: Upsun automatically deploys when you push to GitHub. Each PR gets a preview environment.

**Pros**:
- Zero GitHub Actions config for deployment
- Automatic preview environments per PR
- Built-in rollback
- Symfony-optimized

**Cons**:
- Less control over deployment timing
- Tied to Upsun platform

**Setup**:
```bash
# Install Upsun CLI
curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash

# Initialize project
cd backend
upsun project:init

# Connect GitHub
upsun integration:add --type=github --repository=your-org/kash-kash
```

**Upsun config** (`.upsun/config.yaml`):
```yaml
applications:
  backend:
    source:
      root: backend
    type: php:8.3

    build:
      flavor: composer

    hooks:
      build: |
        set -e
        symfony-build
      deploy: |
        set -e
        symfony-deploy

    web:
      locations:
        "/":
          root: "public"
          passthru: "/index.php"

    relationships:
      database: "db:postgresql"

services:
  db:
    type: postgresql:16
    disk: 1024
    configuration:
      extensions:
        - postgis
```

#### Option B: GitHub Actions Triggered Deployment

**Pros**:
- Full control over when deployments happen
- Can add manual approval gates
- Unified pipeline visibility

**Cons**:
- More config to maintain
- Need to manage Upsun CLI in Actions

```yaml
# .github/workflows/upsun-deploy.yml
name: Deploy to Upsun

on:
  push:
    branches: [main]
    paths:
      - 'backend/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [test]  # Require tests to pass

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Upsun CLI
        run: |
          curl -fsSL https://raw.githubusercontent.com/platformsh/cli/main/installer.sh | bash
          echo "$HOME/.upsun/bin" >> $GITHUB_PATH

      - name: Deploy to Upsun
        run: |
          upsun push --target=main
        env:
          UPSUN_CLI_TOKEN: ${{ secrets.UPSUN_CLI_TOKEN }}
```

**Recommendation**: **Option A** (Native Integration) - simpler, Symfony-optimized, automatic preview environments.

---

### 4.6 Mobile Release Workflows

#### Daily Internal Release (on merge to main)

```yaml
# .github/workflows/flutter-internal.yml
name: Flutter Internal Release

on:
  push:
    branches: [main]
    paths:
      - 'mobile/**'

jobs:
  version:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.calver.outputs.version }}
      build_number: ${{ steps.calver.outputs.build_number }}
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate CalVer
        id: calver
        run: |
          DATE=$(date +%Y.%-m.%-d)
          BUILD_DATE=$(date +%Y%m%d)
          LAST_BUILD=$(git tag -l "${DATE}.*" 2>/dev/null | sort -V | tail -1 | grep -oP '\d+$' || echo 0)
          BUILD_NUM=$((LAST_BUILD + 1))
          echo "version=${DATE}.${BUILD_NUM}" >> $GITHUB_OUTPUT
          echo "build_number=${BUILD_DATE}$(printf '%03d' $BUILD_NUM)" >> $GITHUB_OUTPUT

  release-android-internal:
    runs-on: ubuntu-latest
    needs: version
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Update version
        run: |
          sed -i "s/^version:.*/version: ${{ needs.version.outputs.version }}+${{ needs.version.outputs.build_number }}/" pubspec.yaml
        working-directory: mobile

      - name: Decode keystore
        run: echo "${{ secrets.ANDROID_KEYSTORE }}" | base64 -d > android/app/upload-keystore.jks
        working-directory: mobile

      - name: Build AAB
        run: flutter build appbundle --release
        working-directory: mobile
        env:
          ANDROID_KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          ANDROID_KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}

      - name: Upload to Play Store (Internal)
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}
          packageName: com.kashkash.app
          releaseFiles: mobile/build/app/outputs/bundle/release/app-release.aab
          track: internal

  release-ios-testflight:
    runs-on: macos-latest
    needs: version
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.0'

      - name: Update version
        run: |
          sed -i '' "s/^version:.*/version: ${{ needs.version.outputs.version }}+${{ needs.version.outputs.build_number }}/" pubspec.yaml
        working-directory: mobile

      - name: Install certificates
        uses: apple-actions/import-codesign-certs@v2
        with:
          p12-file-base64: ${{ secrets.IOS_CERTIFICATE }}
          p12-password: ${{ secrets.IOS_CERTIFICATE_PASSWORD }}

      - name: Build IPA
        run: flutter build ipa --release --export-options-plist=ios/ExportOptions.plist
        working-directory: mobile

      - name: Upload to TestFlight
        uses: apple-actions/upload-testflight-build@v1
        with:
          app-path: mobile/build/ios/ipa/*.ipa
          issuer-id: ${{ secrets.APP_STORE_ISSUER_ID }}
          api-key-id: ${{ secrets.APP_STORE_API_KEY_ID }}
          api-private-key: ${{ secrets.APP_STORE_API_KEY }}

  tag-release:
    runs-on: ubuntu-latest
    needs: [version, release-android-internal, release-ios-testflight]
    steps:
      - uses: actions/checkout@v4
      - name: Create tag
        run: |
          git tag "${{ needs.version.outputs.version }}"
          git push origin "${{ needs.version.outputs.version }}"
```

#### Scheduled Beta Release (Mon/Wed/Fri)

```yaml
# .github/workflows/flutter-beta.yml
name: Flutter Beta Release

on:
  schedule:
    - cron: '0 10 * * 1,3,5'  # Mon/Wed/Fri at 10:00 UTC
  workflow_dispatch:

jobs:
  promote-to-beta:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install fastlane
        run: gem install fastlane

      - name: Promote Android internal → beta
        run: |
          fastlane supply \
            --track internal \
            --track_promote_to beta \
            --package_name com.kashkash.app \
            --json_key_data '${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}'
```

#### Production Release (Manual)

```yaml
# .github/workflows/flutter-production.yml
name: Flutter Production Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version tag to promote (e.g., 2026.1.24.1)'
        required: true

jobs:
  promote-to-production:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.version }}

      - name: Install fastlane
        run: gem install fastlane

      - name: Promote Android beta → production
        run: |
          fastlane supply \
            --track beta \
            --track_promote_to production \
            --rollout 0.1 \
            --package_name com.kashkash.app \
            --json_key_data '${{ secrets.GOOGLE_PLAY_SERVICE_ACCOUNT }}'

      # iOS requires manual App Store submission or use fastlane deliver
```

---

## Part 5: Quality Gates

### 5.1 PR Requirements

| Check | Required | Threshold |
|-------|----------|-----------|
| Flutter analyze | Yes | No errors, no warnings |
| Flutter tests | Yes | All passing |
| Flutter coverage | Yes | ≥70% overall |
| Symfony PHPStan | Yes | Level 6, no errors |
| Symfony tests | Yes | All passing |
| Symfony coverage | Yes | ≥75% overall |
| Code formatting | Yes | No changes needed |

### 5.2 Branch Protection Rules

```
main:
  - Require PR reviews: 1
  - Require status checks: flutter-ci, symfony-ci
  - Require branches up to date
  - No force push

develop:
  - Require status checks: flutter-ci, symfony-ci
  - No force push
```

---

## Part 6: Decisions Needed

### Decision 1: Monorepo vs Separate Repos

| Option | Pros | Cons |
|--------|------|------|
| **Monorepo** (recommended) | Single PR for full features, easier atomic changes, shared CI config | Larger repo, need path filters |
| **Separate repos** | Clear separation, independent versioning | Multiple PRs per feature, harder to sync |

**Recommendation**: Monorepo with path-based CI triggers.

### Decision 2: Coverage Tool

| Option | Pros | Cons |
|--------|------|------|
| **Codecov** (recommended) | PR comments, trend tracking, free for OSS | External service |
| **Local lcov only** | No external dependency | No trending, manual checks |
| **SonarCloud** | More metrics (security, duplication) | More complex setup |

**Recommendation**: Codecov for visibility + PR integration.

### Decision 3: Integration Test Environment

| Option | Pros | Cons |
|--------|------|------|
| **Mocked** (recommended for CI) | Fast, deterministic, no infra needed | Less realistic |
| **Real backend** | Realistic | Slow, flaky, needs backend running |
| **Upsun preview env** | Real environment per PR | Slower, costs |

**Recommendation**: Mocked for CI, real backend for nightly/release testing.

### Decision 4: Mobile Release Process

**Decision**: Multi-track continuous deployment with CalVer.

---

## Part 7: Versioning & Release Cadence

### 7.1 CalVer Format

```
Version: YYYY.MM.DD.BUILD
Build number: YYYYMMDDNNN (for app stores)

Examples:
- 2026.01.24.1  → Build 20260240001 (first build of the day)
- 2026.01.24.2  → Build 20260240002 (second build of the day)
- 2026.01.25.1  → Build 20260250001 (next day)
```

**In pubspec.yaml**:
```yaml
version: 2026.1.24+20260124001  # version+buildNumber
```

### 7.2 Release Cadence

| Track | Platform | Cadence | Trigger | Purpose |
|-------|----------|---------|---------|---------|
| Internal | Play Store | Daily | Merge to main | Dev/QA testing |
| TestFlight Internal | App Store | Daily | Merge to main | Dev/QA testing |
| Closed Beta | Play Store | 2-3x/week | Scheduled | Early adopters |
| TestFlight External | App Store | 2-3x/week | Scheduled | Early adopters |
| Production | Both | Weekly/Bi-weekly | Manual | Stable releases |

### 7.3 Store Constraints

**Google Play Store**:
- Internal track: Instant (no review)
- Closed/Open beta: Usually instant or within hours
- Production: Typically 1-3 hours review
- **Daily releases: Fully possible**

**Apple App Store**:
- TestFlight Internal: Instant (up to 100 testers)
- TestFlight External: First build needs ~24h review, subsequent often instant
- App Store: 24-48 hours typical review time
- **Daily releases: Only via TestFlight, production is weekly realistic**

### 7.4 Versioning Script

```bash
#!/bin/bash
# scripts/calver.sh - Generate CalVer version

DATE=$(date +%Y.%-m.%-d)
BUILD_DATE=$(date +%Y%m%d)

# Get build number for today (increment if exists)
LAST_BUILD=$(git tag -l "${DATE}.*" | sort -V | tail -1 | grep -oP '\d+$' || echo 0)
BUILD_NUM=$((LAST_BUILD + 1))

VERSION="${DATE}.${BUILD_NUM}"
BUILD_NUMBER="${BUILD_DATE}$(printf '%03d' $BUILD_NUM)"

echo "VERSION=${VERSION}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "PUBSPEC_VERSION=${VERSION}+${BUILD_NUMBER}"
```

---

## Part 8: Implementation Sprint

Add these tasks to Sprint 1 (Foundation):

### S1-T13: Flutter Test Infrastructure
- [ ] Add test dependencies (mocktail, fake_async)
- [ ] Create mock/fake classes for GPS, API, Storage
- [ ] Set up test helpers and fixtures
- [ ] Write example unit test for DistanceCalculator

### S1-T14: Symfony Test Infrastructure
- [ ] Configure PHPUnit with coverage
- [ ] Set up test database configuration
- [ ] Create API test case base class
- [ ] Write example controller test

### S1-T15: GitHub Actions CI
- [ ] Create flutter-ci.yml workflow
- [ ] Create symfony-ci.yml workflow
- [ ] Set up Codecov integration
- [ ] Configure branch protection rules

### S1-T16: Upsun Configuration
- [ ] Initialize Upsun project
- [ ] Configure `.upsun/config.yaml`
- [ ] Set up GitHub integration
- [ ] Test preview environment deployment

### S1-T17: Mobile Release Infrastructure
- [ ] Create `scripts/calver.sh` versioning script
- [ ] Set up Google Play Console (internal track)
- [ ] Set up App Store Connect (TestFlight)
- [ ] Configure GitHub secrets for signing
- [ ] Create flutter-internal.yml workflow
- [ ] Create flutter-beta.yml workflow
- [ ] Create flutter-production.yml workflow
- [ ] Test internal release pipeline

---

## Sources

- [Upsun Symfony Integration](https://docs.upsun.com/get-started/stacks/symfony/integration.html)
- [Upsun GitHub Integration](https://docs.upsun.com/integrations/source/github.html)
- [Flutter Testing Overview](https://docs.flutter.dev/testing/overview)
- [Flutter Unit Testing Guide 2025](https://www.bacancytechnology.com/blog/flutter-unit-testing)
- [Best Practices for Testing Flutter](https://www.walturn.com/insights/best-practices-for-testing-flutter-applications)
- [Navigating Hard Parts of Flutter Testing](https://dcm.dev/blog/2025/07/30/navigating-hard-parts-testing-flutter-developers)
