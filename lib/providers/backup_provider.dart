import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../services/backup_service.dart';
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

    await _tryAutoBackup();

    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(const Duration(hours: 1), (_) async {
      await _tryAutoBackup();
    });
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
      // 1. Close the active database connection
      final db = _ref.read(databaseProvider);
      await db.close();
    } catch (_) {
      // Ignore if DB is already closed
    }

    // 2. Perform restoration
    final result = await _service.restoreLatestBackup();

    // 3. Invalidate provider so database re-initializes on next query
    if (result) {
      _ref.invalidate(databaseProvider);
    }

    state = result
        ? const AsyncValue.data(null)
        : const AsyncValue.error('Restore failed', StackTrace.empty);
    return result;
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
      // Close DB with timeout — don't let it hang forever
      try {
        final db = _ref.read(databaseProvider);
        await db.close().timeout(const Duration(seconds: 5));
      } catch (_) {}
      // Clean up WAL/SHM files
      try {
        final dir = await getApplicationDocumentsDirectory();
        final dbPath = p.join(dir.path, 'warraich_petroleum.db');
        await File('$dbPath-wal').delete();
        await File('$dbPath-shm').delete();
      } catch (_) {}

      final result = await _service.restoreFromId(fileId);

      // Always recreate DB connection
      _ref.invalidate(databaseProvider);

      state = result
          ? const AsyncValue.data(null)
          : const AsyncValue.error('Cloud restore failed', StackTrace.empty);
      return result;
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
      // Close DB with timeout
      try {
        final db = _ref.read(databaseProvider);
        await db.close().timeout(const Duration(seconds: 5));
      } catch (_) {}
      // Clean up WAL/SHM
      try {
        final dir = await getApplicationDocumentsDirectory();
        final dbPath = p.join(dir.path, 'warraich_petroleum.db');
        await File('$dbPath-wal').delete();
        await File('$dbPath-shm').delete();
      } catch (_) {}

      File? result;
      try {
        result = await _service.localRestore();
      } catch (_) {}

      // Always recreate DB connection
      _ref.invalidate(databaseProvider);

      state = result != null
          ? const AsyncValue.data(null)
          : const AsyncValue.error('Local restore failed', StackTrace.empty);
      return result != null;
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
