import 'package:flutter/services.dart';

class BiometricService {
  static const _channel = MethodChannel('com.warraich.petroleum/biometric');

  Future<bool> isBiometricAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      final result = await _channel.invokeMethod<bool>('authenticate');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
