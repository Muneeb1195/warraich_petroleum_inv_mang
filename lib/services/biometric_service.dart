import 'dart:io';
import 'package:local_auth/local_auth.dart';
import '../utils/constants.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access $kAppName',
        biometricOnly: true,
      );
    } catch (e) {
      return false;
    }
  }
}
