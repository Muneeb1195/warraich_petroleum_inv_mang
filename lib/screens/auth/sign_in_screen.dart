import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/firebase_auth_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_sync_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Cloud Sync',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to sync your data across devices.\nYou can skip this and use the app locally.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 48),
              FilledButton.icon(
                onPressed: () async {
                  final auth = ref.read(firebaseAuthServiceProvider);
                  final signedIn = await auth.signInWithGoogle();
                  if (signedIn && context.mounted) {
                    // Wait for auth state to propagate, then trigger full sync
                    await Future.microtask(() {});
                    ref.invalidate(syncInitializerProvider);
                    await ref.read(syncInitializerProvider.future);
                    ref.read(authStateProvider.notifier).unlock();
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  ref.read(signInSkippedProvider.notifier).state = true;
                },
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
