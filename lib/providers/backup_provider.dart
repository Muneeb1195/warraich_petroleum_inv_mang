import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService();
});

class BackupNotifier extends StateNotifier<AsyncValue<void>> {
  final BackupService _service;

  BackupNotifier(this._service) : super(const AsyncValue.data(null));

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
    final result = await _service.restoreLatestBackup();
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
}

final backupNotifierProvider = StateNotifierProvider<BackupNotifier, AsyncValue<void>>((ref) {
  return BackupNotifier(ref.watch(backupServiceProvider));
});
