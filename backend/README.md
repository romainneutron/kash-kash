# Kash-Kash Backend

Symfony 7 + API Platform backend for the Kash-Kash geocaching game.

## Requirements

- Docker & Docker Compose

## Quick Start

```bash
# Start services
docker-compose up -d

# Install dependencies (first time)
docker-compose exec php composer install

# Generate JWT keys
docker-compose exec php php bin/console lexik:jwt:generate-keypair

# Run migrations
docker-compose exec php php bin/console doctrine:migrations:migrate

# Access API docs
open http://localhost:8080/api
```

## Stack

- PHP 8.3
- Symfony 7.1
- API Platform 4.x
- PostgreSQL 16 + PostGIS
- Doctrine ORM
- Lexik JWT Authentication
- KnpU OAuth2 Client (Google)
- Sentry for error tracking

## Environment Variables

Copy `.env` to `.env.local` and configure:

- `DATABASE_URL` - PostgreSQL connection
- `JWT_PASSPHRASE` - JWT key passphrase
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth client secret
- `SENTRY_DSN` - Sentry error tracking DSN

## API Endpoints

- `POST /api/auth/google` - Google OAuth authentication
- `GET /api/quests` - List published quests
- `GET /api/quests/nearby` - Get quests near location
- `POST /api/attempts` - Start quest attempt
- `POST /api/sync/push` - Push local changes
- `POST /api/sync/pull` - Pull remote updates

## Development

```bash
# Run tests
docker-compose exec php php bin/phpunit

# Create migration
docker-compose exec php php bin/console make:migration

# Run migrations
docker-compose exec php php bin/console doctrine:migrations:migrate
```
