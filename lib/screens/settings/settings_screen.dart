import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../employees/employees_screen.dart';
import '../payroll/payroll_screen.dart';
import '../history/sales_history_screen.dart';
import '../reports/pdf_report_screen.dart';
import 'backup_screen.dart';
import 'app_lock_screen.dart';
import 'fuel_prices_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                subtitle: 'Manage staff and attendance',
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
                  Text('Version 1.0.0', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
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
