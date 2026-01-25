# Kash-Kash: Monetization Decision

## TL;DR

**MVP ships free, no monetization. Add premium unlock later after validation.**

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Monetization in MVP? | **No** | Validate product-market fit first |
| Ads? | **No, never** | Breaks immersion, 54% uninstall rate, kills offline, conflicts with privacy |
| Crypto/NFT? | **No** | Regulatory nightmare, licenses required, overkill |
| Future model? | **One-time unlock** | Simple, no churn, works offline |
| When to add? | **~1k MAU** | After proving core product works |

---

## Why No Ads

1. Core gameplay is immersive (staring at colored screen) - ads break flow
2. 54% of users uninstall apps due to disruptive ads
3. Conflicts with privacy-first stance (Aptabase)
4. Ads need network - breaks offline-first architecture
5. Need 10k+ DAU to make meaningful revenue anyway

---

## Why No Crypto

1. Google Play requires FinCEN + state licenses (Oct 2025)
2. EU requires MiCA license
3. 10x technical complexity for uncertain benefit
4. Simple geocaching game doesn't need blockchain
5. Alienates mainstream users

---

## Future Plan

### Phase 1: MVP (now)
- Free app
- All features available
- Focus on product-market fit

### Phase 2: Premium (~1k MAU)
```
Free tier:
- 5 quests/month
- Basic history

Premium ($4.99 one-time):
- Unlimited quests
- Full history
- All themes
- Offline caching
```

### Phase 3: Expansion (~10k MAU)
- Quest packs ($2.99-4.99)
- Sponsored locations (B2B)
- City partnerships

---

## Technical Impact

### For MVP
**None.** No monetization code needed.

### When Adding Premium
- Add `purchases_flutter` (RevenueCat)
- Create paywall screen
- Gate features behind entitlements
- ~1 sprint of work

---

## Store Economics

| Platform | Commission | Dev Fee |
|----------|------------|---------|
| Apple | 15% (<$1M/year) | $99/year |
| Google | 15% (first $1M) | $25 once |

For every $4.99 purchase → you get $4.24

---

## Revenue Reality Check

Even with 10,000 MAU and 5% conversion:
- 500 paying users × $4.99 = $2,495 gross
- After 15% fee = **$2,120**

This is hobby income, not a business. Focus on making a great product first.

---

## Reference

Full analysis: [MONETIZATION-ANALYSIS.md](./MONETIZATION-ANALYSIS.md)
