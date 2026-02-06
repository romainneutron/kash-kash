# Kash-Kash

[![CI](https://github.com/romainneutron/kash-kash/actions/workflows/ci.yml/badge.svg)](https://github.com/romainneutron/kash-kash/actions/workflows/ci.yml)

A geocaching mobile game where players search for GPS coordinates using only color-coded visual feedback.

## Game Mechanics

- **Black screen**: Stationary (no GPS movement detected)
- **Red screen**: Moving closer to target
- **Blue screen**: Moving farther from target
- **Win**: Within 3 meters of target coordinates

## Tech Stack

### Frontend (Flutter)
- Flutter 3.38.x / Dart 3.10.x
- State Management: Riverpod 3.x with codegen
- Navigation: go_router
- Local Database: Drift (SQLite)
- Location/GPS: geolocator
- Error Handling: fpdart (Either types)

### Backend (Symfony)
- Framework: Symfony 8.0
- Database: PostgreSQL 16 + PostGIS
- Authentication: Google OAuth + JWT
- ORM: Doctrine 3.x

### Monitoring
- Error Tracking: Sentry
- Analytics: Aptabase (privacy-first)

## Prerequisites

- Flutter SDK 3.38+ (installed locally in `./flutter/`)
- Docker & Docker Compose (for backend)
- libsqlite3-dev (for running all tests locally)
  ```bash
  # Ubuntu/Debian
  sudo apt-get install libsqlite3-dev
  ```

## Quick Start

```bash
# Install dependencies
make setup

# Run code generation
make gen

# Run the app (web)
make run

# Run tests (requires libsqlite3-dev)
make test
```

## Development

```bash
# Pre-push check (run before every push)
make pre-push

# Start backend
make backend-up

# Run full CI locally
make pre-push-full
```

## Project Structure

```
kash-kash/
├── kash_kash_app/           # Flutter mobile app
│   └── lib/
│       ├── core/            # Constants, errors, utils
│       ├── domain/          # Entities, repositories, use cases
│       ├── data/            # Data sources, models, repo implementations
│       ├── infrastructure/  # GPS, sync, background services
│       ├── presentation/    # Screens, widgets, providers
│       └── router/          # App navigation
├── backend/                 # Symfony API
├── plan/                    # Sprint planning documents
└── flutter/                 # Local Flutter SDK (gitignored)
```

## Available Commands

Run `make help` to see all available commands.

## Documentation

- [Architecture](plan/ARCHITECTURE.md)
- [Sprint Plans](plan/sprints/)

## License

Proprietary - All rights reserved
