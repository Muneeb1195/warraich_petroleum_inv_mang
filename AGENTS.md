## Progress
### Done
- v1.6.0+1 shipped; tag pushed, CI/CD builds all platforms
- Full deep audit — 0 critical bugs across 74 files
- All hardcoded `Rs.` replaced with `$kCurrency`
- Inline `SegmentedButton<ThemeMode>` in Settings
- `_exceedsInventory` server-side guard in `addSaleToShift` and `updateSaleInShift`
- Stock rollback on sale delete; improved to only restore if shift status is `'closed'`
- `formatMoney` abbreviation toggle in Settings
- `RefreshIndicator` on shifts, sales history, expenses, employees, inventory screens
- Low stock warning banner on dashboard
- Search bar, date range picker, type/status filter on sales history screen
- Edit/delete expenses and employees
- Centralized error handling
- 4-page onboarding with PageView
- 24 tests (11 DB + 6 provider + 1 widget + 1 backup + 5 merge)
- Riverpod codegen unblocked
- Repository pattern
- Linux desktop builds and runs
- Widget test fixed (Drift stream timer issue resolved)
- 0 dart analyze errors (34 info-level hints remain)
- Removed hardcoded Google credentials from source; requires `--dart-define` at build time
- Git history cleaned — all secrets replaced with REDACTED placeholders
- CI/CD fixed: Android keystore path, Windows shell: bash, removed dead FIREBASE_API_KEY
- Code quality pass: extracted `_isWide` to `lib/utils/responsive.dart`, removed 17 duplicates
- `local_auth` upgraded to 3.x (fixes Windows build STL1011 error)
- Firebase Auth for all platforms (Android/Linux/Windows):
  - `AppUser` model (`lib/models/auth_user.dart`) replaces `firebase_auth.User` across providers
  - `FirebaseRestAuth` (`lib/services/firebase_rest_auth.dart`) — pure-Dart REST API fallback for Linux
  - `AuthService` auto-detects Firebase SDK availability; falls back to REST on Linux
  - `Firebase.initializeApp()` wrapped in try-catch in `main.dart` for desktop
  - `Makefile` with `run-*` and `build-*` targets that source `.env` for `--dart-define`
  - `.env.example` updated with redirect URI instructions

### In Progress
- (none)

### Blocked
- (none)

## Key Decisions
- `deleteSaleFromShift` checks `shift.status == 'closed'` before restoring stock
- `BackupService._googleSignIn` is `late final`
- Backup timer created unconditionally in `initializeAutoBackup`; cancelled in `dispose()`
- Onboarding shown before app-lock
- Riverpod 3.x: kept `StateNotifierProvider` via `legacy.dart`
- `local_auth` 3.x accepted as cross-platform dependency (app lock is mobile-only but Flutter includes all platform sub-packages automatically)
- **Firebase Auth on desktop**: `firebase_auth` has native Windows support (C++ plugin in 5.x) but NOT Linux. Linux uses `FirebaseRestAuth` (REST API via `http`). Android uses native Firebase Auth SDK.
- **Platform decoupling**: `AppUser` model replaces `firebase_auth.User` in all providers/UI to avoid Firebase type dependency on desktop. Properties match: uid, email, displayName, photoURL.
- **Google Cloud Console**: Web application OAuth client with `http://localhost:8000` redirect URI required for desktop. Same client ID used as `serverClientId` on Android.
- **`--dart-define`**: Credentials must be passed via `--dart-define=GOOGLE_CLIENT_ID=... --dart-define=GOOGLE_CLIENT_SECRET=...`. Use `make run-linux` etc. from the Makefile to source `.env`.

## Next Steps
- (none)

## Relevant Files
- `lib/services/backup_service.dart`: Google Drive + local backup/restore via REST API
- `lib/providers/backup_provider.dart`: Backup state management
- `lib/screens/settings/backup_screen.dart`: Backup UI
- `lib/providers/auth_provider.dart`: Biometric app lock
- `lib/database/app_database.dart`: Drift schema
- `lib/database/daos/`: All DAOs
- `lib/services/auth_service.dart`: Google Sign-In + Firebase Auth (Firebase SDK or REST fallback)
- `lib/services/firebase_rest_auth.dart`: Pure-Dart Firebase Auth REST API for Linux
- `lib/providers/firebase_auth_provider.dart`: Riverpod auth providers (FirebaseSignInNotifier)
- `lib/models/auth_user.dart`: AppUser model (cross-platform)
- `lib/config/app_config.dart`: `--dart-define` config + Firebase API key getter
- `lib/firebase_options.dart`: Generated FlutterFire config (Android + Desktop)
- `Makefile`: Run/build targets that source `.env` for `--dart-define`
