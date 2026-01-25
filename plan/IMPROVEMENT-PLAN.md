# Kash-Kash Documentation Improvement Plan

Based on comprehensive review of the architecture and sprint files, this plan addresses redundancy, consistency, clarity, and over-engineering issues.

---

## Phase 1: Critical Fixes (Before Development)

### 1.1 Fix Task Numbering in Sprint 1
**Issue**: S1-T10 appears twice (Symfony Bootstrap and Entity Definitions)
**Location**: `sprints/01-project-foundation.md`
**Action**:
- Rename second S1-T10 to S1-T11 (Symfony Entity Definitions)
- Current S1-T12 (Sentry Symfony) becomes S1-T12 (no change needed)
- Update all cross-references in Sprint 2, 8

---

### 1.2 Standardize API Response Format
**Issue**: Inconsistent use of `hydra:member` vs custom `data` wrapper
**Location**: `sprints/03-quest-data-and-list.md`, `ARCHITECTURE.md`
**Decision**: Use API Platform's default `hydra:member` format for standard endpoints
**Action**:
- Remove custom `['data' => $quests]` wrapper from `getNearbyQuests()`
- Simplify Flutter client to expect `hydra:member` only
- Add note to ARCHITECTURE.md: "API Platform JSON-LD format is used for all endpoints"

---

### 1.3 Fix Missing Dependencies
**Issue**: Tasks use code from undeclared dependencies
**Location**: Multiple sprint files
**Actions**:
| Task | Add Dependencies |
|------|-----------------|
| S1-T4 (Drift Schema) | S1-T5 (needs enums) |
| S4-T2 (Path Point DAO) | S3-T6 (DistanceCalculator) |
| S4-T5 (GameStateManager) | S3-T6, S3-T7 |

---

### 1.4 Add Missing Package to Dependencies
**Issue**: `workmanager` package used in S7-T7 but not in S1-T2
**Location**: `sprints/01-project-foundation.md`
**Action**: Add to pubspec.yaml dependencies:
```yaml
workmanager: ^0.5.2
```

---

### 1.5 Fix DistanceFilter Naming Collision
**Issue**: Enum and Riverpod provider both named `DistanceFilter`
**Location**: `sprints/03-quest-data-and-list.md`
**Action**: Rename provider class to `DistanceFilterNotifier` (matches other providers)

---

## Phase 2: Remove Redundancy

### 2.1 Consolidate Sentry Usage Documentation
**Issue**: SentryService patterns repeated in every sprint file
**Location**: All sprint files
**Actions**:
1. Add "Sentry Usage Patterns" section to `ARCHITECTURE.md`:
   ```markdown
   ## Sentry Usage Patterns

   All Sentry calls go through `SentryService` (defined in S1-T9):
   - `SentryService.setUser(user)` - On login
   - `SentryService.clearUser()` - On logout
   - `SentryService.setQuestContext(quest)` - When starting quest
   - `SentryService.addBreadcrumb(message, {category, data})` - Key user actions
   - `SentryService.captureException(e, stackTrace, {extras})` - Error handling
   ```
2. In sprint files, just show the calls inline without re-explaining

---

### 2.2 Consolidate Model Serialization Pattern
**Issue**: `fromJson`/`toJson`/`toDomain()` pattern explained repeatedly
**Location**: Sprints 2, 3, 4, 5
**Action**: Add to ARCHITECTURE.md:
```markdown
## Data Layer Conventions

### Model Serialization
All data models follow this pattern:
- `ModelName.fromJson(Map<String, dynamic>)` - Deserialize from API/storage
- `toJson()` - Serialize for API/storage
- `toDomain()` - Convert to domain entity
- `fromDomain(Entity)` - Convert from domain entity

Domain entities are immutable with `copyWith()`. Data models are mutable.
```

---

### 2.3 Remove Duplicate GPS/Distance Code Comments
**Issue**: DistanceCalculator and GpsService usage explained multiple times
**Location**: Sprints 3, 4
**Action**: Remove redundant comments, rely on dependency references

---

## Phase 3: Improve Clarity

### 3.1 Define GPS Accuracy Behavior
**Issue**: Unclear what happens when GPS accuracy > win radius
**Location**: `sprints/04-core-gameplay.md`
**Action**: Add to S4-T5 GameStateManager:
```dart
// If GPS accuracy is worse than win radius, expand effective radius
// to prevent impossible wins while maintaining challenge
final effectiveRadius = max(quest.radiusMeters, position.accuracy * 0.8);
```
Document this in ARCHITECTURE.md under "Core Game Mechanics".

---

### 3.2 Document Movement Threshold Rationale
**Issue**: Magic numbers 0.5 m/s and smoothingCount = 3 unexplained
**Location**: `sprints/04-core-gameplay.md`, S4-T3
**Action**: Add comments:
```dart
// 0.5 m/s = slow walking speed (normal walking is ~1.4 m/s)
// Lower threshold to detect intentional movement while filtering GPS jitter
static const double defaultThreshold = 0.5;

// Require 3 consecutive readings to change state
// Prevents flickering from momentary GPS glitches
static const int smoothingCount = 3;
```

---

### 3.3 Clarify Background Service Usage
**Issue**: ARCHITECTURE.md says `flutter_background_service`, Sprint 7 uses `workmanager`
**Location**: `ARCHITECTURE.md`, `sprints/07-offline-sync.md`
**Action**: Update ARCHITECTURE.md:
```markdown
### Background Processing
- **workmanager**: Periodic background sync (15min minimum on Android)
- GPS tracking only runs while app is in foreground (battery optimization)
- No `flutter_background_service` needed for MVP
```

---

### 3.4 Clarify SyncQueue vs Per-Entity Synced Flags
**Issue**: SyncQueue table defined but actual sync uses per-entity `synced` flags
**Location**: `sprints/01-project-foundation.md`, `sprints/07-offline-sync.md`
**Decision**: Remove SyncQueue, keep simpler per-entity approach
**Actions**:
1. Remove SyncQueue table from S1-T4
2. Remove S7-T2 (SyncQueueDao)
3. Document that sync uses `synced` boolean on each entity

---

## Phase 4: Define Policies

### 4.1 Error Handling Policy
**Issue**: Inconsistent use of Either<Failure, T> vs exceptions
**Location**: ARCHITECTURE.md (new section)
**Action**: Add to ARCHITECTURE.md:
```markdown
## Error Handling Policy

### Repository Layer
- Operations that can fail: return `Either<Failure, T>`
- Pure local reads: return `Future<T?>` (null = not found)
- Analytics tracking: silent catch, log to Sentry only

### Failure Types
| Type | When |
|------|------|
| NetworkFailure | API unreachable |
| AuthFailure | 401/403, token invalid |
| ValidationFailure | Invalid input |
| CacheFailure | Local DB error |
| ServerFailure | 5xx response |

### Exception Handling
Never throw from repository methods. Catch at repository boundary
and convert to Either.Left(Failure).
```

---

### 4.2 Repository Return Type Policy
**Issue**: Some methods return Either, others don't
**Action**: Standardize in ARCHITECTURE.md:
```markdown
### Repository Return Types
| Method Type | Return Type |
|-------------|-------------|
| Create/Update/Delete | `Future<Either<Failure, T>>` |
| Get by ID | `Future<Either<Failure, T>>` |
| List/Query (local) | `Future<List<T>>` |
| Watch stream | `Stream<List<T>>` |
| Analytics | `Future<void>` (fire and forget) |
```

---

## Phase 5: Simplify for MVP

### 5.1 Defer Detailed Analytics
**Issue**: Full analytics event system is overkill for MVP
**Location**: `sprints/05-history-and-analytics.md`
**Actions**:
1. Keep analytics event table but simplify to:
   - `quest_started`, `quest_completed`, `quest_abandoned` only
   - No custom `event_data` JSON for now
2. Remove S5-T6 (Symfony Analytics Endpoint) - use simple count queries
3. Simplify admin analytics to SQL queries on attempts table
4. Mark full analytics as post-MVP enhancement

---

### 5.2 Defer Path Point Sync
**Issue**: Syncing every GPS point creates data volume
**Location**: `sprints/04-core-gameplay.md`, `sprints/07-offline-sync.md`
**Actions**:
1. Keep local path recording for distance calculation
2. Remove path_points from sync push (S7-T3, S7-T4)
3. Only sync attempt summary (duration, distanceWalked)
4. Mark full path sync as post-MVP (for anti-cheat)

---

### 5.3 Simplify Conflict Resolution Task
**Issue**: S7-T8 mentions UI that won't be built
**Location**: `sprints/07-offline-sync.md`
**Action**: Rename S7-T8 to "Conflict Resolution Strategy", remove UI references, keep just the `last-write-wins` documentation.

---

### 5.4 Remove Over-Detailed Future Features
**Issue**: "Future Architecture Considerations" is too detailed
**Location**: `ARCHITECTURE.md`
**Action**: Replace with brief list:
```markdown
## Future Enhancements (Post-MVP)
- Color saturation based on heading alignment
- Alternative visual modes (pulse, radar)
- User-created quests with moderation
- Adventure courses (multi-quest sequences)
- Full path recording for anti-cheat analysis
- Detailed analytics dashboard
```

---

## Phase 6: Add Missing Pieces

### 6.1 Add Known Limitations Section
**Location**: ARCHITECTURE.md
**Action**: Add section:
```markdown
## MVP Limitations
- No pagination for quest/history lists (limits ~100 items)
- GPS tracking only in foreground
- No offline map tiles (requires network for map picker)
- Simple analytics (counts only, no custom events)
- No path data sync (local only for distance calc)
- No rate limiting (add in first maintenance sprint)
```

---

### 6.2 Add Location Permission Denial Flow
**Location**: `sprints/03-quest-data-and-list.md`
**Action**: Add task S3-T8: Location Permission Screen
- Screen explaining why location is required
- Button to open app settings
- Show when permission permanently denied

---

### 6.3 Complete Token Refresh Implementation
**Location**: `sprints/02-authentication.md`
**Action**: Flesh out S2-T3 `refreshToken()` method with:
- Refresh token storage (separate from access token)
- Server-side validation
- Token rotation (new refresh token on each use)

---

### 6.4 Add Database Migration Task
**Location**: `sprints/01-project-foundation.md`
**Action**: Add to S1-T4 acceptance criteria:
- [ ] Schema version tracking
- [ ] Migration callback in Drift
- [ ] Document upgrade path

---

## Execution Order

```
Phase 1 (Critical)  → Phase 2 (Redundancy) → Phase 3 (Clarity)
                    ↓
Phase 4 (Policies)  → Phase 5 (Simplify)   → Phase 6 (Missing)
```

### Estimated Changes by File

| File | Changes |
|------|---------|
| ARCHITECTURE.md | +5 sections, refactor future features |
| sprints/01-project-foundation.md | Fix task numbers, add S1-T4 deps, remove SyncQueue |
| sprints/02-authentication.md | Complete token refresh, update deps |
| sprints/03-quest-data-and-list.md | Fix DistanceFilter, add S3-T8 |
| sprints/04-core-gameplay.md | Add GPS accuracy handling, add comments |
| sprints/05-history-and-analytics.md | Simplify analytics scope |
| sprints/06-admin-module.md | Minor Sentry cleanup |
| sprints/07-offline-sync.md | Remove SyncQueue, simplify S7-T8, remove path sync |
| sprints/08-polish-and-release.md | Update task references |

---

## Validation

After implementing these changes:
1. [ ] All task IDs are unique across all sprints
2. [ ] All dependencies reference valid task IDs
3. [ ] No code patterns explained more than once
4. [ ] Error handling policy documented and followed
5. [ ] MVP scope clearly defined with known limitations
6. [ ] All packages in pubspec.yaml that are used
7. [ ] Background processing strategy is clear
