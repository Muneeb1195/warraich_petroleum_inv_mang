import 'package:flutter_test/flutter_test.dart';
import 'package:warraich_petroleum/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('isGoogleDriveConfigured returns false when credentials are empty', () {
      // String.fromEnvironment returns '' when not provided via --dart-define
      // In test environment, no --dart-define is passed, so both are empty
      expect(AppConfig.googleClientId, isEmpty);
      expect(AppConfig.googleClientSecret, isEmpty);
      expect(AppConfig.isGoogleDriveConfigured, isFalse);
    });
  });
}
