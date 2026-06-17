import 'dart:convert';
import 'dart:developer' show log;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';

class FirebaseRestAuth {
  final String _apiKey;
  static const _kRefreshTokenKey = 'firebase_refresh_token';
  static const _kIdTokenKey = 'firebase_id_token';
  static const _storage = FlutterSecureStorage();

  FirebaseRestAuth(this._apiKey);

  /// Exchange a Google OAuth token for a Firebase Auth user.
  /// Persists the refresh token so the session survives app restarts.
  Future<AppUser?> signInWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    if (idToken == null && accessToken == null) {
      log('rest_auth: no token provided');
      return null;
    }

    try {
      final tokenField = idToken != null ? 'id_token' : 'access_token';
      final token = idToken ?? accessToken!;
      final postBody = '$tokenField=$token&providerId=google.com';

      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key=$_apiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'postBody': postBody,
          'requestUri': 'http://localhost',
          'returnIdpCredential': true,
          'returnSecureToken': true,
        }),
      );
      if (response.statusCode != 200) {
        log(
          'rest_auth: signInWithIdp failed: ${response.statusCode}',
        );
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final firebaseIdToken = data['idToken'] as String?;
      final refreshToken = data['refreshToken'] as String?;
      if (firebaseIdToken == null) {
        log('rest_auth: signInWithIdp missing idToken');
        return null;
      }

      // Persist tokens for session restore on next launch
      if (refreshToken != null) {
        await _storage.write(key: _kRefreshTokenKey, value: refreshToken);
      }
      await _storage.write(key: _kIdTokenKey, value: firebaseIdToken);

      return await _lookupUser(firebaseIdToken);
    } catch (e) {
      log('rest_auth: signInWithGoogle error: $e');
      return null;
    }
  }

  /// Try to restore a previous session from stored tokens.
  /// Returns the user if successful, null otherwise.
  Future<AppUser?> tryRestoreSession() async {
    try {
      final refreshToken = await _storage.read(key: _kRefreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        log('rest_auth: no stored refresh token');
        return null;
      }

      // Exchange the refresh token for a fresh idToken
      final freshIdToken = await _refreshIdToken(refreshToken);
      if (freshIdToken == null) {
        log('rest_auth: refresh failed, clearing stored tokens');
        await _storage.delete(key: _kRefreshTokenKey);
        await _storage.delete(key: _kIdTokenKey);
        return null;
      }

      await _storage.write(key: _kIdTokenKey, value: freshIdToken);
      return await _lookupUser(freshIdToken);
    } catch (e) {
      log('rest_auth: tryRestoreSession error: $e');
      return null;
    }
  }

  Future<String?> _refreshIdToken(String refreshToken) async {
    try {
      final url = Uri.parse(
        'https://securetoken.googleapis.com/v1/token?key=$_apiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );
      if (response.statusCode != 200) {
        log(
          'rest_auth: refresh failed: ${response.statusCode}',
        );
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['id_token'] as String?;
    } catch (e) {
      log('rest_auth: _refreshIdToken error: $e');
      return null;
    }
  }

  Future<AppUser?> _lookupUser(String idToken) async {
    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$_apiKey',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );
      if (response.statusCode != 200) {
        log(
          'rest_auth: lookup failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final users = data['users'] as List?;
      if (users == null || users.isEmpty) return null;
      final user = users[0] as Map<String, dynamic>;
      return AppUser(
        uid: user['localId'] as String? ?? '',
        email: user['email'] as String?,
        displayName: user['displayName'] as String?,
        photoURL: user['photoUrl'] as String?,
      );
    } catch (e) {
      log('rest_auth: lookupUser error: $e');
      return null;
    }
  }

  /// Clear stored tokens when signing out.
  Future<void> clearTokens() async {
    await _storage.delete(key: _kRefreshTokenKey);
    await _storage.delete(key: _kIdTokenKey);
  }
}
