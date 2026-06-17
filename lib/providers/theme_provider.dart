import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'theme_mode';
  bool _loaded = false;

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      const storage = FlutterSecureStorage();
      final value = await storage.read(key: _themeKey);
      if (!_loaded) {
        _loaded = true;
        if (value == 'light') {
          state = ThemeMode.light;
        } else if (value == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _loaded = true;
    state = mode;
    try {
      const storage = FlutterSecureStorage();
      await storage.write(key: _themeKey, value: mode.name);
    } catch (_) {}
  }
}
