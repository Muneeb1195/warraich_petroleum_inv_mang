import '../firebase_options.dart';

class AppConfig {
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
  );
  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
  );

  static String get firebaseApiKey =>
      DefaultFirebaseOptions.currentPlatform.apiKey;

  static bool get isGoogleDriveConfigured =>
      googleClientId.isNotEmpty && googleClientSecret.isNotEmpty;
}
