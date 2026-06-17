-include .env
export

.PHONY: run-android run-linux run-windows build-apk help

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

run-android: ## Run on Android (requires device/emulator)
	flutter run -d android \
		--dart-define=GOOGLE_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_CLIENT_SECRET="$(GOOGLE_CLIENT_SECRET)"

run-linux: ## Run on Linux desktop
	flutter run -d linux \
		--dart-define=GOOGLE_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_CLIENT_SECRET="$(GOOGLE_CLIENT_SECRET)"

run-windows: ## Run on Windows desktop
	flutter run -d windows \
		--dart-define=GOOGLE_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_CLIENT_SECRET="$(GOOGLE_CLIENT_SECRET)"

build-apk: ## Build release APK (arm64-v8a)
	flutter build apk --target-platform android-arm64 \
		--dart-define=GOOGLE_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_CLIENT_SECRET="$(GOOGLE_CLIENT_SECRET)"

build-linux: ## Build Linux release
	flutter build linux \
		--dart-define=GOOGLE_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_CLIENT_SECRET="$(GOOGLE_CLIENT_SECRET)"

build-windows: ## Build Windows release
	flutter build windows \
		--dart-define=GOOGLE_CLIENT_ID="$(GOOGLE_CLIENT_ID)" \
		--dart-define=GOOGLE_CLIENT_SECRET="$(GOOGLE_CLIENT_SECRET)"
