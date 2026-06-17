import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class DesktopAuthTokens {
  final String accessToken;
  final String? idToken;
  final String? refreshToken;

  DesktopAuthTokens({
    required this.accessToken,
    this.idToken,
    this.refreshToken,
  });
}

/// Handles Google OAuth 2.0 on desktop (Linux/Windows) using a local HTTP
/// server and xdg-open. Also persists the Google refresh token so that
/// subsequent Drive API calls work without re-opening the browser.
class DesktopOAuthService {
  final String clientId;
  final String clientSecret;
  final int redirectPort;
  final List<String> scopes;

  static const _kGoogleRefreshTokenKey = 'google_oauth_refresh_token';
  static const _storage = FlutterSecureStorage();

  DesktopOAuthService({
    required this.clientId,
    required this.clientSecret,
    this.redirectPort = 8000,
    this.scopes = const [
      'openid',
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  });

  /// Opens the browser-based Google OAuth flow and returns the tokens.
  /// Persists the refresh token for future silent re-auth.
  Future<DesktopAuthTokens?> signIn() async {
    HttpServer? server;
    try {
      server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        redirectPort,
      );

      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': 'http://localhost:$redirectPort',
        'scope': scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      log('oauth: opening browser for Google sign-in...');
      try {
        await Process.run('xdg-open', [authUrl.toString()]);
      } catch (e) {
        log('oauth: failed to open browser: $e');
        throw Exception(
          'Could not open browser. Please open this URL manually:\n${authUrl.toString()}',
        );
      }

      String? code;
      final completer = Completer<String?>();

      server.listen(
        (HttpRequest request) {
          final queryCode = request.uri.queryParameters['code'];
          if (queryCode != null) {
            code = queryCode;
            request.response.statusCode = 200;
            request.response.headers.set('Content-Type', 'text/html');
            request.response.write(
              '<html><body><h1>Sign-in complete!</h1>'
              '<p>You can close this tab and return to the app.</p></body></html>',
            );
            request.response.close();
            if (!completer.isCompleted) completer.complete(code);
          } else {
            request.response.statusCode = 200;
            request.response.write('OK');
            request.response.close();
          }
        },
        onError: (Object e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
      );

      code = await completer.future.timeout(const Duration(minutes: 5));
      if (code == null) {
        log('oauth: no auth code received');
        return null;
      }

      log('oauth: exchanging code for tokens...');
      final tokenResponse = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': code,
          'client_id': clientId,
          'client_secret': clientSecret,
          'redirect_uri': 'http://localhost:$redirectPort',
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        log(
          'oauth: token exchange failed: ${tokenResponse.statusCode} ${tokenResponse.body}',
        );
        return null;
      }

      final data = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
      final refreshToken = data['refresh_token'] as String?;

      // Persist the Google refresh token for silent Drive re-auth
      if (refreshToken != null) {
        await _storage.write(key: _kGoogleRefreshTokenKey, value: refreshToken);
      }

      log('oauth: sign-in successful');
      return DesktopAuthTokens(
        accessToken: data['access_token'] as String,
        idToken: data['id_token'] as String?,
        refreshToken: refreshToken,
      );
    } catch (e) {
      log('oauth: signIn error: $e');
      return null;
    } finally {
      try {
        await server?.close(force: true);
      } catch (_) {}
    }
  }

  /// Exchange a stored Google refresh token for a fresh access token.
  /// Returns null if no stored token or the exchange fails.
  Future<String?> tryRestoreAccessToken() async {
    try {
      final refreshToken = await _storage.read(key: _kGoogleRefreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return null;

      final response = await http.post(
        Uri.https('oauth2.googleapis.com', '/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'refresh_token': refreshToken,
          'grant_type': 'refresh_token',
        },
      );

      if (response.statusCode != 200) {
        log(
          'oauth: token refresh failed: ${response.statusCode} ${response.body}',
        );
        await _storage.delete(key: _kGoogleRefreshTokenKey);
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['access_token'] as String?;
    } catch (e) {
      log('oauth: tryRestoreAccessToken error: $e');
      return null;
    }
  }

  /// Clear stored Google tokens (called on sign-out).
  Future<void> clearTokens() async {
    await _storage.delete(key: _kGoogleRefreshTokenKey);
  }
}
