# Kash-Kash: Strategy, Metrics & Growth

## Overview

This document defines success metrics, budget considerations, and user acquisition strategy for Kash-Kash.

---

## Part 1: Success Metrics & KPIs

### 1.1 What Does Success Look Like?

Before tracking metrics, define what success means at each stage:

| Stage | Success Definition |
|-------|-------------------|
| **MVP Launch** | App works, 100+ downloads, core loop validated |
| **Early Traction** | 1,000+ downloads, users complete quests, positive feedback |
| **Product-Market Fit** | 30%+ D7 retention, users request features, organic growth |
| **Growth** | 10,000+ MAU, ready for monetization |
| **Sustainability** | Revenue covers costs, steady user base |

**Your definition**: _Fill in what success means to YOU_

---

### 1.2 Core Metrics to Track

#### Acquisition Metrics

| Metric | Definition | How to Track |
|--------|------------|--------------|
| **Downloads** | Total app installs | App Store Connect / Play Console |
| **Organic vs Paid** | Source of installs | Store analytics |
| **Install → Signup** | % who complete registration | Aptabase event |

#### Engagement Metrics

| Metric | Definition | How to Track |
|--------|------------|--------------|
| **DAU** | Daily Active Users | Aptabase sessions |
| **MAU** | Monthly Active Users | Aptabase sessions |
| **DAU/MAU (Stickiness)** | How often users return | Calculated |
| **Quests Started** | Engagement with core feature | Aptabase: `quest_started` |
| **Quests Completed** | Success rate | Aptabase: `quest_completed` |
| **Session Duration** | Time in app | Aptabase (if tracked) |

#### Retention Metrics

| Metric | Definition | How to Track |
|--------|------------|--------------|
| **D1 Retention** | % returning after 1 day | Aptabase / Store |
| **D7 Retention** | % returning after 7 days | Aptabase / Store |
| **D30 Retention** | % returning after 30 days | Aptabase / Store |

#### Game-Specific Metrics

| Metric | Definition | What It Tells You |
|--------|------------|-------------------|
| **Quest Completion Rate** | Completed / Started | Is the game too hard/easy? |
| **Avg Quest Duration** | Time to complete | Engagement quality |
| **Abandon Rate** | Abandoned / Started | Friction points |
| **Distance Walked** | Avg meters per quest | Physical engagement |

---

### 1.3 Benchmarks to Compare Against

#### Retention Benchmarks (Mobile Games)

| Metric | Poor | Average | Good | Great |
|--------|------|---------|------|-------|
| D1 Retention | <20% | 25% | 30% | 40%+ |
| D7 Retention | <5% | 10% | 15% | 20%+ |
| D30 Retention | <1% | 3% | 5% | 10%+ |

**Context**: Average app loses 77% of users in first 3 days.

**Sources**: [UXCam](https://uxcam.com/blog/mobile-app-retention-benchmarks/), [Udonis](https://www.blog.udonis.co/mobile-marketing/mobile-games/key-mobile-game-metrics)

#### Stickiness Benchmarks (DAU/MAU)

| Category | Typical DAU/MAU |
|----------|-----------------|
| Social/Messaging | 50%+ |
| Gaming | 20-30% |
| Entertainment | 10-20% |
| E-commerce | ~10% |

**Good target for Kash-Kash**: 15-25% (casual game, not daily habit)

**Sources**: [CleverTap](https://clevertap.com/blog/dau-vs-mau-app-stickiness-metrics/), [Braze](https://www.braze.com/resources/articles/essential-mobile-app-metrics-formulas)

---

### 1.4 Decision Triggers

Define what metrics trigger what actions:

| Metric | Threshold | Action |
|--------|-----------|--------|
| D1 Retention < 20% | Red flag | Fix onboarding, investigate drop-off |
| D7 Retention < 10% | Red flag | Core loop not engaging, major pivot needed |
| Quest Completion < 30% | Warning | Game too hard, improve hints/feedback |
| Quest Abandon > 50% | Warning | Something broken, investigate |
| MAU > 1,000 | Milestone | Consider adding monetization |
| MAU > 10,000 | Milestone | Consider sponsored locations, scale infra |
| DAU/MAU < 10% | Warning | Not sticky enough, add reasons to return |

---

### 1.5 Tracking Implementation

#### Already Planned (Aptabase)

```dart
// From Sprint 5
AnalyticsService.questStarted(questId);
AnalyticsService.questCompleted(questId, duration, distance);
AnalyticsService.questAbandoned(questId, duration);
```

#### Add These Events

```dart
// User lifecycle
AnalyticsService.trackEvent('signup_completed');
AnalyticsService.trackEvent('first_quest_started');
AnalyticsService.trackEvent('first_quest_completed');

// Engagement quality
AnalyticsService.trackEvent('app_opened');
AnalyticsService.trackEvent('quest_list_viewed');
AnalyticsService.trackEvent('history_viewed');

// Friction points
AnalyticsService.trackEvent('gps_permission_denied');
AnalyticsService.trackEvent('gps_unavailable');
AnalyticsService.trackEvent('offline_mode_entered');
```

#### Dashboards

| Source | What It Shows |
|--------|---------------|
| App Store Connect | iOS downloads, ratings, crashes |
| Google Play Console | Android downloads, ratings, crashes |
| Aptabase | Custom events, sessions |
| Sentry | Errors, performance |

**Note**: Aptabase is privacy-first and doesn't track user identity, so cohort analysis (D1/D7/D30) may need store analytics instead.

---

### 1.6 Review Cadence

| Frequency | What to Review |
|-----------|----------------|
| Daily | Crash reports (Sentry) |
| Weekly | Downloads, DAU, quest metrics |
| Monthly | Retention, MAU, trends |
| Quarterly | Strategy assessment, roadmap adjustment |

---

## Part 2: Budget & Costs

### 2.1 Fixed Costs

| Item | Cost | Frequency | Notes |
|------|------|-----------|-------|
| Apple Developer Account | $99 | Annual | Required for App Store |
| Google Play Developer | $25 | One-time | Already paid? |
| Upsun Hosting | **$0** | - | Free for you |
| Domain (if needed) | ~$12 | Annual | kashkash.app? |
| **Total Year 1** | **~$136** | | |

### 2.2 Optional/Variable Costs

| Item | Cost | When Needed |
|------|------|-------------|
| Sentry | Free tier | Up to 5k errors/month |
| Aptabase | Free tier | Up to 20k events/month |
| RevenueCat | Free tier | Up to $2,500 MTR |
| Codecov | Free for OSS | Public repo |
| Domain email | ~$6/mo | If you want support@kashkash.app |
| Marketing spend | Variable | If doing paid UA |

### 2.3 Scale Triggers

| Event | Cost Implication |
|-------|------------------|
| >5k errors/month | Sentry paid (~$26/mo) |
| >20k events/month | Aptabase paid (~$19/mo) |
| >$2,500 revenue | RevenueCat 1% fee |
| High traffic | Upsun may need upgrade (check your plan) |

### 2.4 Break-Even Analysis

With ~$136/year fixed costs:

| Scenario | Revenue Needed | Users Needed (at 5% conversion, $4.99) |
|----------|----------------|----------------------------------------|
| Cover costs | $136/year | ~550 downloads |
| Hobby income ($100/mo) | $1,200/year | ~4,800 downloads |
| Side income ($500/mo) | $6,000/year | ~24,000 downloads |

**Reality**: With free hosting, runway is essentially infinite. You can experiment without financial pressure.

---

## Part 3: User Acquisition Strategy

### 3.1 The Challenge

- 9 million apps exist globally
- Average app loses 77% of users in 3 days
- Paid UA costs $1-5 per install (US)
- Indie games compete with massive marketing budgets

**Your advantage**: Unique concept, no direct competitor, location-based = viral potential

---

### 3.2 Organic Acquisition (Priority)

Organic users have 4.5% retention at 8 weeks vs 3.5% for paid users. Focus here first.

#### App Store Optimization (ASO)

70% of App Store users find apps via search. ASO is critical.

| Element | Optimization Tips |
|---------|-------------------|
| **App Name** | Include keywords: "Kash-Kash: GPS Treasure Hunt" |
| **Subtitle (iOS)** | "Hot/Cold Geocaching Game" |
| **Keywords (iOS)** | geocaching, treasure hunt, GPS game, outdoor, adventure |
| **Description** | Lead with unique value, include keywords naturally |
| **Screenshots** | Show gameplay progression, color changes, win state |
| **Icon** | Simple, recognizable, stands out in search |
| **Category** | Games > Adventure? Games > Puzzle? Test both |

**Sources**: [MobileAction](https://www.mobileaction.co/guide/the-definitive-guide-for-mobile-user-acquisition/), [Udonis](https://www.blog.udonis.co/mobile-marketing/mobile-games/user-acquisition-strategy-mobile-games)

#### Word of Mouth (Most Powerful)

- 84% of people act on personal recommendations
- Word of mouth boosts marketing effectiveness by 54%

**How to encourage**:
- Make the game shareable (share win screenshots?)
- Add "Invite a friend" with deep link to quest
- Create memorable moments worth talking about

#### Community Building

| Channel | Effort | Potential |
|---------|--------|-----------|
| Reddit (r/geocaching, r/androidgaming, r/iosgaming) | Low | Medium |
| Discord server | Medium | High (engaged users) |
| Twitter/X | Low | Low-Medium |
| TikTok | Medium | High (if content goes viral) |
| Local geocaching groups | Low | High (target audience) |

**Recommendation**: Start with Reddit + Discord. These are low-cost and reach engaged audiences.

#### Content Marketing

| Content Type | Platform | Effort |
|--------------|----------|--------|
| Dev log posts | Reddit, Twitter | Low |
| Gameplay videos | YouTube, TikTok | Medium |
| "Making of" story | Blog, Medium | Medium |
| Local media (if newsworthy) | Press | Low |

---

### 3.3 Referral Mechanics

Built-in virality for location-based games:

| Mechanic | Description |
|----------|-------------|
| **Share Quest** | "I found this! Can you?" with link |
| **Create Quest** (future) | Users create quests for friends |
| **Leaderboards** (future) | Local competition |
| **Achievements** | Shareable badges |

**MVP**: Keep simple. Just make it easy to share a screenshot of winning.

---

### 3.4 Launch Strategy

#### Pre-Launch (2-4 weeks before)

- [ ] Create landing page with email capture
- [ ] Post on Reddit r/geocaching, r/indiegaming - "Working on this, would love feedback"
- [ ] Create Discord server for early testers
- [ ] Prepare press kit (screenshots, description, icon)

#### Launch Week

- [ ] Submit to App Store & Play Store
- [ ] Post on Reddit (r/androidgaming, r/iosgaming, r/geocaching)
- [ ] Announce on Discord, Twitter
- [ ] Reach out to local geocaching communities
- [ ] Ask friends/family to download and rate (honestly)

#### Post-Launch (ongoing)

- [ ] Respond to all reviews (especially negative)
- [ ] Post updates on community channels
- [ ] Collect and act on feedback
- [ ] Iterate based on metrics

---

### 3.5 Paid Acquisition (Later)

**Not recommended for MVP.** But if you have budget later:

| Channel | CPI (US) | Notes |
|---------|----------|-------|
| Meta (Facebook/Instagram) | $2-4 | Good targeting, expensive |
| TikTok | $1-3 | Younger audience, video required |
| Google UAC | $1-3 | Broad reach |
| Apple Search Ads | $2-5 | High intent, expensive |

**Rule of thumb**: Only spend on paid UA when LTV > 3x CPI

For Kash-Kash at $4.99 one-time purchase with 5% conversion:
- LTV = $4.99 × 5% = $0.25 per download
- Break-even CPI = $0.25 / 3 = $0.08

**Translation**: Paid UA doesn't make sense until you have subscription or higher conversion.

**Sources**: [MAF](https://maf.ad/en/blog/mobile-game-user-acquisition-strategy-2025/), [TyrAds](https://tyrads.com/mobile-game-user-acquisition-strategy/)

---

### 3.6 Target Audience

| Segment | Description | Where to Find |
|---------|-------------|---------------|
| **Geocachers** | Already love treasure hunting | r/geocaching, geocaching.com forums |
| **Outdoor enthusiasts** | Hikers, runners, explorers | Outdoor apps, hiking communities |
| **Pokémon GO players** | Like location-based games | Gaming subreddits, Discord |
| **Casual mobile gamers** | Looking for unique experiences | App Store search |
| **Families** | Activity to do together | Parenting communities |

**Primary target for launch**: Geocachers and Pokémon GO players - they already understand the concept.

---

## Part 4: Competitive Landscape

### 4.1 Direct Competitors

| App | Model | Differentiator |
|-----|-------|----------------|
| Geocaching (official) | Freemium | Community, millions of caches |
| Pokémon GO | F2P + IAP | AR, IP, massive scale |
| Ingress | F2P + IAP | Team gameplay, complex |
| Munzee | Freemium | QR code hunting |

### 4.2 Kash-Kash Differentiation

| Feature | Others | Kash-Kash |
|---------|--------|-------------|
| Shows distance/direction | Yes | **No** - pure hot/cold |
| Requires internet | Mostly | **Offline-first** |
| Complexity | High | **Minimal** - open and play |
| Hardware needs | Phone + GPS | **Same** |
| Learning curve | Medium | **Zero** - color = feedback |

**Positioning**: "The minimalist geocaching game. No maps. No hints. Just you and your instincts."

---

## Part 5: Decision Summary

### Metrics Decisions

| Question | Recommendation | Your Decision |
|----------|----------------|---------------|
| Primary success metric? | D7 Retention > 15% | ___________ |
| When to add monetization? | MAU > 1,000 | ___________ |
| When to consider pivot? | D7 Retention < 10% after fixes | ___________ |

### Budget Decisions

| Question | Recommendation | Your Decision |
|----------|----------------|---------------|
| Domain to register? | kashkash.app or similar | ___________ |
| Marketing budget? | $0 for MVP | ___________ |
| Paid tools budget? | $0 (free tiers) | ___________ |

### Acquisition Decisions

| Question | Recommendation | Your Decision |
|----------|----------------|---------------|
| Primary channel? | Reddit + ASO | ___________ |
| Create Discord? | Yes, before launch | ___________ |
| Landing page? | Yes, simple | ___________ |
| Paid UA? | No, not for MVP | ___________ |

---

## Part 6: Action Items

### Before MVP Launch

- [ ] Register domain (optional)
- [ ] Create simple landing page with email capture
- [ ] Set up Discord server
- [ ] Prepare ASO assets (screenshots, descriptions, keywords)
- [ ] Identify 3-5 Reddit communities to engage

### Launch Week

- [ ] Submit to stores with optimized ASO
- [ ] Post launch announcement (Reddit, Discord, Twitter)
- [ ] Ask beta testers to leave honest reviews
- [ ] Monitor crash reports and feedback

### Ongoing

- [ ] Weekly metrics review
- [ ] Respond to all reviews
- [ ] Engage in community
- [ ] Iterate based on data

---

## Sources

### Metrics & Benchmarks
- [UXCam - Mobile App Retention Benchmarks 2025](https://uxcam.com/blog/mobile-app-retention-benchmarks/)
- [Udonis - 15 Key Mobile Game Metrics](https://www.blog.udonis.co/mobile-marketing/mobile-games/key-mobile-game-metrics)
- [CleverTap - DAU vs MAU App Stickiness](https://clevertap.com/blog/dau-vs-mau-app-stickiness-metrics/)
- [Braze - Essential Mobile App Metrics](https://www.braze.com/resources/articles/essential-mobile-app-metrics-formulas)
- [UserPilot - 14 Mobile App Metrics](https://userpilot.com/blog/mobile-app-metrics/)

### User Acquisition
- [MAF - Mobile Game User Acquisition 2025](https://maf.ad/en/blog/mobile-game-user-acquisition-strategy-2025/)
- [Udonis - User Acquisition Strategy](https://www.blog.udonis.co/mobile-marketing/mobile-games/user-acquisition-strategy-mobile-games)
- [TyrAds - Ultimate Mobile Game UA Strategy](https://tyrads.com/mobile-game-user-acquisition-strategy/)
- [adjoe - Mobile App User Acquisition 2026](https://adjoe.io/blog/mobile-app-user-acquisition-strategy/)
- [MobileAction - Definitive Guide for Mobile UA](https://www.mobileaction.co/guide/the-definitive-guide-for-mobile-user-acquisition/)
- [GameBiz - Paid vs Organic UA](https://www.gamebizconsulting.com/blog/paid-organic-user-acquisition-mobile-games)

### Costs
- [Upsun Pricing](https://upsun.com/pricing/)
