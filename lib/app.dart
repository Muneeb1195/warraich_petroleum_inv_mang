import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/lock_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';

class WarraichPetroleumApp extends ConsumerStatefulWidget {
  const WarraichPetroleumApp({super.key});

  @override
  ConsumerState<WarraichPetroleumApp> createState() => _WarraichPetroleumAppState();
}

class _WarraichPetroleumAppState extends ConsumerState<WarraichPetroleumApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authStateProvider.notifier).init();
      ref.read(backupNotifierProvider.notifier).initializeAutoBackup();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      ref.read(authStateProvider.notifier).lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final onboarding = ref.watch(onboardingProvider);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          title: 'Warraich Petroleum',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(lightDynamic),
          darkTheme: AppTheme.dark(darkDynamic),
          themeMode: themeMode,
          home: onboarding.when(
            data: (completed) {
              if (!completed) return const OnboardingScreen();
              return authState.isLocked ? const LockScreen() : const HomeShell();
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => authState.isLocked ? const LockScreen() : const HomeShell(),
          ),
        );
      },
    );
  }
}
