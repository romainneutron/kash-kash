# Claude Code Instructions

This file provides context for Claude Code when working on this repository.

## Project Overview

Kash-Kash is a geocaching mobile game where players search for GPS coordinates using only color-coded visual feedback (black=stationary, red=closer, blue=farther).

## Tech Stack

- **Frontend**: Flutter with Riverpod, Drift, go_router
- **Backend**: Symfony 7 + API Platform + PostgreSQL/PostGIS
- **Monitoring**: Sentry (errors), Aptabase (analytics)

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
├── backend/                 # Symfony API (to be created)
├── plan/                    # Sprint planning documents
│   └── sprints/            # Individual sprint plans with checkboxes
├── flutter/                 # Local Flutter SDK (gitignored)
└── Makefile                 # Common development commands
```

## Key Commands

```bash
make setup          # Install dependencies
make gen            # Run code generation (Drift, Riverpod)
make analyze        # Run Flutter analyzer
make test           # Run tests
make run            # Run app (web)
```

## Development Workflow

1. Check sprint plans in `plan/sprints/` for tasks
2. Tasks have checkboxes `[ ]` to mark completion
3. After completing a task, check the box `[x]`
4. Commit frequently with descriptive messages

## Architecture Patterns

- **Clean Architecture**: domain → data → presentation
- **State Management**: Riverpod 2.x with code generation
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

## Conventions

- Use Riverpod for all state management
- Domain entities are pure Dart (no Flutter dependencies)
- Repositories return `Either<Failure, T>`
- All screens are `ConsumerWidget` or `ConsumerStatefulWidget`
- Commit after each completed task
