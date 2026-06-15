import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/biometric_service.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref.read(biometricServiceProvider));
});

class AuthState {
  final bool isLocked;
  final bool isAuthenticated;
  final bool isLoading;
  final bool biometricEnabled;

  const AuthState({
    this.isLocked = false,
    this.isAuthenticated = true,
    this.isLoading = false,
    this.biometricEnabled = false,
  });

  AuthState copyWith({
    bool? isLocked,
    bool? isAuthenticated,
    bool? isLoading,
    bool? biometricEnabled,
  }) {
    return AuthState(
      isLocked: isLocked ?? this.isLocked,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}

class AuthStateNotifier extends StateNotifier<AuthState> {
  final BiometricService _biometricService;
  static const _storage = FlutterSecureStorage();
  static const _lockEnabledKey = 'app_lock_enabled';

  AuthStateNotifier(this._biometricService) : super(const AuthState());

  Future<void> init() async {
    final lockEnabled = await _storage.read(key: _lockEnabledKey);
    if (lockEnabled == 'true') {
      state = state.copyWith(biometricEnabled: true, isLocked: true, isAuthenticated: false);
      await authenticate();
    }
  }

  Future<void> authenticate() async {
    state = state.copyWith(isLoading: true);
    final result = await _biometricService.authenticate();
    state = state.copyWith(
      isLocked: !result,
      isAuthenticated: result,
      isLoading: false,
    );
  }

  Future<void> enableLock() async {
    await _storage.write(key: _lockEnabledKey, value: 'true');
    state = state.copyWith(biometricEnabled: true);
  }

  Future<void> disableLock() async {
    await _storage.write(key: _lockEnabledKey, value: 'false');
    state = state.copyWith(biometricEnabled: false, isLocked: false, isAuthenticated: true);
  }

  void lock() {
    if (state.biometricEnabled) {
      state = state.copyWith(isLocked: true, isAuthenticated: false);
    }
  }

  void unlock() {
    state = state.copyWith(isLocked: false, isAuthenticated: true);
  }
}
