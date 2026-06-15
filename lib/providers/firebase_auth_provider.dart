import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/firebase_auth_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  final service = FirebaseAuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

final firebaseAuthStateProvider = StreamProvider<bool>((ref) {
  return ref.watch(firebaseAuthServiceProvider).authStateChanges;
});

final firebaseAuthUidProvider = Provider<String?>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  if (!(authState.asData?.value ?? false)) return null;
  return ref.watch(firebaseAuthServiceProvider).uid;
});

class _SignInSkippedNotifier extends StateNotifier<bool> {
  _SignInSkippedNotifier() : super(false) {
    _load();
  }

  static const _storage = FlutterSecureStorage();

  Future<void> _load() async {
    final val = await _storage.read(key: 'signInSkipped');
    if (val == 'true') state = true;
  }

  Future<void> set(bool value) async {
    state = value;
    await _storage.write(key: 'signInSkipped', value: value.toString());
  }
}

final signInSkippedProvider = StateNotifierProvider<_SignInSkippedNotifier, bool>(
  (ref) => _SignInSkippedNotifier(),
);

final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.asData?.value ?? false;
});
