class AppConfig {
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleClientSecret = String.fromEnvironment(
    'GOOGLE_CLIENT_SECRET',
    defaultValue: '',
  );
}
