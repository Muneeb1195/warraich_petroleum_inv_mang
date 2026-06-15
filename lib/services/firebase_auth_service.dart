import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart' as gsap;
import 'package:google_sign_in_all_platforms_desktop/google_sign_in_all_platforms_desktop.dart';
import 'package:google_sign_in/google_sign_in.dart' as gs;
import '../config/app_config.dart';

class FirebaseAuthService {
  static const String _apiKey = 'REDACTED_FIREBASE_KEY';
  static const String _databaseURL =
      'https://com-warraich-petroleum-default-rtdb.asia-southeast1.firebasedatabase.app';

  gsap.GoogleSignIn? _desktopSignIn;
  bool _androidInitialized = false;
  String? _idToken;
  String? _refreshToken;
  String? _uid;
  DateTime? _tokenExpiresAt;

  final _authStateController = StreamController<bool>.broadcast();
  Stream<bool> get authStateChanges => _authStateController.stream;

  bool get isSignedIn => _uid != null;
  String? get uid => _uid;

  Future<bool> signInWithGoogle() async {
    try {
      String? googleIdToken;

      if (Platform.isAndroid) {
        log('google_auth: signing in on Android');
        googleIdToken = await _signInAndroid();
      } else {
        log('google_auth: signing in on desktop');
        googleIdToken = await _signInDesktop();
      }

      if (googleIdToken == null) {
        log('google_auth: got null idToken');
        return false;
      }

      log('google_auth: got Google ID token, exchanging with Firebase...');
      final exchanged = await _exchangeToken(googleIdToken);
      if (!exchanged) {
        log('google_auth: token exchange FAILED');
        return false;
      }

      log('google_auth: signed in, uid=$_uid');
      const storage = FlutterSecureStorage();
      if (_uid != null) await storage.write(key: 'firebase_uid', value: _uid);
      if (_refreshToken != null) await storage.write(key: 'firebase_refresh_token', value: _refreshToken);
      _authStateController.add(true);
      return true;
    } catch (e, s) {
      log('google_auth: error: $e\n$s');
      _idToken = null;
      _uid = null;
      return false;
    }
  }

  Future<String?> _signInAndroid() async {
    if (!_androidInitialized) {
      try {
        await gs.GoogleSignIn.instance.initialize();
        _androidInitialized = true;
      } catch (e) {
        log('google_auth: android init error: $e');
        return null;
      }
    }
    try {
      final account = await gs.GoogleSignIn.instance.authenticate();
      log('google_auth: android authenticate succeeded, email=${account.email}');
      return account.authentication.idToken;
    } catch (e) {
      log('google_auth: android authenticate error: $e');
      return null;
    }
  }

  bool _desktopRegistered = false;

  gsap.GoogleSignInParams get _desktopAuthParams => gsap.GoogleSignInParams(
    clientId: AppConfig.googleClientId,
    clientSecret: AppConfig.googleClientSecret,
    scopes: ['openid', 'email', 'profile'],
    saveAccessToken: (token) async {
      const storage = FlutterSecureStorage();
      await storage.write(key: 'google_sign_in_token', value: token);
    },
    retrieveAccessToken: () async {
      const storage = FlutterSecureStorage();
      return storage.read(key: 'google_sign_in_token');
    },
    deleteAccessToken: () async {
      const storage = FlutterSecureStorage();
      await storage.delete(key: 'google_sign_in_token');
    },
  );

  Future<String?> _signInDesktop() async {
    if (!_desktopRegistered) {
      GoogleSignInAllPlatformsDesktop.registerWith();
      _desktopRegistered = true;
    }
    _desktopSignIn ??= gsap.GoogleSignIn(params: _desktopAuthParams);
    try {
      final creds = await _desktopSignIn!.signIn();
      log('google_auth: desktop signIn returned creds=${creds != null} idToken=${creds?.idToken != null}');
      return creds?.idToken;
    } catch (e) {
      log('google_auth: desktop signIn error: $e');
      return null;
    }
  }

  Future<bool> _exchangeToken(String googleIdToken) async {
    final encodedToken = Uri.encodeQueryComponent(googleIdToken);
    final body = jsonEncode({
      'postBody': 'id_token=$encodedToken&providerId=google.com',
      'requestUri': 'http://localhost',
      'returnSecureToken': true,
    });
    log('google_auth: exchanging token...');
    try {
      final response = await http.post(
        Uri.parse(
            'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$_apiKey'),
        body: body,
        headers: {'Content-Type': 'application/json'},
      );
      log('google_auth: exchange response ${response.statusCode}');
      if (response.statusCode != 200) {
        log('google_auth: exchange failed: ${response.body}');
        return false;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _idToken = data['idToken'] as String?;
      _refreshToken = data['refreshToken'] as String?;
      _uid = data['localId'] as String?;
      final expiresIn = data['expiresIn'] as String?;
      if (expiresIn != null) {
        _tokenExpiresAt = DateTime.now().add(Duration(seconds: int.parse(expiresIn)));
      } else {
        _tokenExpiresAt = DateTime.now().add(const Duration(hours: 1));
      }
      log('google_auth: exchange OK, uid=$_uid idToken=${_idToken?.substring(0, 20)}...');
      return _uid != null;
    } catch (e) {
      log('google_auth: exchange error: $e');
      return false;
    }
  }

  Future<bool> _refreshIdToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse(
            'https://securetoken.googleapis.com/v1/token?key=$_apiKey'),
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _idToken = data['id_token'] as String?;
        _refreshToken = data['refresh_token'] as String?;
        _uid = data['user_id'] as String?;
        final expiresIn = data['expires_in'] as String?;
        if (expiresIn != null) {
          _tokenExpiresAt = DateTime.now().add(Duration(seconds: int.parse(expiresIn)));
        } else {
          _tokenExpiresAt = DateTime.now().add(const Duration(hours: 1));
        }
        const storage = FlutterSecureStorage();
        if (_refreshToken != null) {
          await storage.write(key: 'firebase_refresh_token', value: _refreshToken);
        }
        if (_uid != null) {
          await storage.write(key: 'firebase_uid', value: _uid);
        }
        return _idToken != null && _uid != null;
      }
    } catch (e) {
      log('google_auth: refresh error: $e');
    }
    return false;
  }

  Future<Map<String, dynamic>?> getData(String path) async {
    final result = await _request('GET', path);
    return result.isEmpty ? null : result;
  }

  Future<void> putData(String path, Map<String, dynamic> data) async =>
      _request('PUT', path, body: data);

  Future<void> patchData(String path, Map<String, dynamic> data) async =>
      _request('PATCH', path, body: data);

  Future<void> deleteData(String path) async =>
      _request('DELETE', path);

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Object? body,
  }) async {
    if (_idToken != null && _tokenExpiresAt != null &&
        DateTime.now().isAfter(_tokenExpiresAt!.subtract(const Duration(minutes: 5)))) {
      final refreshed = await _refreshIdToken();
      if (!refreshed) {
        log('sync_req: token refresh failed, clearing auth state');
        return {};
      }
    }

    final url = _idToken != null
        ? '$_databaseURL/$path.json?auth=$_idToken'
        : '$_databaseURL/$path.json';
    final uri = Uri.parse(url);
    final headers = <String, String>{'Content-Type': 'application/json'};

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'PATCH':
          response = await http
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception('Unsupported method: $method');
      }
    } on TimeoutException {
      log('sync_req: $method $path timed out');
      throw Exception('RTDB $method $path timed out');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      log('sync_req: $method $path failed ${response.statusCode}: ${response.body}');
      throw Exception(
          'RTDB $method $path failed: ${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded == null) return {};
    return {};
  }

  Future<bool> trySilentSignIn() async {
    try {
      const storage = FlutterSecureStorage();
      final savedRefreshToken = await storage.read(key: 'firebase_refresh_token');
      final savedUid = await storage.read(key: 'firebase_uid');

      if (savedRefreshToken != null && savedUid != null) {
        _refreshToken = savedRefreshToken;
        _uid = savedUid;
        final refreshed = await _refreshIdToken();
        if (refreshed) {
          log('google_auth: silent sign-in OK, uid=$_uid');
          _authStateController.add(true);
          return true;
        }
        log('google_auth: silent sign-in refresh FAILED, clearing tokens');
        await storage.deleteAll();
        _uid = null;
        _refreshToken = null;
        return false;
      }

      if (!Platform.isAndroid) {
        if (!_desktopRegistered) {
          GoogleSignInAllPlatformsDesktop.registerWith();
          _desktopRegistered = true;
        }
        _desktopSignIn ??= gsap.GoogleSignIn(params: _desktopAuthParams);
        final creds = await _desktopSignIn!.silentSignIn();
        if (creds?.idToken == null) return false;
        final exchanged = await _exchangeToken(creds!.idToken!);
        if (exchanged) _authStateController.add(true);
        return exchanged;
      }

      return false;
    } catch (e) {
      log('google_auth: silent sign-in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    _idToken = null;
    _refreshToken = null;
    _uid = null;
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'firebase_uid');
    await storage.delete(key: 'firebase_refresh_token');
    _authStateController.add(false);
  }

  void dispose() {
    _authStateController.close();
  }
}
