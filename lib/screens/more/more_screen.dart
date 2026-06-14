import 'package:flutter/material.dart';
import '../employees/employees_screen.dart';
import '../payroll/payroll_screen.dart';
import '../history/sales_history_screen.dart';
import '../reports/pdf_report_screen.dart';
import '../settings/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreItem(
            icon: Icons.people,
            title: 'Employees',
            subtitle: 'Manage staff',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen())),
          ),
          _MoreItem(
            icon: Icons.payments,
            title: 'Payroll',
            subtitle: 'Generate and manage payroll',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen())),
          ),
          _MoreItem(
            icon: Icons.history,
            title: 'Sales History',
            subtitle: 'View all past shifts',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())),
          ),
          _MoreItem(
            icon: Icons.picture_as_pdf,
            title: 'Reports',
            subtitle: 'Generate PDF reports',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfReportScreen())),
          ),
          const Divider(),
          _MoreItem(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Backup, theme, and more',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreItem({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
