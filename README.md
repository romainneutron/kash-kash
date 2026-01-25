# Kash-Kash

A geocaching mobile game where players search for GPS coordinates using only color-coded visual feedback.

## Game Mechanics

- **Black screen**: Stationary (no GPS movement detected)
- **Red screen**: Moving closer to target
- **Blue screen**: Moving farther from target
- **Win**: Within 3 meters of target coordinates

## Tech Stack

### Frontend (Flutter)
- State Management: Riverpod 2.x
- Navigation: go_router
- Local Database: Drift (SQLite)
- Location/GPS: geolocator
- Maps: flutter_map (OpenStreetMap)

### Backend (Symfony)
- Framework: Symfony 7 + API Platform
- Database: PostgreSQL 16 + PostGIS
- Authentication: Google OAuth + JWT

### Monitoring
- Error Tracking: Sentry
- Analytics: Aptabase (privacy-first)

## Prerequisites

- Flutter SDK 3.24+ (installed locally in `./flutter/`)
- Docker & Docker Compose (for backend)

## Quick Start

```bash
# Install dependencies
make setup

# Run code generation
make gen

# Run the app
make run

# Run tests
make test
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
├── backend/                 # Symfony API (TODO)
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
