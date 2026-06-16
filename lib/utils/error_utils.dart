import 'package:flutter/material.dart';
import '../services/error_logger.dart';

extension SnackbarUtils on BuildContext {
  void showSuccess(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(this).colorScheme.primary,
    ));
  }

  void showError(dynamic error, {String? source}) {
    final message = error.toString();
    ErrorLogger.log(message, source: source);
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Theme.of(this).colorScheme.error,
    ));
  }
}

