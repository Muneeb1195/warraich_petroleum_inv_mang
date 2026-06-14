import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../providers/theme_provider.dart';
import '../employees/employees_screen.dart';
import '../payroll/payroll_screen.dart';
import '../history/sales_history_screen.dart';
import '../reports/pdf_report_screen.dart';
import '../../services/error_logger.dart';
import 'help_screen.dart';
import 'backup_screen.dart';
import 'app_lock_screen.dart';
import 'fuel_prices_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentMode,
              onChanged: (value) {
                if (value == null) return;
                ref.read(themeModeProvider.notifier).setThemeMode(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentMode,
              onChanged: (value) {
                if (value == null) return;
                ref.read(themeModeProvider.notifier).setThemeMode(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentMode,
              onChanged: (value) {
                if (value == null) return;
                ref.read(themeModeProvider.notifier).setThemeMode(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _isDesktop
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
      if (!_isDesktop) ...[
        _MenuSection(
          title: 'Management',
          items: [
            _MenuItem(
              icon: Icons.local_gas_station,
              title: 'Fuel Prices',
              subtitle: 'Manage product prices',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FuelPricesScreen())),
            ),
            _MenuItem(
              icon: Icons.people,
              title: 'Employees',
                  subtitle: 'Manage staff',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen())),
            ),
            _MenuItem(
              icon: Icons.payments,
              title: 'Payroll',
              subtitle: 'Generate and manage payroll',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen())),
            ),
            _MenuItem(
              icon: Icons.history,
              title: 'Sales History',
              subtitle: 'View all past shifts',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MenuSection(
          title: 'Reports',
          items: [
            _MenuItem(
              icon: Icons.picture_as_pdf,
              title: 'Generate Report',
              subtitle: 'Create PDF reports',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfReportScreen())),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
      _MenuSection(
        title: 'Settings',
        items: [
          _MenuItem(
            icon: Icons.local_gas_station,
            title: 'Fuel Prices',
            subtitle: 'Manage product prices',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FuelPricesScreen())),
          ),
          _MenuItem(
            icon: Icons.cloud_upload,
            title: 'Backup & Restore',
            subtitle: 'Backup management',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupScreen())),
          ),
          _MenuItem(
            icon: Icons.dark_mode,
            title: 'Theme',
            subtitle: 'Switch between light and dark mode',
            onTap: () => _showThemeDialog(context, ref),
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
            children: [
              Icon(Icons.local_gas_station, size: 48, color: colorScheme.primary),
              const SizedBox(height: 8),
              Text('Warraich Petroleum', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) => Text(
                  'Version ${snapshot.data?.version ?? "..."}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  void _showErrorLog(BuildContext context) async {
    final logContent = await ErrorLogger.getLogContent();
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
              await ErrorLogger.clearLog();
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
