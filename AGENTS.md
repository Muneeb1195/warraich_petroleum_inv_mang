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
- 17 tests (11 DB + 6 provider)
- Riverpod codegen unblocked
- Repository pattern
- Replaced all Firebase packages with pure-HTTP REST client
- FirebaseAuthService: Google sign-in + Firebase Auth REST + RTDB HTTP CRUD
- SyncService: 6-collection sync, 30s periodic timer, per-record PATCH/DELETE, conflict resolution via `updatedAt`
- Linux desktop builds and runs without Firebase crash
- Android RTDB sync works (`?auth=` query param)
- Login persists after restart (`_refreshToken`/`_uid` in `FlutterSecureStorage`)
- Desktop sign-in works (browser OAuth + `FlutterSecureStorage`)
- Cloud Sync status card in Settings
- **Bidirectional sync**: `updatedAt` column added to all 6 syncable tables;
  per-record `syncRecord()`/`deleteRecord()` methods; conflict resolution in
  `pullAllFromCloud` (last-writer-wins); providers wire sync to all collections.

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
- Realtime Database over Firestore (Spark free tier)
- Pure-HTTP Firebase over native SDK (no Linux desktop support for native)
- Platform-specific Google sign-in (Android Credential Manager vs browser OAuth)
- Desktop token storage uses `FlutterSecureStorage` not `SharedPreferences`
- `?auth=` query param over `Authorization: Bearer` for RTDB
- Sync frequency: per-record push immediately on mutation; periodic full push every 30s; full pull on init; last-writer-wins via `updatedAt`

## Next Steps
- Fix pre-existing widget test (drift timer pending issue)
- Update RTDB security rules to enforce per-UID access
- Add inventory collection to cloud sync

## Relevant Files
- `lib/services/sync_service.dart`: Full bidirectional sync with per-record PATCH/DELETE, conflict resolution via `updatedAt`, 6 collections, periodic timer
- `lib/database/app_database.dart`: schema v4 with `updatedAt` in all 6 tables
- `lib/database/daos/`: All DAOs set `updatedAt` on every update
- `lib/providers/`: All providers call sync after each mutation
