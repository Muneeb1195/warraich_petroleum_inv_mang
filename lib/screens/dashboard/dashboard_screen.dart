import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../providers/shift_provider.dart';
import '../../providers/product_provider.dart';
import '../../utils/constants.dart';
import '../../screens/shifts/shift_detail_screen.dart';
import '../../screens/shifts/new_shift_screen.dart';
import '../../screens/expenses/expenses_screen.dart';
import '../../screens/settings/fuel_prices_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShift = ref.watch(activeShiftProvider);
    final allInventory = ref.watch(allInventoryProvider);
    final todaySummary = ref.watch(todaySummaryProvider);
    final weeklySales = ref.watch(weeklySalesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(weeklySalesProvider);
          ref.invalidate(allInventoryProvider);
          ref.invalidate(monthlySummaryProvider);
          ref.invalidate(recentExpensesProvider);
          ref.invalidate(employeeCountProvider);
        },
        child: _isDesktop
            ? _buildDesktopLayout(context, ref, todaySummary, weeklySales, activeShift, allInventory, colorScheme)
            : _buildMobileLayout(context, ref, todaySummary, weeklySales, activeShift, allInventory, colorScheme),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, AsyncValue<Map<String, double>> todaySummary, AsyncValue<List<MapEntry<DateTime, double>>> weeklySales, AsyncValue<Shift?> activeShift, AsyncValue<List<dynamic>> allInventory, ColorScheme colorScheme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTodaySummary(context, todaySummary, colorScheme),
        const SizedBox(height: 16),
        _buildActiveShiftCard(context, ref, activeShift, colorScheme),
        const SizedBox(height: 16),
        _buildSalesChart(context, weeklySales, colorScheme),
        const SizedBox(height: 16),
        _buildInventoryAlerts(context, ref, allInventory, colorScheme),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, AsyncValue<Map<String, double>> todaySummary, AsyncValue<List<MapEntry<DateTime, double>>> weeklySales, AsyncValue<Shift?> activeShift, AsyncValue<List<dynamic>> allInventory, ColorScheme colorScheme) {
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final employeeCount = ref.watch(employeeCountProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTodaySummary(context, todaySummary, colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMonthlySummary(context, monthlySummary, colorScheme)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildActiveShiftCard(context, ref, activeShift, colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildQuickActions(context, ref, colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildEmployeeCount(context, employeeCount, colorScheme)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSalesChart(context, weeklySales, colorScheme)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInventoryAlerts(context, ref, allInventory, colorScheme)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(BuildContext context, AsyncValue<Map<String, double>> todaySummary, ColorScheme colorScheme) {
    return todaySummary.when(
      data: (summary) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Today's Summary", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Sales', value: formatMoney(summary['sales']!), icon: Icons.trending_up, color: colorScheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(title: 'Expenses', value: formatMoney(summary['expenses']!), icon: Icons.trending_down, color: colorScheme.error)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(title: 'Profit', value: formatMoney(summary['profit']!), icon: Icons.account_balance_wallet, color: summary['profit']! >= 0 ? Colors.green : colorScheme.error)),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
    );
  }

  Widget _buildMonthlySummary(BuildContext context, AsyncValue<Map<String, double>> monthlySummary, ColorScheme colorScheme) {
    return monthlySummary.when(
      data: (summary) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _StatCard(title: 'Sales', value: formatMoney(summary['sales']!), icon: Icons.trending_up, color: colorScheme.primary)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(title: 'Expenses', value: formatMoney(summary['expenses']!), icon: Icons.trending_down, color: colorScheme.error)),
                  const SizedBox(width: 8),
                  Expanded(child: _StatCard(title: 'Profit', value: formatMoney(summary['profit']!), icon: Icons.account_balance_wallet, color: summary['profit']! >= 0 ? Colors.green : colorScheme.error)),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
    );
  }

  Widget _buildActiveShiftCard(BuildContext context, WidgetRef ref, AsyncValue<Shift?> activeShift, ColorScheme colorScheme) {
    final isActive = activeShift.hasValue && activeShift.value != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Shift', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                child: Icon(Icons.schedule, color: isActive ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              ),
              title: Text(isActive ? '${activeShift.value!.type.toUpperCase()} Shift' : 'No Active Shift'),
              subtitle: Text(isActive ? 'Tap to manage sales' : 'Start a shift to begin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: isActive
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftDetailScreen(shiftId: activeShift.value!.id)))
                  : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewShiftScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.add_circle,
              label: 'New Shift',
              color: colorScheme.primary,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewShiftScreen())),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.receipt_long,
              label: 'Add Expense',
              color: colorScheme.error,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(BuildContext context, AsyncValue<List<MapEntry<DateTime, double>>> weeklySales, ColorScheme colorScheme) {
    return weeklySales.when(
      data: (data) {
        if (data.every((e) => e.value == 0)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sales Trends (7 days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  Center(child: Text('No sales data yet', style: TextStyle(color: colorScheme.onSurfaceVariant))),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        final spots = data.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();

        final maxY = spots.fold<double>(0, (max, spot) => spot.y > max ? spot.y : max);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sales Trends (7 days)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: _isDesktop ? 220 : 200,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      minY: 0,
                      maxY: maxY > 0 ? maxY * 1.2 : 100,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(formatMoney(value), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length) return const SizedBox.shrink();
                              return Text(DateFormat('E').format(data[index].key), style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colorScheme.primary,
                          barWidth: 3,
                          belowBarData: BarAreaData(show: true, color: colorScheme.primary.withValues(alpha: 0.1)),
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
    );
  }

  Widget _buildEmployeeCount(BuildContext context, AsyncValue<int> employeeCount, ColorScheme colorScheme) {
    return employeeCount.when(
      data: (count) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '$count',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Active Employees', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))),
      error: (e, _) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error: $e'))),
    );
  }

  Widget _buildInventoryAlerts(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> allInventory, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Petroleum Status', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FuelPricesScreen())),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Prices', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            allInventory.when(
              data: (items) {
                final fuelItems = items.where((item) => item.product.category == 'fuel').toList();
                if (fuelItems.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No inventory data')));
                }
                return Column(
                  children: fuelItems.map((item) {
                    final isLow = item.inventoryEntry.currentStock <= item.inventoryEntry.minStock && item.inventoryEntry.minStock > 0;
                    final maxStock = item.inventoryEntry.minStock > 0 ? item.inventoryEntry.minStock * 3 : item.inventoryEntry.currentStock * 1.5;
                    final progress = (item.inventoryEntry.currentStock / maxStock).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(isLow ? Icons.warning_amber : Icons.check_circle, color: isLow ? colorScheme.error : colorScheme.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                              Text(
                                '${item.inventoryEntry.currentStock.toStringAsFixed(1)} ${item.product.unit}',
                                style: TextStyle(
                                  color: isLow ? colorScheme.error : colorScheme.onSurface,
                                  fontWeight: isLow ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: colorScheme.surfaceContainerHighest,
                              color: isLow ? colorScheme.error : colorScheme.primary,
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
