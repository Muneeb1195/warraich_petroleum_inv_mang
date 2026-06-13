import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/lock_screen.dart';
import 'screens/home_shell.dart';

class WarraichPetroleumApp extends ConsumerStatefulWidget {
  const WarraichPetroleumApp({super.key});

  @override
  ConsumerState<WarraichPetroleumApp> createState() => _WarraichPetroleumAppState();
}

class _WarraichPetroleumAppState extends ConsumerState<WarraichPetroleumApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Warraich Petroleum',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: themeMode,
          home: authState.isLocked ? const LockScreen() : const HomeShell(),
        );
      },
    );
  }
}
