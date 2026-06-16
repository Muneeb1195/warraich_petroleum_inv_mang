## Progress
### Done
- v1.5.0+1 shipped; tag pushed, CI/CD builds all platforms, APK installed on Pixel 8
- Full deep audit — 0 critical bugs across 60+ files
- All hardcoded `Rs.` replaced with `$kCurrency`
- Inline `SegmentedButton<ThemeMode>` in Settings
- `_exceedsInventory` server-side guard in `addSaleToShift` and `updateSaleInShift`
- Stock rollback on sale delete; improved to only restore if shift status is `'closed'`
- `formatMoney` abbreviation toggle in Settings
- `RefreshIndicator` on shifts, sales history, expenses, employees, inventory screens
- Low stock warning banner on dashboard
- Search bar, date range picker, type/status filter on sales history screen
- Edit/delete expenses
- Centralized error handling
- 4-page onboarding with PageView
- 19 tests (11 DB + 6 provider + 1 widget + 1 backup)
- Riverpod codegen unblocked
- Repository pattern
- Linux desktop builds and runs
- Widget test fixed (Drift stream timer issue resolved)
- 0 dart analyze issues (all info-level warnings resolved)
- Removed hardcoded Google credentials from source; requires `--dart-define` at build time
- Git history cleaned — all secrets replaced with REDACTED placeholders
- CI/CD fixed: Android keystore path, Windows shell: bash, removed dead FIREBASE_API_KEY
- Code quality pass: extracted `_isWide` to `lib/utils/responsive.dart`, removed 17 duplicates
- `local_auth` upgraded to 3.x (fixes Windows build STL1011 error)

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

## Next Steps
- (none)

## Relevant Files
- `lib/services/backup_service.dart`: Google Drive + local backup/restore via REST API
- `lib/providers/backup_provider.dart`: Backup state management
- `lib/screens/settings/backup_screen.dart`: Backup UI
- `lib/providers/auth_provider.dart`: Biometric app lock
- `lib/database/app_database.dart`: Drift schema
- `lib/database/daos/`: All DAOs
