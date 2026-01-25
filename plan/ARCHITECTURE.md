# Kash-Kash: Geocaching App Architecture

## Project Overview

Kash-Kash is a mobile geocaching game with a unique twist: players find GPS coordinates without knowing distance or direction. The screen provides feedback only through color changes based on movement - RED when getting closer, BLUE when getting farther, and BLACK when stationary.

### Core Game Mechanics
- **Black Screen**: User is stationary (no GPS movement detected)
- **Red Screen**: User is moving closer to target
- **Blue Screen**: User is moving farther from target
- **Win Condition**: Within 3 meters of target coordinates

### Critical Requirements
- **Offline-First**: Full gameplay without network connectivity
- **Battery Efficient**: Smart GPS polling based on movement detection
- **Cross-Platform**: iOS and Android via Flutter

---

## Technology Stack

### Frontend: Flutter
- **State Management**: Riverpod 2.x with AsyncNotifier pattern
- **Architecture**: Clean Architecture (Presentation -> Domain -> Data layers)
- **Local Database**: Drift (SQLite) - chosen for relational integrity, type safety, and encryption support
- **GPS/Location**: `geolocator` + `flutter_background_service` for background tracking
- **Maps (Admin)**: `flutter_map` with OpenStreetMap tiles
- **HTTP Client**: `dio` with interceptors for auth and caching

### Backend: Symfony 7 + API Platform
**Rationale**:
- Full control over business logic and data model
- PostgreSQL with PostGIS for geospatial queries
- Self-hostable on any VPS (~$10/month)
- No vendor lock-in
- Mature ecosystem with excellent documentation

**Stack**:
- Symfony 7.x
- API Platform 4.x (auto-generated REST API)
- PostgreSQL 16 with PostGIS extension
- LexikJWTAuthenticationBundle (JWT tokens)
- KnpUOAuth2ClientBundle (Google OAuth)
- Doctrine ORM

### Authentication
- Google OAuth via Symfony (KnpUOAuth2ClientBundle)
- JWT tokens (LexikJWTAuthenticationBundle)
- Tokens stored securely on device (flutter_secure_storage)
- Offline session persistence

### Offline Sync Architecture
- Local SQLite (Drift) is source of truth during gameplay
- Background sync when network available
- Sync queue for pending operations
- Last-write-wins conflict resolution (server timestamp)

### Monitoring & Observability

**Error Tracking: Sentry**
- Single platform for both Flutter and Symfony
- Automatic error capture with full context
- Performance monitoring (APM) included
- Self-hostable if costs grow
- Excellent stack traces and breadcrumbs

**What Sentry monitors**:
- App crashes and exceptions (automatic)
- API errors and slow queries (automatic)
- User sessions and context
- Release health and regressions
- Performance traces (sampled)

**Product Analytics: Aptabase**
- Privacy-first, no user identifiers (GDPR/CCPA compliant)
- Self-hostable (AGPLv3) or cloud option
- Official Flutter SDK
- Tracks: sessions, custom events, app versions
- Does NOT track: user identity, retention, MAU (by design)

**What Aptabase tracks**:
- Quest started/completed/abandoned events
- Session counts and durations
- App version distribution
- Basic device info (OS, country)

---

## Architecture Diagram

```
+------------------------------------------------------------------+
|                        FLUTTER APPLICATION                        |
+------------------------------------------------------------------+
|  PRESENTATION LAYER                                               |
|  +------------------+  +------------------+  +------------------+ |
|  |   Auth Module    |  |  Quest Module    |  |  Admin Module    | |
|  |  - LoginScreen   |  |  - QuestList     |  |  - QuestMgmt     | |
|  |  - AuthProvider  |  |  - ActiveQuest   |  |  - MapPicker     | |
|  |                  |  |  - QuestHistory  |  |  - Analytics     | |
|  +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+
|  DOMAIN LAYER (Pure Dart - No Flutter Dependencies)              |
|  +------------------+  +------------------+  +------------------+ |
|  |    Entities      |  |   Repositories   |  |    Use Cases     | |
|  |  - User          |  |   (Interfaces)   |  |  - StartQuest    | |
|  |  - Quest         |  |  - IAuthRepo     |  |  - UpdatePosition| |
|  |  - QuestAttempt  |  |  - IQuestRepo    |  |  - CheckWin      | |
|  |  - Position      |  |  - IAnalyticsRepo|  |  - SyncData      | |
|  |  - AnalyticsEvent|  |  - ISyncRepo     |  |  - CreateQuest   | |
|  +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+
|  DATA LAYER                                                       |
|  +------------------+  +------------------+  +------------------+ |
|  | Local DataSource |  |Remote DataSource |  |  Repositories    | |
|  |  - Drift DB      |  |  - API Client    |  |  (Implementations)|
|  |  - Secure Store  |  |  - Dio + Auth    |  |  - AuthRepoImpl  | |
|  |  - Tile Cache    |  |                  |  |  - QuestRepoImpl | |
|  +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+
|  INFRASTRUCTURE                                                   |
|  +------------------+  +------------------+  +------------------+ |
|  |  GPS Service     |  |  Sync Engine     |  |  Background Svc  | |
|  |  - Location      |  |  - Queue Mgmt    |  |  - Foreground    | |
|  |  - Movement Det. |  |  - Conflict Res. |  |  - Notifications | |
|  |  - Distance Calc |  |  - Retry Logic   |  |                  | |
|  +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+

                              |
                              | HTTPS (REST API)
                              v

+------------------------------------------------------------------+
|                     SYMFONY BACKEND (API Platform)                |
+------------------------------------------------------------------+
|  +------------------+  +------------------+  +------------------+ |
|  |   PostgreSQL     |  |   Auth Service   |  |   API Endpoints  | |
|  |  + PostGIS       |  |  - Google OAuth  |  |  - /api/quests   | |
|  |  - users         |  |  - JWT Tokens    |  |  - /api/attempts | |
|  |  - quests        |  |  - Role-Based    |  |  - /api/sync     | |
|  |  - attempts      |  |                  |  |  - /api/admin/*  | |
|  |  - path_points   |  |                  |  |                  | |
|  +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+

                              |
                              | Errors & Traces
                              v

+------------------------------------------------------------------+
|                           SENTRY                                  |
|  +------------------+  +------------------+  +------------------+ |
|  |  Error Tracking  |  |   Performance    |  |     Alerts       | |
|  |  - Crashes       |  |  - API latency   |  |  - Slack         | |
|  |  - Exceptions    |  |  - DB queries    |  |  - Email         | |
|  |  - Breadcrumbs   |  |  - Traces        |  |  - PagerDuty     | |
|  +------------------+  +------------------+  +------------------+ |
+------------------------------------------------------------------+
```

---

## Data Models

### Entity Relationship Diagram

```
+------------------+       +------------------+       +------------------+
|      users       |       |      quests      |       |  quest_attempts  |
+------------------+       +------------------+       +------------------+
| id (UUID) PK     |       | id (UUID) PK     |       | id (UUID) PK     |
| email            |       | title            |       | quest_id FK      |
| display_name     |       | description      |       | user_id FK       |
| avatar_url       |       | latitude         |       | started_at       |
| role (enum)      |<---+  | longitude        |  +--->| completed_at     |
| created_at       |    |  | radius_meters    |  |    | abandoned_at     |
| updated_at       |    |  | created_by FK ---+  |    | status (enum)    |
+------------------+    |  | published        |  |    | duration_seconds |
                        |  | difficulty       |  |    | distance_walked  |
                        |  | location_type    |  |    | synced           |
                        |  | created_at       |  |    +------------------+
                        |  | updated_at       |  |            |
                        |  +------------------+  |            |
                        |                        |            |
                        +------------------------+            |
                                                              |
                              +------------------+            |
                              |   path_points    |            |
                              +------------------+            |
                              | id (UUID) PK     |            |
                              | attempt_id FK -------------------+
                              | latitude         |
                              | longitude        |
                              | timestamp        |
                              | accuracy         |
                              | speed            |
                              | synced           |
                              +------------------+

Note: Product analytics via Aptabase (external service, no local table)
```

---

## API Endpoints (Symfony + API Platform)

### Authentication
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/auth/google` | Initiate Google OAuth | - |
| GET | `/auth/google/callback` | OAuth callback | - |
| POST | `/api/token/refresh` | Refresh JWT token | JWT |
| GET | `/api/me` | Get current user | JWT |

### Quests
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/quests` | List published quests | JWT |
| GET | `/api/quests/nearby?lat=X&lng=Y&radius=Z` | Nearby quests | JWT |
| GET | `/api/quests/{id}` | Get quest details | JWT |
| POST | `/api/quests` | Create quest | Admin |
| PUT | `/api/quests/{id}` | Update quest | Admin |
| DELETE | `/api/quests/{id}` | Delete quest | Admin |

### Attempts
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/attempts` | List user's attempts | JWT |
| POST | `/api/attempts` | Start new attempt | JWT |
| PUT | `/api/attempts/{id}` | Update attempt (complete/abandon) | JWT |
| POST | `/api/attempts/{id}/path` | Batch upload path points | JWT |

### Analytics
Product analytics handled by Aptabase (external service).
Admin dashboard stats derived from attempts table:
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/admin/stats` | Dashboard stats (derived from attempts) | Admin |

### Sync
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/sync/pull` | Get updated records since timestamp | JWT |
| POST | `/api/sync/push` | Push local changes | JWT |

---

## Screen Definitions

### User Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Login | `/login` | Google Sign-In |
| Quest List | `/quests` | Browse nearby quests with distance filter |
| Active Quest | `/quest/:id/play` | Core gameplay (BLACK/RED/BLUE) |
| Quest History | `/history` | View past attempts |

### Admin Screens

| Screen | Route | Purpose |
|--------|-------|---------|
| Admin Quest List | `/admin/quests` | Manage all quests |
| Quest Editor | `/admin/quests/new` | Create quest with map |
| Quest Editor | `/admin/quests/:id/edit` | Edit existing quest |
| Analytics Dashboard | `/admin/analytics` | View stats |

---

## Folder Structure

### Flutter App
```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── extensions/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/
│   ├── datasources/
│   │   ├── local/
│   │   └── remote/
│   ├── models/
│   └── repositories/
├── infrastructure/
│   ├── gps/
│   ├── sync/
│   └── background/
├── presentation/
│   ├── providers/
│   ├── screens/
│   ├── widgets/
│   └── theme/
└── router/
```

### Symfony Backend
```
backend/
├── config/
│   ├── packages/
│   │   ├── api_platform.yaml
│   │   ├── doctrine.yaml
│   │   ├── lexik_jwt_authentication.yaml
│   │   └── knpu_oauth2_client.yaml
│   └── routes.yaml
├── src/
│   ├── Controller/
│   │   ├── AuthController.php
│   │   ├── SyncController.php
│   │   └── AnalyticsController.php
│   ├── Entity/
│   │   ├── User.php
│   │   ├── Quest.php
│   │   ├── QuestAttempt.php
│   │   ├── PathPoint.php
│   │   └── AnalyticsEvent.php
│   ├── Repository/
│   ├── Security/
│   │   ├── GoogleAuthenticator.php
│   │   └── JwtAuthenticator.php
│   ├── Service/
│   │   ├── GeoService.php
│   │   └── AnalyticsService.php
│   └── State/
│       └── QuestStateProcessor.php
├── migrations/
└── docker/
    └── docker-compose.yml
```

---

## Sprint Overview

| Sprint | Name | Goal |
|--------|------|------|
| 1 | [Project Foundation](sprints/01-project-foundation.md) | Flutter skeleton + Symfony bootstrap |
| 2 | [Authentication](sprints/02-authentication.md) | Google OAuth on both ends |
| 3 | [Quest Data & List](sprints/03-quest-data-and-list.md) | Quest CRUD + offline list |
| 4 | [Core Gameplay](sprints/04-core-gameplay.md) | GPS tracking + color feedback |
| 5 | [History & Analytics](sprints/05-history-and-analytics.md) | Attempt history + event tracking |
| 6 | [Admin Module](sprints/06-admin-module.md) | Quest creation with map |
| 7 | [Offline Sync](sprints/07-offline-sync.md) | Bidirectional sync engine |
| 8 | [Polish & Release](sprints/08-polish-and-release.md) | Testing + deployment |

---

## Future Enhancements (Post-MVP)

Brief ideas for future development (not designed in detail):

- **Color saturation**: Vary intensity based on heading alignment with target
- **Alternative visual modes**: Pulsing, radar/compass, accessibility options
- **User-created quests**: With visibility controls and moderation
- **Adventure courses**: Multi-quest sequences with leaderboards
- **White-label**: Theming and tenant isolation for B2B
- **Auto-difficulty**: ML classification based on completion data

---

## Open Questions

1. **GPS Accuracy**: Is 3-meter win radius achievable? May need to adjust based on real-world testing.
2. **Background Tracking**: How long can GPS run in background on iOS without being killed?
3. **Cheating Prevention**: How to detect GPS spoofing? (Path analysis, speed checks)
4. **Battery Optimization**: Acceptable battery drain percentage per hour of gameplay?

---

## MVP Limitations

The following are known limitations for the initial release:

- **No pagination** for quest/history lists (practical limit ~100 items)
- **GPS tracking only in foreground** - no background gameplay
- **No offline map tiles** - map picker requires network
- **Simple admin stats** - counts from attempts table, no detailed event analytics
- **No rate limiting** - add in first maintenance sprint
- **Last-write-wins sync** - no manual conflict resolution UI
- **No user-created quests** - admin-only quest creation

---

## Definition of Done (Phase 1)

- [ ] User can sign in with Google
- [ ] User can see nearby quests (2km, 5km, 10km, 20km filters)
- [ ] User can start a quest and see color feedback
- [ ] User can win when within 3m of target
- [ ] User can abandon a quest
- [ ] User can view quest history
- [ ] Admin can create quests via map interface
- [ ] Admin can see basic analytics (plays, wins, abandonment rate)
- [ ] All features work offline
- [ ] Data syncs when online
- [ ] Works on iOS and Android
