import 'package:flutter/material.dart';
import '../../utils/responsive.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HelpSection(
          icon: Icons.dashboard,
          title: 'Dashboard',
          color: colorScheme.primary,
          items: [
            'View today\'s summary: sales, expenses, and profit',
            'Track monthly performance at a glance',
            'Monitor active shifts and inventory levels',
            'See sales, expense, and profit trends over the last 7 days',
          ],
        ),
        _HelpSection(
          icon: Icons.schedule,
          title: 'Shifts',
          color: colorScheme.tertiary,
          items: [
            'Start a new shift (Morning or Evening)',
            'Add fuel sales entries with meter readings',
            'Select payment method: Cash, Card, Raast, or Credit',
            'Track total sales for each shift',
            'Close the shift to finalize and deduct inventory',
          ],
        ),
        _HelpSection(
          icon: Icons.inventory_2,
          title: 'Inventory',
          color: colorScheme.primary,
          items: [
            'View current stock levels for all products',
            'Visual indicators show stock health (green/orange/red)',
            'Tap any product to set min/max stock levels',
            'Long-press to view transaction history',
            'Use "Add Stock" to record new purchases',
          ],
        ),
        _HelpSection(
          icon: Icons.receipt_long,
          title: 'Expenses',
          color: colorScheme.error,
          items: [
            'Record daily expenses by category',
            'Categories: Electricity, Maintenance, Transport, Utilities, Misc',
            'Expenses are tracked per shift and per day',
            'Older expenses collapse automatically',
          ],
        ),
        _HelpSection(
          icon: Icons.people,
          title: 'Employees',
          color: colorScheme.secondary,
          items: [
            'Add and manage staff members',
            'Set roles: Operator, Manager, Supervisor',
            'Assign shifts: Morning, Evening, or Both',
            'Set monthly salary for each employee',
          ],
        ),
        _HelpSection(
          icon: Icons.payments,
          title: 'Payroll',
          color: colorScheme.primary,
          items: [
            'Generate monthly payroll for all employees',
            'Adjust deductions, advances, and bonuses',
            'Net pay is calculated automatically',
            'Mark payroll as paid when disbursed',
          ],
        ),
        _HelpSection(
          icon: Icons.history,
          title: 'Sales History',
          color: colorScheme.tertiary,
          items: [
            'View all past shifts with sales details',
            'Filter by shift type (Morning/Evening)',
            'See per-shift totals: sales, expenses, profit',
          ],
        ),
        _HelpSection(
          icon: Icons.picture_as_pdf,
          title: 'Reports',
          color: colorScheme.error,
          items: [
            'Generate PDF reports for individual shifts',
            'Generate monthly sales and expense reports',
            'Select date range for report generation',
          ],
        ),
        _HelpSection(
          icon: Icons.cloud,
          title: 'Backup & Restore',
          color: colorScheme.primary,
          items: [
            'Local Backup: saves database to device storage',
            'Local Restore: restore from a local backup file',
            'Cloud Backup: backup to Google Drive (sign in required)',
            'Cloud Restore: choose from multiple backup versions',
            'Up to 5 backups are kept automatically',
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 36,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Pull down on Dashboard to refresh data\n'
                  '• Long-press inventory items to see transaction history\n'
                  '• Close shifts regularly to keep inventory accurate\n'
                  '• Back up your data before major changes',
                  style: TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Guide')),
      body: isWide(context)
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                child: body,
              ),
            )
          : body,
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> items;

  const _HelpSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color)),
                    Expanded(
                      child: Text(item, style: const TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
