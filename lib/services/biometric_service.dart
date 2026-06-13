import 'dart:io';
import 'package:flutter/services.dart';

class BiometricService {
  static const _channel = MethodChannel('com.warraich.petroleum/biometric');

  Future<bool> isBiometricAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;
    try {
      final result = await _channel.invokeMethod<bool>('authenticate');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
