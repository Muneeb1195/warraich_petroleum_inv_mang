import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';
import 'firebase_auth_provider.dart';

final syncServiceProvider = Provider<SyncService?>((ref) {
  final auth = ref.watch(firebaseAuthServiceProvider);
  final db = ref.watch(databaseProvider);
  final uid = ref.watch(firebaseAuthUidProvider);
  if (uid == null) return null;
  final service = SyncService(auth, db, uid);
  ref.onDispose(() => service.dispose());
  return service;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  final service = ref.watch(syncServiceProvider);
  return service?.statusStream ?? Stream<SyncStatus>.value(SyncStatus.idle);
});

final syncInitializerProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(firebaseAuthUidProvider);
  if (uid == null) return;
  final service = ref.watch(syncServiceProvider);
  if (service != null) {
    await service.initialize();
  }
});
