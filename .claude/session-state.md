# Claude Session State

**Last Updated**: 2026-01-27
**Last Commit**: 90ac26a - Complete Sprint 2: Flutter authentication flow

## Current Progress

### Sprint 2: Authentication - COMPLETE ✅

All tasks completed and pushed to origin/main.

#### Backend Tasks (Complete)
- [x] S2-T1: Symfony Google OAuth Setup
- [x] S2-T2: Symfony JWT Configuration (base64 keys in env vars)
- [x] S2-T3: Symfony Auth Controller

#### Flutter Tasks (Complete)
- [x] S2-T4: Flutter API Client Setup
- [x] S2-T5: Flutter Auth Remote Data Source
- [x] S2-T6: Flutter Secure Storage
- [x] S2-T7: Flutter Auth Repository
- [x] S2-T8: Flutter Auth Provider
- [x] S2-T9: Flutter Login Screen
- [x] S2-T10: Flutter Router Auth Guards

## Next Steps

### Sprint 3: Quest Data and List
See `plan/sprints/03-quest-data-and-list.md` for full details.

## Key Files Created in Sprint 2

### Backend
- `backend/config/packages/knpu_oauth2_client.yaml`
- `backend/config/packages/lexik_jwt_authentication.yaml`
- `backend/config/packages/security.yaml`
- `backend/src/Controller/AuthController.php`
- `backend/src/Entity/RefreshToken.php`
- `backend/src/Repository/RefreshTokenRepository.php`

### Flutter
- `kash_kash_app/lib/infrastructure/storage/secure_storage.dart`
- `kash_kash_app/lib/data/datasources/remote/api/api_client.dart`
- `kash_kash_app/lib/data/datasources/remote/api/auth_interceptor.dart`
- `kash_kash_app/lib/data/datasources/remote/auth_remote_data_source.dart`
- `kash_kash_app/lib/data/models/user_model.dart`
- `kash_kash_app/lib/data/models/auth_result.dart`
- `kash_kash_app/lib/data/repositories/auth_repository_impl.dart`
- `kash_kash_app/lib/presentation/providers/api_provider.dart`
- `kash_kash_app/lib/presentation/providers/auth_provider.dart`
- `kash_kash_app/lib/presentation/screens/login_screen.dart`
- `kash_kash_app/lib/router/app_router.dart` (updated)

## Environment Setup Notes

### Upsun Deployment
- Project ID: `zbl4tfxlbq4ss`
- Console: https://console.upsun.com/romain-neutron-private/zbl4tfxlbq4ss
- Environment variables set with `env:` prefix:
  - `env:GOOGLE_CLIENT_ID`
  - `env:GOOGLE_CLIENT_SECRET`
  - `env:JWT_SECRET_KEY` (base64 encoded)
  - `env:JWT_PUBLIC_KEY` (base64 encoded)

### Google OAuth
- Configured in Google Cloud Console
- Redirect URI: `https://main-bvxea6i-zbl4tfxlbq4ss.eu-5.platformsh.site/auth/google/callback`

### Local Development
- Flutter SDK in `./flutter/` (gitignored)
- Backend runs with Docker: `make backend-up`
- Run `make pre-push` before committing

## Commands to Resume

```bash
# Verify current state
git log --oneline -5
make pre-push

# Start Sprint 3
cat plan/sprints/03-quest-data-and-list.md
```
