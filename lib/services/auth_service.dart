import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart'
    as gsap;
import '../config/app_config.dart';
import '../models/auth_user.dart';
import 'firebase_rest_auth.dart';
import 'desktop_oauth_service.dart';

class AuthService {
  late final gsap.GoogleSignIn _googleSignIn;
  late final FirebaseRestAuth _restAuth;
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  StreamSubscription<User?>? _authSubscription;

  DesktopOAuthService? _linuxOAuth;

  /// Last obtained OAuth access token for Linux (used by getDriveAccessToken).
  String? _linuxAccessToken;
  DateTime? _linuxAccessTokenExpiry;

  /// Cached Drive access token for mobile (Android/Windows) to avoid multiple
  /// sign-in popups during sequential calls (e.g. list + restore).
  String? _driveAccessToken;
  DateTime? _driveAccessTokenExpiry;

  /// Ensures session restore completes before the stream emits its first value,
  /// preventing a sign-in screen flash on restart.
  final Completer<void> _sessionCheckCompleter = Completer<void>();

  AuthService() {
    _restAuth = FirebaseRestAuth(AppConfig.firebaseApiKey);

    _googleSignIn = gsap.GoogleSignIn(
      params: gsap.GoogleSignInParams(
        clientId: AppConfig.googleClientId,
        clientSecret: AppConfig.googleClientSecret,
        scopes: [
          'email',
          'https://www.googleapis.com/auth/drive.file',
          'https://www.googleapis.com/auth/drive.appdata',
        ],
      ),
    );

    // Desktop OAuth service for Linux (uses xdg-open + HttpServer directly)
    if (!kIsWeb && Platform.isLinux) {
      _linuxOAuth = DesktopOAuthService(
        clientId: AppConfig.googleClientId,
        clientSecret: AppConfig.googleClientSecret,
      );
    }

    // ---- Session restore (Linux only) ----
    // Run BEFORE setting up streams so the restored user is available.
    _restoreSession();

    // ---- Firebase Auth listener (Android/Windows) ----
    try {
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
        _currentUser = user != null ? _fromFirebaseUser(user) : null;
        _userController.add(_currentUser);
      });
    } catch (_) {
      // Linux: no Firebase platform — session restore is handled by
      // _restoreSession(). Do NOT emit null here or complete the
      // completer — allow _restoreSession() to finish first.
    }
  }

  /// Try to restore a previous session from stored tokens.
  /// Also restores the Google Drive access token.
  Future<void> _restoreSession() async {
    if (kIsWeb || !Platform.isLinux) {
      _sessionCheckCompleter.complete();
      return;
    }

    // Restore Firebase user
    final user = await _restAuth.tryRestoreSession();
    if (user != null) {
      log('auth: session restored for ${user.email}');
      _currentUser = user;
      _userController.add(user);
    }

    // Restore Google Drive access token
    if (_linuxOAuth != null) {
      final token = await _linuxOAuth!.tryRestoreAccessToken();
      if (token != null) {
        _linuxAccessToken = token;
      }
    }

    // Notify the stream that initial check is done
    _sessionCheckCompleter.complete();
    if (_currentUser == null) {
      _currentUser = null;
      _userController.add(null);
    }
  }

  static AppUser _fromFirebaseUser(User user) {
    return AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  AppUser? get currentUser => _currentUser;

  /// Stream that emits the current user. On Linux, waits for session restore
  /// to complete before yielding the initial value, preventing a sign-in
  /// screen flash on restart.
  Stream<AppUser?> get authStateChanges async* {
    await _sessionCheckCompleter.future;
    yield _currentUser;
    yield* _userController.stream;
  }

  Future<AppUser?> signInWithGoogle() async {
    if (!AppConfig.isGoogleDriveConfigured) {
      log('auth: Google Sign-In not configured (missing client ID/secret)');
      return null;
    }

    try {
      String? idToken;
      String? accessToken;

      // ---- Step 1: Get Google OAuth tokens ----
      if (_linuxOAuth != null) {
        log('auth: using Linux desktop OAuth...');
        final tokens = await _linuxOAuth!.signIn();
        if (tokens == null) {
          log('auth: Linux OAuth returned null (cancelled?)');
          return null;
        }
        idToken = tokens.idToken;
        accessToken = tokens.accessToken;
      } else {
        // Android/Windows: use google_sign_in_all_platforms
        // Sign out first to force the account picker every time.
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        final credentials = await _googleSignIn.signIn();
        if (credentials == null) return null;
        idToken = credentials.idToken;
        accessToken = credentials.accessToken;
        _driveAccessToken = accessToken;
      }

      // ---- Step 2: Exchange Google tokens for Firebase Auth user ----
      AppUser? user;

      // Try Firebase SDK (works on Android/Windows, fails on Linux)
      try {
        final credential = GoogleAuthProvider.credential(
          accessToken: accessToken,
          idToken: idToken,
        );
        final result = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
        if (result.user != null) {
          user = _fromFirebaseUser(result.user!);
        }
      } catch (e) {
        log('auth: Firebase SDK sign-in failed, trying REST fallback: $e');
      }

      // REST fallback (Linux or if Firebase SDK fails)
      user ??= await _restAuth.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      if (user != null) {
        _currentUser = user;
        _userController.add(user);
        if (_linuxOAuth != null) {
          _linuxAccessToken = accessToken;
        }
      }

      return user;
    } catch (e) {
      log('auth: signInWithGoogle error: $e');
      return null;
    }
  }

  /// Returns a Google Drive access token. On Linux, first tries the cached
  /// access token, then attempts to refresh from the stored refresh token.
  Future<String?> getDriveAccessToken() async {
    try {
      if (_linuxOAuth != null) {
        if (_linuxAccessToken != null &&
            _linuxAccessTokenExpiry != null &&
            DateTime.now().isBefore(_linuxAccessTokenExpiry!)) {
          return _linuxAccessToken;
        }
        _linuxAccessToken = await _linuxOAuth!.tryRestoreAccessToken();
        if (_linuxAccessToken != null) {
          _linuxAccessTokenExpiry = DateTime.now().add(const Duration(hours: 1));
        }
        return _linuxAccessToken;
      }

      if (_driveAccessToken != null &&
          _driveAccessTokenExpiry != null &&
          DateTime.now().isBefore(_driveAccessTokenExpiry!)) {
        return _driveAccessToken;
      }

      final credentials = await _googleSignIn.lightweightSignIn();
      if (credentials == null) return null;
      _driveAccessToken = credentials.accessToken;
      _driveAccessTokenExpiry = DateTime.now().add(const Duration(hours: 1));
      return _driveAccessToken;
    } catch (e) {
      log('auth: getDriveAccessToken error: $e');
      return null;
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _userController.close();
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      log('auth: Google signOut error: $e');
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    await _restAuth.clearTokens();
    await _linuxOAuth?.clearTokens();

    _currentUser = null;
    _linuxAccessToken = null;
    _driveAccessToken = null;
    _userController.add(null);
  }
}
