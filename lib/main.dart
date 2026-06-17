import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:window_manager/window_manager.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'services/error_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    log('Firebase initialization skipped: $e');
  }

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(900, 600),
      center: true,
      title: kAppName,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    ErrorLogger.log(
      details.exceptionAsString(),
      source: 'FlutterError',
      stackTrace: details.stack,
    );
  };

  runZonedGuarded(
    () {
      runApp(const ProviderScope(child: WarraichPetroleumApp()));
    },
    (error, stack) {
      log('Uncaught async error: $error', stackTrace: stack);
      ErrorLogger.log(
        error.toString(),
        source: 'AsyncError',
        stackTrace: stack,
      );
    },
  );
}
