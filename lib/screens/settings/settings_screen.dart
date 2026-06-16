import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/format_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/error_logger.dart';
import '../../utils/error_utils.dart';
import '../../utils/constants.dart';
import '../../utils/responsive.dart';
import 'help_screen.dart';
import 'backup_screen.dart';
import 'app_lock_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: isWide(context)
          ? _buildDesktopLayout(context, ref, colorScheme)
          : _buildMobileLayout(context, ref, colorScheme),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _buildMenuSections(context, ref, colorScheme),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: _buildMenuSections(context, ref, colorScheme),
        ),
      ),
    );
  }

  List<Widget> _buildMenuSections(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return [
      _MenuSection(
        title: 'Settings',
        items: [
          _MenuItem(
            icon: Icons.cloud_upload,
            title: 'Backup & Restore',
            subtitle: 'Backup management',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          if (Platform.isAndroid || Platform.isIOS)
            _MenuItem(
              icon: Icons.lock,
              title: 'App Lock',
              subtitle: 'Configure biometric lock',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppLockScreen())),
            ),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Help & Guide',
            subtitle: 'Learn how to use the app',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
          ),
          _MenuItem(
            icon: Icons.bug_report,
            title: 'View Error Log',
            subtitle: 'Check for any recorded errors',
            onTap: () => _showErrorLog(context),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Icon(Icons.dark_mode, color: colorScheme.primary, size: 20), const SizedBox(width: 8), Text('Theme', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))]),
              const SizedBox(height: 12),
              _ThemeSelector(ref: ref),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: SwitchListTile(
          secondary: Icon(Icons.format_paint, color: colorScheme.primary),
          title: const Text('Abbreviate Amounts'),
          subtitle: const Text('Show abbreviated amounts (e.g. 1.2L)'),
          value: ref.watch(abbreviateAmountsProvider),
          onChanged: (value) => ref.read(abbreviateAmountsProvider.notifier).setAbbreviate(value),
        ),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.local_gas_station, size: 48, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text(kAppName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => Text(
                  'Version ${snapshot.data?.version ?? "..."}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 12),
              Text('Built by Software Works', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text('Developer: Muneeb Saeed', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text('Contact: 03156525591', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    ];
  }

  void _showErrorLog(BuildContext context) async {
    String logContent;
    try {
      logContent = await ErrorLogger.getLogContent();
    } catch (e) {
      if (context.mounted) context.showError(e, source: 'getLogContent');
      return;
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error Log'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              logContent,
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await ErrorLogger.clearLog();
              } catch (_) {}
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Clear Log'),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Column(children: items.map((item) {
            return ListTile(
              leading: Icon(item.icon),
              title: Text(item.title),
              subtitle: Text(item.subtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: item.onTap,
            );
          }).toList()),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
}

class _ThemeSelector extends ConsumerWidget {
  final WidgetRef ref;

  const _ThemeSelector({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final mode = ref.watch(themeModeProvider);
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto), label: Text('Auto')),
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode), label: Text('Light')),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode), label: Text('Dark')),
      ],
      selected: {mode},
      onSelectionChanged: (value) => ref.read(themeModeProvider.notifier).setThemeMode(value.first),
    );
  }
}
