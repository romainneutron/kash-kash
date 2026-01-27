# Claude Code Instructions

This file provides context for Claude Code when working on this repository.

## Project Overview

Kash-Kash is a geocaching mobile game where players search for GPS coordinates using only color-coded visual feedback (black=stationary, red=closer, blue=farther).

## Tech Stack

| Component | Version | Notes |
|-----------|---------|-------|
| Flutter | 3.38.x | Local SDK in `./flutter/` (gitignored) |
| Dart | 3.10.x | Comes with Flutter |
| Symfony | 8.0 | API backend |
| PHP | 8.5 | Required for Symfony 8 |
| PostgreSQL | 16 | With PostGIS extension |
| Doctrine Bundle | 3.0 | Required for Symfony 8 compatibility |
| Riverpod | 3.x | State management with codegen |

## Project Structure

```
kash-kash/
├── kash_kash_app/           # Flutter mobile app
│   └── lib/
│       ├── core/            # Constants, errors, utils, extensions
│       ├── domain/          # Entities, repository interfaces, use cases
│       ├── data/            # Data sources, models, repository implementations
│       ├── infrastructure/  # GPS, sync, background services
│       ├── presentation/    # Screens, widgets, providers, theme
│       └── router/          # App navigation (go_router)
├── backend/                 # Symfony API
│   ├── src/Entity/          # Doctrine entities
│   ├── config/              # Symfony configuration
│   └── docker/              # Docker configuration
├── plan/                    # Sprint planning documents
│   └── sprints/            # Individual sprint plans with checkboxes
├── flutter/                 # Local Flutter SDK (gitignored)
├── .github/workflows/       # GitHub Actions CI
├── renovate.json           # Renovate auto-update config
└── Makefile                # Development commands
```

## Key Commands (Makefile)

```bash
# Quick reference - run `make help` for full list
make pre-push        # RUN THIS BEFORE EVERY PUSH (Flutter only)
make pre-push-full   # Full CI locally (requires Docker)

# Flutter
make setup           # Install dependencies
make gen             # Code generation (Drift, Riverpod)
make analyze         # Run analyzer
make test            # Run tests
make flutter-check   # Analyze + test

# Backend (requires Docker)
make backend-up      # Start containers
make backend-install # Install Composer deps
make backend-test    # Run PHPUnit
make backend-check   # Full backend check
```

## Development Workflow

1. Check sprint plans in `plan/sprints/` for tasks
2. Tasks have checkboxes `[ ]` to mark completion
3. After completing a task, check the box `[x]`
4. Run `make pre-push` before committing
5. Commit frequently with descriptive messages

## Pre-Push Checklist (CRITICAL)

**ALWAYS run before pushing:**

```bash
make pre-push  # Runs analyze + test for Flutter
```

**For backend changes (requires Docker):**

```bash
make pre-push-full  # Runs full CI locally
```

**NEVER push without local tests passing - GitHub Actions costs money.**

## Architecture Patterns

- **Clean Architecture**: domain → data → presentation
- **State Management**: Riverpod 3.x with code generation
- **Error Handling**: `Either<Failure, T>` from fpdart
- **Database**: Drift (SQLite) for local storage
- **Navigation**: go_router with auth guards

## Code Generation

After modifying:
- Drift tables (`*.dart` with `@DriftDatabase`)
- Riverpod providers (`@riverpod` annotation)

Run: `make gen` or `make watch`

## Sprint Progress

Check `plan/sprints/` for detailed task breakdowns with acceptance criteria.
Current sprint documents have checkboxes indicating completion status.

**Current Sprint**: 1 (Project Foundation) - Complete
**Next Sprint**: 2 (Authentication Flow)

## Conventions

- Use Riverpod for all state management
- Domain entities are pure Dart (no Flutter dependencies)
- Repositories return `Either<Failure, T>`
- All screens are `ConsumerWidget` or `ConsumerStatefulWidget`
- Commit after each completed task

## CI/CD

### GitHub Actions (`.github/workflows/ci.yml`)
- **Flutter**: setup → gen → analyze → test → coverage
- **Symfony**: composer install → schema:create → PHPUnit → coverage
- Runs on push/PR to main branch

### Renovate (`renovate.json`)
- Checks twice daily (9am, 5pm UTC)
- Auto-merges minor/patch updates for Flutter and PHP
- Major updates require manual review
- Security alerts enabled

### Upsun Deployment
- **Project**: `zbl4tfxlbq4ss`
- **Console**: https://console.upsun.com/romain-neutron-private/zbl4tfxlbq4ss
- **Config**: `.upsun/config.yaml`
- **Auto-deploy**: Push to `main` triggers deployment
- **Stack**: PHP 8.5 + PostgreSQL 16

## Troubleshooting

### Doctrine Bundle + Symfony 8
- Use `doctrine/doctrine-bundle: ^3.0` (not ^2.x)
- Use `doctrine/doctrine-migrations-bundle: ^4.0`
- Remove deprecated config options:
  - `use_savepoints` (removed in 3.0)
  - `auto_generate_proxy_classes` (always enabled)
  - `enable_lazy_ghost_objects` (always enabled)
  - `report_fields_where_declared` (removed)
  - `validate_xml_mapping` (removed)

### Flutter 3.38 Breaking Changes
- Use `CardThemeData` instead of `CardTheme`
- Remove `library` declarations (deprecated in Dart 3.10)
- Remove dangling doc comments

### Common Errors
- "No migrations found" → Use `doctrine:schema:create` for fresh DB
- Flutter analyzer on wrong dir → Run from `kash_kash_app/` not root

## Local Development Setup

### Flutter
Flutter SDK is installed locally in `./flutter/` (gitignored).
If missing, download from https://flutter.dev and extract to `./flutter/`.

### Backend (Docker)
```bash
make backend-up       # Start containers
make backend-install  # Install dependencies
make backend-test     # Run tests
```

## Session Notes

_Add any session-specific context here for continuity._
