import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/backup_provider.dart';
import 'providers/firebase_auth_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/sync_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/lock_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/sign_in_screen.dart';

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
      ref.read(firebaseAuthServiceProvider).trySilentSignIn();
      ref.read(authStateProvider.notifier).init();
      ref.read(backupNotifierProvider.notifier).initializeAutoBackup();
    });
    ref.listen(syncInitializerProvider, (_, __) {});
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
    final skipAuth = ref.watch(signInSkippedProvider);
    final isSignedIn = ref.watch(isSignedInProvider);

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
              if (!isSignedIn && !skipAuth) return const SignInScreen();
              return authState.isLocked ? const LockScreen() : const HomeShell();
            },
            loading: () {
              if (!isSignedIn && !skipAuth) return const SignInScreen();
              return authState.isLocked ? const LockScreen() : const HomeShell();
            },
            error: (_, _) {
              if (!isSignedIn && !skipAuth) return const SignInScreen();
              return authState.isLocked ? const LockScreen() : const HomeShell();
            },
          ),
        );
      },
    );
  }
}
