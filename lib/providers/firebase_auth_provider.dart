import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

final signInSkippedProvider = StateProvider<bool>((ref) => false);

final isSignedInProvider = Provider<bool>((ref) {
  final authState = ref.watch(firebaseAuthStateProvider);
  return authState.asData?.value ?? false;
});
