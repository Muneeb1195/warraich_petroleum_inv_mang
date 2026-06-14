import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';
import 'database_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupNotifier extends StateNotifier<AsyncValue<void>> {
  final BackupService _service;
  final Ref _ref;

  BackupNotifier(this._service, this._ref) : super(const AsyncValue.data(null));

  Future<bool> backupDatabase(File dbFile) async {
    state = const AsyncValue.loading();
    final result = await _service.backupDatabase(dbFile);
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
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.close();
    } catch (_) {}

    final result = await _service.restoreFromId(fileId);

    if (result) {
      _ref.invalidate(databaseProvider);
    }

    state = result
        ? const AsyncValue.data(null)
        : const AsyncValue.error('Cloud restore failed', StackTrace.empty);
    return result;
  }

  Future<bool> localBackup(File dbFile) async {
    state = const AsyncValue.loading();
    final result = await _service.localBackup(dbFile);
    state = result
        ? const AsyncValue.data(null)
        : const AsyncValue.error('Local backup failed', StackTrace.empty);
    return result;
  }

  Future<bool> localRestore() async {
    state = const AsyncValue.loading();
    try {
      final db = _ref.read(databaseProvider);
      await db.close();
    } catch (_) {}

    final result = await _service.localRestore();

    if (result != null) {
      _ref.invalidate(databaseProvider);
    }

    state = result != null
        ? const AsyncValue.data(null)
        : const AsyncValue.error('Local restore failed', StackTrace.empty);
    return result != null;
  }
}

final backupNotifierProvider = StateNotifierProvider<BackupNotifier, AsyncValue<void>>((ref) {
  return BackupNotifier(ref.watch(backupServiceProvider), ref);
});
