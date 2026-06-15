import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isMobile = Platform.isAndroid || Platform.isIOS;

    Widget body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!isMobile) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.desktop_windows, size: 48, color: colorScheme.onSurfaceVariant),
                  const SizedBox(height: 16),
                  Text('App Lock is not available on desktop', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Biometric authentication is only supported on mobile devices.', style: TextStyle(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [Icon(Icons.fingerprint, color: colorScheme.primary), const SizedBox(width: 8), Text('Biometric Lock', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Text('Lock the app behind your phone\'s fingerprint or face unlock.', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(authState.biometricEnabled ? 'Disable App Lock' : 'Enable App Lock'),
            subtitle: Text(authState.biometricEnabled ? 'App is locked. Authentication required on launch.' : 'App is unlocked. No authentication required.'),
            value: authState.biometricEnabled,
            onChanged: (value) async {
              try {
                if (value) {
                  final biometricService = ref.read(biometricServiceProvider);
                  if (!await biometricService.authenticate()) return;
                  await ref.read(authStateProvider.notifier).enableLock();
                } else {
                  final biometricService = ref.read(biometricServiceProvider);
                  if (!await biometricService.authenticate()) return;
                  await ref.read(authStateProvider.notifier).disableLock();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(value ? 'App lock enabled' : 'App lock disabled'),
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              }
            },
          ),
          const Divider(),
          ListTile(leading: const Icon(Icons.info_outline), title: const Text('How it works'), subtitle: const Text('When enabled, the app will ask for your fingerprint or face every time you open or return to the app. You can disable it anytime from this screen.')),
        ],
      ],
    );

    if (_isDesktop) {
      body = Center(
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body),
      );
    }

    return Scaffold(appBar: AppBar(title: const Text('App Lock')), body: body);
  }
}
