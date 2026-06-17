import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ErrorLogger {
  static const _fileName = 'error_log.txt';
  static const _maxLogSize = 512 * 1024; // 512KB
  static Future<void>? _writeMutex;

  static Future<File> get _logFile async {
    Directory? dir;
    try {
      dir = await getExternalStorageDirectory();
    } catch (_) {}
    dir ??= await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<void> log(
    String message, {
    String? source,
    StackTrace? stackTrace,
  }) async {
    final prev = _writeMutex;
    final completer = Completer<void>();
    _writeMutex = completer.future;
    await prev;

    try {
      final file = await _logFile;
      final timestamp = DateTime.now().toIso8601String();
      final buffer = StringBuffer();
      buffer.writeln('[$timestamp] $source: $message');
      if (stackTrace != null) {
        buffer.writeln(stackTrace.toString().split('\n').take(10).join('\n'));
      }
      buffer.writeln('---');

      // Truncate if too large
      if (await file.exists() && await file.length() > _maxLogSize) {
        final content = await file.readAsString();
        final lines = content.split('\n');
        final trimmed = lines.sublist(lines.length ~/ 2).join('\n');
        await file.writeAsString(trimmed);
      }

      await file.writeAsString(buffer.toString(), mode: FileMode.append);
    } catch (_) {
      // Don't let logging failures crash the app
    } finally {
      completer.complete();
    }
  }

  static Future<String> getLogContent() async {
    try {
      final file = await _logFile;
      if (!await file.exists()) return 'No error log found.';
      return await file.readAsString();
    } catch (_) {
      return 'Failed to read error log.';
    }
  }

  static Future<void> clearLog() async {
    try {
      final file = await _logFile;
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
