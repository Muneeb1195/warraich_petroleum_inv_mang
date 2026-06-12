import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('App Lock')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fingerprint, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Biometric Lock',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lock the app behind your phone\'s fingerprint or face unlock.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Enable App Lock'),
            subtitle: Text(
              authState.biometricEnabled
                  ? 'App is locked. Authentication required on launch.'
                  : 'App is unlocked. No authentication required.',
            ),
            value: authState.biometricEnabled,
            onChanged: (value) async {
              final biometricService = ref.read(biometricServiceProvider);
              final authenticated = await biometricService.authenticate();
              if (!authenticated) return;

              if (value) {
                await ref.read(authStateProvider.notifier).enableLock();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App lock enabled')),
                  );
                }
              } else {
                await ref.read(authStateProvider.notifier).disableLock();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('App lock disabled')),
                  );
                }
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('How it works'),
            subtitle: const Text(
              'When enabled, the app will ask for your fingerprint or face every time you open or return to the app. You can disable it anytime from this screen.',
            ),
          ),
        ],
      ),
    );
  }
}
