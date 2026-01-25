# Kash-Kash Development Makefile

ROOT_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
FLUTTER = $(ROOT_DIR)/flutter/bin/flutter
DART = $(ROOT_DIR)/flutter/bin/dart
APP_DIR = $(ROOT_DIR)/kash_kash_app

.PHONY: help setup clean analyze test build run gen watch

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

# Setup
setup: ## Install Flutter dependencies
	cd $(APP_DIR) && $(FLUTTER) pub get

# Code Quality
analyze: ## Run Flutter analyzer
	cd $(APP_DIR) && $(FLUTTER) analyze

format: ## Format Dart code
	cd $(APP_DIR) && $(DART) format lib test

lint: analyze format ## Run all linting (analyze + format)

# Testing
test: ## Run all tests
	cd $(APP_DIR) && $(FLUTTER) test

test-coverage: ## Run tests with coverage
	cd $(APP_DIR) && $(FLUTTER) test --coverage
	@echo "Coverage report at $(APP_DIR)/coverage/lcov.info"

# Code Generation
gen: ## Run build_runner (generate code)
	cd $(APP_DIR) && $(DART) run build_runner build --delete-conflicting-outputs

watch: ## Watch and regenerate code on changes
	cd $(APP_DIR) && $(DART) run build_runner watch --delete-conflicting-outputs

# Running
run: ## Run app in debug mode (web)
	cd $(APP_DIR) && $(FLUTTER) run -d chrome

run-android: ## Run app on Android
	cd $(APP_DIR) && $(FLUTTER) run -d android

run-ios: ## Run app on iOS
	cd $(APP_DIR) && $(FLUTTER) run -d ios

# Building
build-apk: ## Build Android APK
	cd $(APP_DIR) && $(FLUTTER) build apk --release

build-aab: ## Build Android App Bundle
	cd $(APP_DIR) && $(FLUTTER) build appbundle --release

build-ios: ## Build iOS
	cd $(APP_DIR) && $(FLUTTER) build ios --release

build-web: ## Build web
	cd $(APP_DIR) && $(FLUTTER) build web --release

# Cleaning
clean: ## Clean build artifacts
	cd $(APP_DIR) && $(FLUTTER) clean
	cd $(APP_DIR) && rm -rf .dart_tool/build

clean-gen: ## Clean generated files
	cd $(APP_DIR) && find . -name "*.g.dart" -delete
	cd $(APP_DIR) && find . -name "*.freezed.dart" -delete

# Doctor
doctor: ## Run Flutter doctor
	$(FLUTTER) doctor -v

# Upgrade
upgrade: ## Upgrade dependencies
	cd $(APP_DIR) && $(FLUTTER) pub upgrade

upgrade-major: ## Upgrade to major versions
	cd $(APP_DIR) && $(FLUTTER) pub upgrade --major-versions

# Backend (Symfony)
backend-up: ## Start backend with Docker
	cd backend && docker-compose up -d

backend-down: ## Stop backend
	cd backend && docker-compose down

backend-logs: ## Show backend logs
	cd backend && docker-compose logs -f
