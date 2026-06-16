import 'dart:async';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/app_database.dart';
import '../services/backup_service.dart';
import '../services/merge_service.dart';
import 'database_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupNotifier extends StateNotifier<AsyncValue<void>> {
  final BackupService _service;
  final Ref _ref;
  Timer? _autoTimer;
  bool _autoBackupInProgress = false;

  BackupNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  static const _autoBackupKey = 'auto_backup_enabled';
  static const _lastAutoBackupKey = 'last_auto_backup';

  Future<void> initializeAutoBackup() async {
    const storage = FlutterSecureStorage();
    final enabled = await storage.read(key: _autoBackupKey);
    if (enabled == 'false') return;

    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _tryAutoBackup();
    });

    _tryAutoBackup();
  }

  Future<void> _tryAutoBackup() async {
    if (_autoBackupInProgress) return;
    _autoBackupInProgress = true;
    try {
      const storage = FlutterSecureStorage();
      final enabled = await storage.read(key: _autoBackupKey);
      if (enabled == 'false') return;

      final lastBackup = await storage.read(key: _lastAutoBackupKey);
      if (lastBackup != null) {
        final lastDate = DateTime.tryParse(lastBackup);
        if (lastDate != null && DateTime.now().difference(lastDate).inHours < 24) return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dir.path, 'warraich_petroleum.db'));
      if (!dbFile.existsSync()) return;

      // WAL checkpoint — wrapped in try-catch in case DB is corrupted
      try {
        final db = _ref.read(databaseProvider);
        await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
      } catch (_) {
        return; // Skip backup if DB is in bad state
      }

      final cloudResult = await _service.backupDatabase(dbFile);
      if (cloudResult) {
        await storage.write(key: _lastAutoBackupKey, value: DateTime.now().toIso8601String());
        return;
      }

      final localResult = await _service.localBackup(dbFile);
      if (localResult) {
        await storage.write(key: _lastAutoBackupKey, value: DateTime.now().toIso8601String());
      }
    } catch (_) {
      // Silent — auto-backup should never crash the app
    } finally {
      _autoBackupInProgress = false;
    }
  }

  Future<void> _saveBackupTimestamp() async {
    const storage = FlutterSecureStorage();
    await storage.write(key: _lastAutoBackupKey, value: DateTime.now().toIso8601String());
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  Future<bool> backupDatabase(File dbFile) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}
    final result = await _service.backupDatabase(dbFile);
    if (result) await _saveBackupTimestamp();
    state = result
        ? const AsyncValue.data(null)
        : const AsyncValue.error('Backup failed', StackTrace.empty);
    return result;
  }

  Future<bool> restoreFromDrive(File targetFile) async {
    state = const AsyncValue.loading();
    try {
      // 1. Download backup to temp file
      final tempFile = await _service.restoreLatestBackup();
      if (tempFile == null) {
        state = const AsyncValue.error('Download failed', StackTrace.empty);
        return false;
      }

      // 2. Open both databases and merge
      final currentDb = _ref.read(databaseProvider);
      final backupDb = AppDatabase(executor: NativeDatabase(tempFile));
      try {
        await MergeService.mergeDatabases(currentDb, backupDb);
      } finally {
        await backupDb.close();
        try { await tempFile.delete(); } catch (_) {}
      }

      // 3. Invalidate provider so database re-initializes
      _ref.invalidate(databaseProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      _ref.invalidate(databaseProvider);
      state = AsyncValue.error('Restore failed: $e', StackTrace.empty);
      return false;
    }
  }

  Future<void> signOut() async {
    await _service.signOut();
  }

  Future<bool> signIn() async {
    return await _service.signIn();
  }

  Future<List<Map<String, String>>> listCloudBackups() async {
    return await _service.listBackups();
  }

  Future<bool> restoreCloudBackup(String fileId) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    try {
      // 1. Download backup to temp file
      final tempFile = await _service.restoreFromId(fileId);
      if (tempFile == null) {
        state = const AsyncValue.error('Cloud restore failed', StackTrace.empty);
        return false;
      }

      // 2. Open both databases and merge
      final currentDb = _ref.read(databaseProvider);
      final backupDb = AppDatabase(executor: NativeDatabase(tempFile));
      try {
        await MergeService.mergeDatabases(currentDb, backupDb);
      } finally {
        await backupDb.close();
        try { await tempFile.delete(); } catch (_) {}
      }

      // 3. Invalidate provider so database re-initializes
      _ref.invalidate(databaseProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      _ref.invalidate(databaseProvider);
      state = const AsyncValue.error('Cloud restore failed', StackTrace.empty);
      return false;
    }
  }

  Future<bool> localBackup(File dbFile) async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
    } catch (_) {}
    final result = await _service.localBackup(dbFile);
    if (result) await _saveBackupTimestamp();
    state = result
        ? const AsyncValue.data(null)
        : const AsyncValue.error('Local backup failed', StackTrace.empty);
    return result;
  }

  Future<bool> localRestore() async {
    if (state.isLoading) return false;
    state = const AsyncValue.loading();
    try {
      // 1. Get backup file
      final tempFile = await _service.localRestore();
      if (tempFile == null) {
        state = const AsyncValue.error('Local restore failed', StackTrace.empty);
        return false;
      }

      // 2. Open both databases and merge
      final currentDb = _ref.read(databaseProvider);
      final backupDb = AppDatabase(executor: NativeDatabase(tempFile));
      try {
        await MergeService.mergeDatabases(currentDb, backupDb);
      } finally {
        await backupDb.close();
        try { await tempFile.delete(); } catch (_) {}
      }

      // 3. Invalidate provider so database re-initializes
      _ref.invalidate(databaseProvider);

      state = const AsyncValue.data(null);
      return true;
    } catch (e) {
      _ref.invalidate(databaseProvider);
      state = const AsyncValue.error('Local restore failed', StackTrace.empty);
      return false;
    }
  }
}

final backupNotifierProvider = StateNotifierProvider<BackupNotifier, AsyncValue<void>>((ref) {
  return BackupNotifier(ref.read(backupServiceProvider), ref);
});
