class AppConfig {
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'REDACTED_FIREBASE_KEY',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: 'REDACTED_GOOGLE_CLIENT_ID',
  );

  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: 'REDACTED_GOOGLE_SECRET',
  );
}
