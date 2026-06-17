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

  DesktopOAuthService? _linuxOAuth;

  String? _linuxAccessToken;
  DateTime? _linuxAccessTokenExpiry;
  String? _driveAccessToken;
  DateTime? _driveAccessTokenExpiry;

  final Completer<void> _sessionCheckCompleter = Completer<void>();
  StreamSubscription<User?>? _firebaseAuthSub;

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

    if (!kIsWeb && Platform.isLinux) {
      _linuxOAuth = DesktopOAuthService(
        clientId: AppConfig.googleClientId,
        clientSecret: AppConfig.googleClientSecret,
      );
    }

    _restoreSession();

    try {
      _firebaseAuthSub =
          FirebaseAuth.instance.authStateChanges().listen((user) {
        _currentUser = user != null ? _fromFirebaseUser(user) : null;
        _userController.add(_currentUser);
      });
    } catch (_) {
      // Linux: no Firebase platform — session restore is handled by
      // _restoreSession().
    }
  }

  Future<void> _restoreSession() async {
    if (kIsWeb || !Platform.isLinux) {
      if (!_sessionCheckCompleter.isCompleted) {
        _sessionCheckCompleter.complete();
      }
      return;
    }

    final user = await _restAuth.tryRestoreSession();
    if (user != null) {
      log('auth: session restored for ${user.email}');
      _currentUser = user;
      _userController.add(user);
    }

    if (_linuxOAuth != null) {
      final token = await _linuxOAuth!.tryRestoreAccessToken();
      if (token != null) {
        _linuxAccessToken = token;
      }
    }

    if (!_sessionCheckCompleter.isCompleted) {
      _sessionCheckCompleter.complete();
    }
    if (_currentUser == null) {
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
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        final credentials = await _googleSignIn.signIn();
        if (credentials == null) return null;
        idToken = credentials.idToken;
        accessToken = credentials.accessToken;
        _driveAccessToken = accessToken;
        _driveAccessTokenExpiry = DateTime.now().add(const Duration(hours: 1));
      }

      AppUser? user;

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

      user ??= await _restAuth.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
      );

      if (user != null) {
        _currentUser = user;
        _userController.add(user);
        if (_linuxOAuth != null) {
          _linuxAccessToken = accessToken;
          _linuxAccessTokenExpiry =
              DateTime.now().add(const Duration(hours: 1));
        }
      }

      return user;
    } catch (e) {
      log('auth: signInWithGoogle error: $e');
      return null;
    }
  }

  Future<String?> getDriveAccessToken() async {
    try {
      if (_linuxOAuth != null) {
        if (_linuxAccessToken != null &&
            _linuxAccessTokenExpiry != null &&
            DateTime.now().isBefore(_linuxAccessTokenExpiry!)) {
          return _linuxAccessToken;
        }
        _linuxAccessToken = await _linuxOAuth!.tryRestoreAccessToken();
        _linuxAccessTokenExpiry =
            _linuxAccessToken != null
                ? DateTime.now().add(const Duration(hours: 1))
                : null;
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
    _linuxAccessTokenExpiry = null;
    _driveAccessToken = null;
    _driveAccessTokenExpiry = null;
    _userController.add(null);
  }

  void dispose() {
    _firebaseAuthSub?.cancel();
    _userController.close();
  }
}
