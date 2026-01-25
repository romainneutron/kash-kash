# Kash-Kash Development Makefile
# ================================
# Run `make help` to see all available commands

ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
FLUTTER = $(ROOT_DIR)/flutter/bin/flutter
DART = $(ROOT_DIR)/flutter/bin/dart
APP_DIR = $(ROOT_DIR)/kash_kash_app
BACKEND_DIR = $(ROOT_DIR)/backend

.PHONY: help setup clean analyze test build run gen watch

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# FLUTTER COMMANDS
# =============================================================================

setup: ## [Flutter] Install dependencies
	cd $(APP_DIR) && $(FLUTTER) pub get

analyze: ## [Flutter] Run analyzer
	cd $(APP_DIR) && $(FLUTTER) analyze

format: ## [Flutter] Format Dart code
	cd $(APP_DIR) && $(DART) format lib test

lint: analyze format ## [Flutter] Run all linting (analyze + format)

test: ## [Flutter] Run all tests
	cd $(APP_DIR) && $(FLUTTER) test

test-coverage: ## [Flutter] Run tests with coverage
	cd $(APP_DIR) && $(FLUTTER) test --coverage
	@echo "Coverage report at $(APP_DIR)/coverage/lcov.info"

gen: ## [Flutter] Run build_runner (generate code)
	cd $(APP_DIR) && $(DART) run build_runner build --delete-conflicting-outputs

watch: ## [Flutter] Watch and regenerate code on changes
	cd $(APP_DIR) && $(DART) run build_runner watch --delete-conflicting-outputs

run: ## [Flutter] Run app in debug mode (web)
	cd $(APP_DIR) && $(FLUTTER) run -d chrome

run-android: ## [Flutter] Run app on Android
	cd $(APP_DIR) && $(FLUTTER) run -d android

run-ios: ## [Flutter] Run app on iOS
	cd $(APP_DIR) && $(FLUTTER) run -d ios

build-apk: ## [Flutter] Build Android APK
	cd $(APP_DIR) && $(FLUTTER) build apk --release

build-aab: ## [Flutter] Build Android App Bundle
	cd $(APP_DIR) && $(FLUTTER) build appbundle --release

build-ios: ## [Flutter] Build iOS
	cd $(APP_DIR) && $(FLUTTER) build ios --release

build-web: ## [Flutter] Build web
	cd $(APP_DIR) && $(FLUTTER) build web --release

clean: ## [Flutter] Clean build artifacts
	cd $(APP_DIR) && $(FLUTTER) clean
	cd $(APP_DIR) && rm -rf .dart_tool/build

clean-gen: ## [Flutter] Clean generated files
	cd $(APP_DIR) && find . -name "*.g.dart" -delete
	cd $(APP_DIR) && find . -name "*.freezed.dart" -delete

doctor: ## [Flutter] Run Flutter doctor
	$(FLUTTER) doctor -v

upgrade: ## [Flutter] Upgrade dependencies
	cd $(APP_DIR) && $(FLUTTER) pub upgrade

upgrade-major: ## [Flutter] Upgrade to major versions
	cd $(APP_DIR) && $(FLUTTER) pub upgrade --major-versions

flutter-check: analyze test ## [Flutter] Run full check (analyze + test) - USE BEFORE PUSH

# =============================================================================
# SYMFONY/BACKEND COMMANDS
# =============================================================================

backend-up: ## [Backend] Start Docker containers
	cd $(BACKEND_DIR) && docker compose up -d

backend-down: ## [Backend] Stop Docker containers
	cd $(BACKEND_DIR) && docker compose down

backend-logs: ## [Backend] Show container logs
	cd $(BACKEND_DIR) && docker compose logs -f

backend-shell: ## [Backend] Open shell in PHP container
	cd $(BACKEND_DIR) && docker compose exec php bash

backend-install: ## [Backend] Install Composer dependencies
	cd $(BACKEND_DIR) && docker compose exec php composer install

backend-schema: ## [Backend] Create database schema
	cd $(BACKEND_DIR) && docker compose exec php bin/console doctrine:schema:create --env=test

backend-schema-update: ## [Backend] Update database schema
	cd $(BACKEND_DIR) && docker compose exec php bin/console doctrine:schema:update --force

backend-migrate: ## [Backend] Run migrations
	cd $(BACKEND_DIR) && docker compose exec php bin/console doctrine:migrations:migrate --no-interaction

backend-test: ## [Backend] Run PHPUnit tests
	cd $(BACKEND_DIR) && docker compose exec php vendor/bin/phpunit

backend-test-coverage: ## [Backend] Run PHPUnit tests with coverage
	cd $(BACKEND_DIR) && docker compose exec php vendor/bin/phpunit --coverage-html var/coverage

backend-console: ## [Backend] Run Symfony console command (usage: make backend-console CMD="cache:clear")
	cd $(BACKEND_DIR) && docker compose exec php bin/console $(CMD)

backend-check: backend-up backend-install backend-test ## [Backend] Run full check - USE BEFORE PUSH

# =============================================================================
# CI/CD COMMANDS
# =============================================================================

ci-flutter: setup gen analyze test ## [CI] Flutter CI pipeline
	@echo "✓ Flutter CI passed"

ci-backend: backend-up backend-install backend-schema backend-test ## [CI] Backend CI pipeline
	@echo "✓ Backend CI passed"

ci: ci-flutter ci-backend ## [CI] Run full CI pipeline locally
	@echo "✓ All CI checks passed - safe to push"

# =============================================================================
# PRE-PUSH CHECK (RUN THIS BEFORE EVERY PUSH)
# =============================================================================

pre-push: flutter-check ## Run all checks before pushing (Flutter only for now)
	@echo ""
	@echo "==========================================="
	@echo "✓ Pre-push checks passed - safe to push"
	@echo "==========================================="

pre-push-full: ci ## Run full CI locally before pushing (requires Docker)
	@echo ""
	@echo "==========================================="
	@echo "✓ Full pre-push checks passed - safe to push"
	@echo "==========================================="
