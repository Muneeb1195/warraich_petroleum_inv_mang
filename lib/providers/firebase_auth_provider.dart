import 'dart:async';
import 'dart:developer' show log;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final firebaseAuthUserProvider = StreamProvider<AppUser?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class FirebaseSignInNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  FirebaseSignInNotifier(this._authService)
    : super(const AsyncValue.loading()) {
    _init();
  }

  final AuthService _authService;
  StreamSubscription<AppUser?>? _authSub;

  void _init() {
    state = AsyncValue.data(_authService.currentUser);
    _authSub = _authService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        log('auth: signed in as ${user.email}');
        return true;
      }
      log('auth: sign-in cancelled or failed');
      state = AsyncValue.data(_authService.currentUser);
      return false;
    } catch (e, st) {
      log('auth: signInWithGoogle error: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AsyncValue.data(null);
  }
}

final firebaseSignInProvider =
    StateNotifierProvider<FirebaseSignInNotifier, AsyncValue<AppUser?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return FirebaseSignInNotifier(authService);
    });
