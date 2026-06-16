class AppConfig {
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');
  static const String googleClientSecret = String.fromEnvironment('GOOGLE_CLIENT_SECRET');

  static bool get isGoogleDriveConfigured =>
      googleClientId.isNotEmpty && googleClientSecret.isNotEmpty;
}
