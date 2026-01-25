# Kash-Kash: Pre-Launch Considerations

## Overview

This document captures gaps identified in the current plan that require decisions before or shortly after launch. Each item is marked with priority and decision status.

**Decision statuses**:
- `PENDING` - Needs discussion and decision
- `DECIDED` - Decision made, ready to implement
- `DEFERRED` - Explicitly postponed to post-MVP

---

## Part 1: Legal & Compliance

### 1.1 Privacy Policy

**Status**: `PENDING`
**Priority**: BLOCKER (required for app stores)

**Context**:
App stores require a privacy policy URL. Kash-Kash collects:
- Email (via Google OAuth)
- Display name and avatar
- GPS location during gameplay
- Quest attempt history
- Anonymous analytics (Aptabase)

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| **A: Use generator** (Termly, iubenda) | Fast, legally reviewed, auto-updates | Monthly cost (~$10-20/mo), less control |
| **B: Write custom** | Full control, free | Time-consuming, may miss legal nuances |
| **C: Lawyer review** | Most thorough | Expensive ($500-2000), slower |

**Recommendation**: Option A for MVP, Option C before significant user base.

**Decision**: _To be filled_

**Hosting**: Where will the privacy policy live?
- [ ] Dedicated page on marketing site
- [ ] In-app webview
- [ ] GitHub Pages

---

### 1.2 Terms of Service

**Status**: `PENDING`
**Priority**: BLOCKER (required for app stores)

**Context**:
Defines user responsibilities, liability limitations, account termination conditions.

**Key clauses needed**:
- Account termination rights
- Content ownership (quest data)
- Liability disclaimers (GPS accuracy, physical safety)
- Dispute resolution

**Options**: Same as Privacy Policy (generator vs custom vs lawyer)

**Decision**: _To be filled_

---

### 1.3 GDPR Compliance

**Status**: `PENDING`
**Priority**: HIGH (legal requirement in EU)

#### 1.3.1 Right to Deletion

**Context**: Users must be able to delete their account and all associated data.

**Implementation approach**:
```
DELETE /api/me → Deletes user + cascades to attempts, path_points
```

**Questions**:
- [ ] Hard delete or soft delete with retention period?
- [ ] Immediate or queued (24h grace period)?
- [ ] Email confirmation required?

**Decision**: _To be filled_

#### 1.3.2 Right to Data Export

**Context**: Users must be able to export their data in a portable format.

**Implementation approach**:
```
GET /api/me/export → Returns JSON/ZIP with all user data
```

**Questions**:
- [ ] JSON only or include GPX for path data?
- [ ] Immediate download or email link?
- [ ] Include quest details or just references?

**Decision**: _To be filled_

#### 1.3.3 Consent Management

**Context**: Must obtain clear consent for data collection.

**Questions**:
- [ ] Consent during onboarding or implicit via ToS acceptance?
- [ ] Granular consent (analytics separate from core)?
- [ ] Consent withdrawal mechanism?

**Decision**: _To be filled_

---

### 1.4 App Store Age Rating

**Status**: `PENDING`
**Priority**: BLOCKER

**Context**:
Both stores require content rating questionnaires.

**Likely rating**: 4+ (iOS) / Everyone (Android)
- No violence, gambling, adult content
- Location-based gameplay
- User-generated content: NO (admin-only quests in MVP)

**Action**: Complete rating questionnaires during store setup.

---

### 1.5 Location Permission Justification

**Status**: `PENDING`
**Priority**: BLOCKER (iOS requirement)

**Context**:
iOS requires `NSLocationWhenInUseUsageDescription` and `NSLocationAlwaysUsageDescription` with clear justification.

**Draft text**:
```
When In Use: "Kash-Kash needs your location to guide you toward hidden quests. The screen color changes based on whether you're getting closer or farther from the target."

Always (if background): "Kash-Kash uses background location to continue tracking your progress even when the app is minimized."
```

**Questions**:
- [ ] Do we need "Always" permission for MVP? (Currently: NO, foreground only)
- [ ] How to handle if user denies?

**Decision**: _To be filled_

---

## Part 2: User Experience Gaps

### 2.1 Onboarding Flow

**Status**: `PENDING`
**Priority**: HIGH

**Context**:
First-time users need to understand:
1. What the game is
2. How colors work (red = closer, blue = farther, black = stationary)
3. That they need to physically move
4. GPS permission request

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| **A: 3-4 screen tutorial** | Clear, can be skipped | Feels dated, users skip |
| **B: Interactive first quest** | Learning by doing | More complex to build |
| **C: Inline hints on first play** | Contextual, non-intrusive | May miss key info |

**Recommendation**: Option A for MVP (faster to build), consider B post-launch.

**Decision**: _To be filled_

---

### 2.2 Permission Request Flow

**Status**: `PENDING`
**Priority**: HIGH

**Context**:
GPS permission is critical. If denied, app is unusable for gameplay.

**Flow to define**:
```
1. Pre-permission screen explaining WHY (before system prompt)
2. System permission prompt
3. If denied → Explain impact + link to settings
4. If "Ask Next Time" → Re-request on quest start
```

**Questions**:
- [ ] Block app entirely if denied, or allow browsing quests?
- [ ] Show demo mode without real GPS?

**Decision**: _To be filled_

---

### 2.3 Error States & UX Copy

**Status**: `PENDING`
**Priority**: MEDIUM

**Context**:
User-facing error messages need to be helpful, not technical.

**Errors to define**:
| Scenario | Current | Proposed |
|----------|---------|----------|
| No internet (login) | Generic error | "No internet connection. Connect to sign in." |
| No internet (gameplay) | N/A (offline works) | - |
| GPS unavailable | ? | "Unable to get your location. Check GPS settings." |
| GPS poor accuracy | ? | "GPS signal weak. Move to an open area." |
| Quest not found | 404 | "This quest is no longer available." |
| Server error | 500 | "Something went wrong. Please try again." |
| Session expired | 401 | "Session expired. Please sign in again." |

**Action**: Create UX copy document with all user-facing strings.

**Decision**: _To be filled_

---

### 2.4 Accessibility (a11y)

**Status**: `PENDING`
**Priority**: MEDIUM (HIGH for inclusive design)

**Context**:
Core gameplay is visual (colors). This presents accessibility challenges.

**Considerations**:
| Issue | Possible Solution |
|-------|-------------------|
| Color blindness | Add patterns, icons, or haptics alongside colors |
| Screen readers | Announce direction changes ("Getting closer", "Getting farther") |
| Motor impairment | N/A (requires walking) - inherent limitation |
| Low vision | High contrast mode, larger touch targets |

**Questions**:
- [ ] Is accessibility a launch blocker or post-MVP?
- [ ] Minimum viable accessibility features?

**Decision**: _To be filled_

---

### 2.5 Localization (i18n)

**Status**: `PENDING`
**Priority**: LOW (for initial launch)

**Context**:
Initial launch language(s)?

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| **English only** | Fastest | Limits market |
| **English + French** | Your likely market? | More work upfront |
| **Full i18n setup, English only** | Ready for expansion | Slight overhead |

**Recommendation**: Option C - Set up flutter_localizations + intl, but only English for MVP.

**Decision**: _To be filled_

---

### 2.6 Haptic & Sound Feedback

**Status**: `PENDING`
**Priority**: LOW

**Context**:
Could enhance gameplay feel:
- Haptic pulse when direction changes
- Victory sound/vibration on win
- Subtle tick when moving

**Questions**:
- [ ] Include in MVP or defer?
- [ ] Configurable in settings?
- [ ] What about silent/vibrate mode respect?

**Decision**: _To be filled_

---

## Part 3: Operational Gaps

### 3.1 Backup Strategy

**Status**: `PENDING`
**Priority**: HIGH

**Context**:
Upsun provides automatic backups, but strategy needs definition.

**Questions**:
- [ ] Backup frequency? (Daily recommended)
- [ ] Retention period? (7 days? 30 days?)
- [ ] Tested restore procedure?
- [ ] Off-platform backup copy?

**Upsun defaults**:
- Automatic daily backups
- 7-day retention on production
- Can trigger manual backups

**Action**: Document backup/restore procedure in runbook.

**Decision**: _To be filled_

---

### 3.2 Monitoring & Alerting

**Status**: `PENDING`
**Priority**: HIGH

**Context**:
Sentry captures errors, but alerting thresholds not defined.

**Alerts to configure**:
| Alert | Threshold | Channel |
|-------|-----------|---------|
| Error spike | >10 errors/hour | Email |
| New error type | Any new issue | Email |
| API latency | p95 > 2s | Email |
| Auth failures | >20/hour | Email (potential attack) |
| Database connection | Any failure | Email + SMS |

**Questions**:
- [ ] Email only or also Slack/Discord?
- [ ] On-call rotation? (Probably just you initially)
- [ ] PagerDuty/Opsgenie integration?

**Decision**: _To be filled_

---

### 3.3 Log Aggregation

**Status**: `PENDING`
**Priority**: MEDIUM

**Context**:
Where do logs go? How to search them?

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| **Upsun built-in** | Free, integrated | Limited search, short retention |
| **Sentry breadcrumbs** | Already have Sentry | Not full logs |
| **Papertrail/Logtail** | Searchable, alerts | Additional cost |
| **Self-hosted (Loki)** | Full control | Operational burden |

**Recommendation**: Upsun built-in for MVP, add Papertrail if debugging becomes painful.

**Decision**: _To be filled_

---

### 3.4 Incident Runbooks

**Status**: `PENDING`
**Priority**: MEDIUM

**Context**:
What to do when things break?

**Runbooks needed**:
- [ ] Database connection failure
- [ ] API unresponsive
- [ ] High error rate
- [ ] Deployment rollback procedure
- [ ] User reports data loss
- [ ] Suspected security incident

**Action**: Create `docs/runbooks/` directory with procedures.

**Decision**: _To be filled_

---

### 3.5 Database Migration Strategy

**Status**: `PENDING`
**Priority**: HIGH

**Context**:
How to handle schema changes safely?

**Strategy options**:
| Approach | Description |
|----------|-------------|
| **Expand-contract** | Add new → migrate data → remove old |
| **Feature flags** | Toggle between old/new code paths |
| **Maintenance window** | Brief downtime for breaking changes |

**Questions**:
- [ ] Zero-downtime migrations required?
- [ ] Doctrine migrations with Upsun hooks?
- [ ] Rollback strategy for failed migrations?

**Decision**: _To be filled_

---

## Part 4: Security Gaps

### 4.1 Rate Limiting

**Status**: `PENDING` (documented as MVP limitation)
**Priority**: HIGH (post-launch)

**Context**:
Currently no rate limiting. Risk of abuse.

**Endpoints to protect**:
| Endpoint | Limit | Rationale |
|----------|-------|-----------|
| `POST /auth/*` | 10/min | Prevent brute force |
| `GET /api/quests/nearby` | 60/min | Expensive query |
| `POST /api/attempts` | 10/min | Prevent spam |
| `POST /api/sync/*` | 30/min | Large payloads |

**Implementation**: Symfony RateLimiter component

**Decision**: _To be filled_

---

### 4.2 API Security Headers

**Status**: `PENDING`
**Priority**: MEDIUM

**Headers to add**:
```yaml
Strict-Transport-Security: max-age=31536000; includeSubDomains
X-Content-Type-Options: nosniff
X-Frame-Options: DENY
Content-Security-Policy: default-src 'self'
```

**Implementation**: NelmioCorsBundle + Symfony event listener

**Decision**: _To be filled_

---

### 4.3 GPS Spoofing Detection

**Status**: `PENDING` (documented as open question)
**Priority**: MEDIUM

**Context**:
Users could fake GPS to "win" quests without moving.

**Detection approaches**:
| Method | Effectiveness | Effort |
|--------|---------------|--------|
| Speed analysis | Medium | Low |
| Path smoothness | Medium | Medium |
| Mock location flag (Android) | High on Android | Low |
| Accelerometer correlation | High | High |

**Questions**:
- [ ] How important is anti-cheat for MVP?
- [ ] Ban vs. flag suspicious users?
- [ ] Allow "casual mode" without verification?

**Decision**: _To be filled_

---

### 4.4 Secrets Management

**Status**: `PENDING`
**Priority**: HIGH

**Secrets inventory**:
| Secret | Storage Location | Rotation Plan |
|--------|------------------|---------------|
| JWT private key | Upsun env var | Annually |
| Google OAuth credentials | Upsun env var | As needed |
| Database password | Upsun managed | Auto |
| Android keystore | GitHub Secrets | Never (same key) |
| iOS certificates | GitHub Secrets | Annually |
| Aptabase API key | Flutter env | As needed |
| Sentry DSN | Flutter env / Upsun | As needed |

**Questions**:
- [ ] Use Upsun's built-in secrets or external (Vault)?
- [ ] Document rotation procedures?

**Decision**: _To be filled_

---

## Part 5: Launch Readiness

### 5.1 App Store Metadata

**Status**: `PENDING`
**Priority**: BLOCKER

**Required assets**:
| Asset | Spec | Status |
|-------|------|--------|
| App icon | 1024x1024 PNG | [ ] |
| Screenshots (iOS) | 6.5", 5.5" sizes | [ ] |
| Screenshots (Android) | Phone, 7" tablet, 10" tablet | [ ] |
| Feature graphic (Android) | 1024x500 | [ ] |
| App name | 30 chars max | [ ] |
| Short description | 80 chars | [ ] |
| Full description | 4000 chars | [ ] |
| Keywords (iOS) | 100 chars | [ ] |
| Category | Games > Puzzle? Adventure? | [ ] |
| Content rating | Complete questionnaire | [ ] |

**Action**: Create `assets/store/` directory with all assets.

**Decision**: _To be filled_

---

### 5.2 Initial Quest Seeding

**Status**: `PENDING`
**Priority**: HIGH

**Context**:
App is useless without quests. Need initial content.

**Questions**:
- [ ] How many quests for launch? (Suggest: 10-20 in one city)
- [ ] Who creates them? (You? Friends? Hired?)
- [ ] Geographic focus? (One city first?)
- [ ] Quest difficulty distribution?
- [ ] Seeding via admin UI or database script?

**Decision**: _To be filled_

---

### 5.3 Beta Tester Recruitment

**Status**: `PENDING`
**Priority**: MEDIUM

**Context**:
Need real users before public launch.

**Options**:
| Channel | Reach | Quality |
|---------|-------|---------|
| Friends & family | Low | High (honest feedback) |
| Reddit (r/geocaching, r/betatesting) | Medium | Medium |
| Twitter/X | Medium | Variable |
| ProductHunt Ship | Low | High (engaged) |
| BetaList | Medium | Medium |

**Questions**:
- [ ] Target number of beta testers?
- [ ] Beta duration before public launch?
- [ ] Feedback collection mechanism (form, Discord, in-app)?

**Decision**: _To be filled_

---

### 5.4 Feedback Collection

**Status**: `PENDING`
**Priority**: MEDIUM

**Context**:
How will users report bugs or suggest features?

**Options**:
| Option | Pros | Cons |
|--------|------|------|
| Email link | Simple | Unstructured, hard to track |
| In-app form | Low friction | Need to build |
| Discord/Slack community | Engagement | Moderation overhead |
| GitHub Issues (public) | Transparent | Technical barrier |
| Canny/Productboard | Organized, voting | Cost |

**Recommendation**: Email for MVP + consider Discord for community.

**Decision**: _To be filled_

---

### 5.5 Launch Checklist

**Status**: `PENDING`
**Priority**: HIGH

**Pre-launch verification**:
```
[ ] Legal
    [ ] Privacy Policy published and linked
    [ ] Terms of Service published and linked
    [ ] Age rating completed
    [ ] GDPR deletion endpoint works

[ ] Technical
    [ ] Production environment deployed
    [ ] Database backups verified
    [ ] Sentry alerts configured
    [ ] SSL certificate valid
    [ ] All secrets rotated from dev values

[ ] Content
    [ ] Initial quests created and tested
    [ ] App store listings complete
    [ ] Screenshots uploaded
    [ ] Descriptions proofread

[ ] Testing
    [ ] Full app tested on iOS device
    [ ] Full app tested on Android device
    [ ] Offline mode tested
    [ ] Sync tested
    [ ] Edge cases tested (GPS off, poor signal)

[ ] Release
    [ ] Version number set
    [ ] Release notes written
    [ ] Internal testing passed
    [ ] Beta feedback addressed
    [ ] Go/no-go decision made
```

---

## Part 6: Edge Cases

### 6.1 GPS Disabled

**Status**: `PENDING`
**Priority**: HIGH

**Current behavior**: Undefined

**Proposed behavior**:
1. Check GPS status on app launch
2. If disabled → Show explanatory screen with button to settings
3. If disabled during quest → Pause quest, show overlay
4. Resume automatically when GPS re-enabled

**Decision**: _To be filled_

---

### 6.2 Permission Denied

**Status**: `PENDING`
**Priority**: HIGH

**Scenarios**:
| Scenario | Proposed Behavior |
|----------|-------------------|
| Denied on first ask | Show explanation + settings link |
| "Don't ask again" (Android) | Direct to app settings |
| Denied mid-quest | Pause quest, show overlay |
| Reduced accuracy (iOS 14+) | Warn user, may affect gameplay |

**Decision**: _To be filled_

---

### 6.3 Poor GPS Accuracy

**Status**: DECIDED (documented in Sprint 4)
**Priority**: HIGH

**Solution**: Expand effective win radius based on accuracy
```dart
final effectiveRadius = max(quest.radiusMeters, position.accuracy * 0.8);
```

---

### 6.4 Offline Login

**Status**: `PENDING`
**Priority**: MEDIUM

**Context**:
OAuth requires network. What if user opens app offline for first time?

**Proposed behavior**:
- If never logged in → Show "Internet required to sign in"
- If previously logged in → Use cached session (JWT may be expired)
- If JWT expired → Allow offline gameplay, sync when online, refresh token then

**Decision**: _To be filled_

---

### 6.5 Low Battery Mode

**Status**: `PENDING`
**Priority**: LOW

**Context**:
GPS is battery-intensive. Should app adapt?

**Options**:
| Behavior | Impact |
|----------|--------|
| Reduce GPS polling frequency | Less accurate, better battery |
| Show battery warning | User awareness |
| Disable background tracking | Already MVP limitation |
| No change | Consistent experience |

**Decision**: _To be filled_

---

### 6.6 App Backgrounded During Quest

**Status**: DECIDED (MVP limitation)
**Priority**: LOW (post-MVP)

**Current**: GPS tracking only in foreground.

**Future consideration**: Background tracking with foreground service (Android) / background modes (iOS).

---

## Part 7: Developer Experience

### 7.1 Local Development Setup

**Status**: `PENDING`
**Priority**: MEDIUM

**Documentation needed**:
```markdown
# Local Development

## Prerequisites
- Flutter 3.24+
- PHP 8.3+
- PostgreSQL 16 + PostGIS
- Docker (optional)

## Backend Setup
1. Clone repo
2. cd backend && composer install
3. Configure .env.local
4. php bin/console doctrine:database:create
5. php bin/console doctrine:migrations:migrate
6. symfony serve

## Mobile Setup
1. cd mobile && flutter pub get
2. Configure .env (API URL)
3. flutter run

## Running Tests
...
```

**Action**: Create `CONTRIBUTING.md` or `docs/development.md`

**Decision**: _To be filled_

---

### 7.2 Code Style Documentation

**Status**: `PENDING`
**Priority**: LOW

**Current state**:
- Flutter: `flutter analyze` + `dart format`
- Symfony: PHP-CS-Fixer + PHPStan level 6

**Action**: Document in CONTRIBUTING.md

---

## Summary: Decision Priority

### Blockers (must decide before any store submission)
1. Privacy Policy approach
2. Terms of Service approach
3. App Store metadata creation
4. Location permission justification text
5. Age rating completion

### High Priority (must decide before public launch)
1. GDPR deletion implementation
2. Onboarding flow design
3. Permission request flow
4. Initial quest seeding plan
5. Backup strategy confirmation
6. Alerting thresholds
7. Secrets rotation/documentation
8. Launch checklist completion

### Medium Priority (should decide before public launch)
1. GDPR data export
2. Error UX copy
3. Rate limiting implementation
4. GPS spoofing stance
5. Beta tester recruitment
6. Feedback collection mechanism
7. Log aggregation approach
8. Incident runbooks

### Low Priority (can defer to post-MVP)
1. Accessibility features
2. Localization setup
3. Haptic/sound feedback
4. Low battery mode handling

---

## Next Steps

1. Review this document
2. Make decisions on BLOCKER items
3. Create tasks in Sprint 1 or dedicated "Launch Prep" sprint
4. Assign owners and deadlines
