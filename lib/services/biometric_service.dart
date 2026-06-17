import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:local_auth/local_auth.dart';
import '../utils/constants.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return true;
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access $kAppName',
        biometricOnly: false,
      );
    } catch (e) {
      return false;
    }
  }
}
