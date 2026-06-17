import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../providers/shift_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/format_provider.dart';
import '../../utils/constants.dart';
import '../../utils/responsive.dart';
import '../../screens/shifts/shift_detail_screen.dart';
import '../../screens/shifts/new_shift_screen.dart';
import '../../screens/expenses/add_expense_screen.dart';
import '../../screens/settings/fuel_prices_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShift = ref.watch(activeShiftProvider);
    final allInventory = ref.watch(allInventoryProvider);
    final todaySummary = ref.watch(todaySummaryProvider);
    final weeklySales = ref.watch(weeklySalesProvider);
    final weeklyExpenses = ref.watch(weeklyExpensesProvider);
    final weeklyProfit = ref.watch(weeklyProfitProvider);
    final lowStock = ref.watch(lowStockProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final abbreviate = ref.watch(abbreviateAmountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(todaySummaryProvider);
          ref.invalidate(weeklySalesProvider);
          ref.invalidate(weeklyExpensesProvider);
          ref.invalidate(weeklyProfitProvider);
          ref.invalidate(allInventoryProvider);
          ref.invalidate(monthlySummaryProvider);
          ref.invalidate(recentExpensesProvider);
          ref.invalidate(employeeCountProvider);
        },
        child: isWide(context)
            ? _buildDesktopLayout(
                context,
                ref,
                todaySummary,
                weeklySales,
                weeklyExpenses,
                weeklyProfit,
                activeShift,
                allInventory,
                lowStock,
                colorScheme,
                abbreviate: abbreviate,
              )
            : _buildMobileLayout(
                context,
                ref,
                todaySummary,
                weeklySales,
                activeShift,
                allInventory,
                lowStock,
                colorScheme,
                abbreviate: abbreviate,
              ),
      ),
    );
  }

  Widget _buildLowStockBanner(
    BuildContext context,
    AsyncValue<List<InventoryRow>> lowStock,
    ColorScheme colorScheme,
  ) {
    final lowStockItems = lowStock.asData?.value;
    if (lowStockItems == null || lowStockItems.isEmpty)
      return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Low stock: ${lowStockItems.map((e) => '${e.product.name} (${e.inventoryEntry.currentStock.toStringAsFixed(1)} ${e.product.unit})').join(', ')}',
                  style: TextStyle(color: colorScheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, double>> todaySummary,
    AsyncValue<List<MapEntry<DateTime, double>>> weeklySales,
    AsyncValue<Shift?> activeShift,
    AsyncValue<List<dynamic>> allInventory,
    AsyncValue<List<InventoryRow>> lowStock,
    ColorScheme colorScheme, {
    bool abbreviate = true,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildLowStockBanner(context, lowStock, colorScheme),
        _buildTodaySummary(
          context,
          todaySummary,
          colorScheme,
          abbreviate: abbreviate,
        ),
        const SizedBox(height: 16),
        _buildActiveShiftCard(context, ref, activeShift, colorScheme),
        const SizedBox(height: 16),
        _buildSalesChart(
          context,
          ref,
          weeklySales,
          colorScheme,
          abbreviate: abbreviate,
        ),
        const SizedBox(height: 16),
        _buildInventoryAlerts(context, ref, allInventory, colorScheme),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, double>> todaySummary,
    AsyncValue<List<MapEntry<DateTime, double>>> weeklySales,
    AsyncValue<List<MapEntry<DateTime, double>>> weeklyExpenses,
    AsyncValue<List<MapEntry<DateTime, double>>> weeklyProfit,
    AsyncValue<Shift?> activeShift,
    AsyncValue<List<dynamic>> allInventory,
    AsyncValue<List<InventoryRow>> lowStock,
    ColorScheme colorScheme, {
    bool abbreviate = true,
  }) {
    final monthlySummary = ref.watch(monthlySummaryProvider);
    final employeeCount = ref.watch(employeeCountProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLowStockBanner(context, lowStock, colorScheme),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTodaySummary(
                      context,
                      todaySummary,
                      colorScheme,
                      abbreviate: abbreviate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMonthlySummary(
                      context,
                      monthlySummary,
                      colorScheme,
                      abbreviate: abbreviate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildActiveShiftCard(
                      context,
                      ref,
                      activeShift,
                      colorScheme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActions(context, ref, colorScheme),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEmployeeCount(
                      context,
                      employeeCount,
                      colorScheme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTrendChart(
                      context,
                      'Sales Trends (7 days)',
                      weeklySales,
                      colorScheme.primary,
                      colorScheme,
                      abbreviate: abbreviate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTrendChart(
                      context,
                      'Expense Trends (7 days)',
                      weeklyExpenses,
                      colorScheme.error,
                      colorScheme,
                      abbreviate: abbreviate,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTrendChart(
                      context,
                      'Profit Trends (7 days)',
                      weeklyProfit,
                      colorScheme.tertiary,
                      colorScheme,
                      abbreviate: abbreviate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInventoryAlerts(
                      context,
                      ref,
                      allInventory,
                      colorScheme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySummary(
    BuildContext context,
    AsyncValue<Map<String, double>> todaySummary,
    ColorScheme colorScheme, {
    bool abbreviate = true,
  }) {
    return todaySummary.when(
      data: (summary) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Today's Summary",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Sales',
                      value: formatMoney(
                        summary['sales'] ?? 0,
                        abbreviate: abbreviate,
                      ),
                      icon: Icons.trending_up,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Expenses',
                      value: formatMoney(
                        summary['expenses'] ?? 0,
                        abbreviate: abbreviate,
                      ),
                      icon: Icons.trending_down,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Profit',
                      value: formatMoney(
                        summary['profit'] ?? 0,
                        abbreviate: abbreviate,
                      ),
                      icon: Icons.account_balance_wallet,
                      color: (summary['profit'] ?? 0) >= 0
                          ? colorScheme.tertiary
                          : colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildMonthlySummary(
    BuildContext context,
    AsyncValue<Map<String, double>> monthlySummary,
    ColorScheme colorScheme, {
    bool abbreviate = true,
  }) {
    return monthlySummary.when(
      data: (summary) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Sales',
                      value: formatMoney(
                        summary['sales'] ?? 0,
                        abbreviate: abbreviate,
                      ),
                      icon: Icons.trending_up,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Expenses',
                      value: formatMoney(
                        summary['expenses'] ?? 0,
                        abbreviate: abbreviate,
                      ),
                      icon: Icons.trending_down,
                      color: colorScheme.error,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatCard(
                      title: 'Profit',
                      value: formatMoney(
                        summary['profit'] ?? 0,
                        abbreviate: abbreviate,
                      ),
                      icon: Icons.account_balance_wallet,
                      color: (summary['profit'] ?? 0) >= 0
                          ? colorScheme.tertiary
                          : colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildActiveShiftCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Shift?> activeShift,
    ColorScheme colorScheme,
  ) {
    final isActive = activeShift.hasValue && activeShift.value != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Shift',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.schedule,
                  color: isActive
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(
                isActive
                    ? '${activeShift.value!.type.toUpperCase()} Shift'
                    : 'No Active Shift',
              ),
              subtitle: Text(
                isActive ? 'Tap to manage sales' : 'Start a shift to begin',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: isActive
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ShiftDetailScreen(shiftId: activeShift.value!.id),
                      ),
                    )
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const NewShiftScreen()),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              icon: Icons.add_circle,
              label: 'New Shift',
              color: colorScheme.primary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewShiftScreen()),
              ),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              icon: Icons.receipt_long,
              label: 'Add Expense',
              color: colorScheme.error,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<MapEntry<DateTime, double>>> weeklySales,
    ColorScheme colorScheme, {
    bool abbreviate = true,
  }) {
    return weeklySales.when(
      data: (data) {
        if (data.every((e) => e.value == 0)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Trends (7 days)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'No sales data yet',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        final spots = data.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();

        final maxY = spots.fold<double>(
          0,
          (max, spot) => spot.y > max ? spot.y : max,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sales Trends (7 days)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: isWide(context) ? 220 : 200,
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
                              return Text(
                                formatMoney(value, abbreviate: abbreviate),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length)
                                return const SizedBox.shrink();
                              return Text(
                                DateFormat('E').format(data[index].key),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colorScheme.primary,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
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
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildTrendChart(
    BuildContext context,
    String title,
    AsyncValue<List<MapEntry<DateTime, double>>> weeklyData,
    Color chartColor,
    ColorScheme colorScheme, {
    bool abbreviate = true,
  }) {
    return weeklyData.when(
      data: (data) {
        if (data.every((e) => e.value == 0)) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'No data yet',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        final spots = data.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.value);
        }).toList();

        final maxY = spots.fold<double>(
          0,
          (max, spot) => spot.y > max ? spot.y : max,
        );
        final minY = spots.fold<double>(
          0,
          (min, spot) => spot.y < min ? spot.y : min,
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      minY: minY < 0 ? minY * 1.2 : 0,
                      maxY: maxY > 0 ? maxY * 1.2 : 100,
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              if (value == 0) return const SizedBox.shrink();
                              return Text(
                                formatMoney(value, abbreviate: abbreviate),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= data.length)
                                return const SizedBox.shrink();
                              return Text(
                                DateFormat('E').format(data[index].key),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: chartColor,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: chartColor.withValues(alpha: 0.1),
                          ),
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
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildEmployeeCount(
    BuildContext context,
    AsyncValue<int> employeeCount,
    ColorScheme colorScheme,
  ) {
    return employeeCount.when(
      data: (count) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Active Employees',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e'),
        ),
      ),
    );
  }

  Widget _buildInventoryAlerts(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<dynamic>> allInventory,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Petroleum Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FuelPricesScreen()),
                  ),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Prices', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            allInventory.when(
              data: (items) {
                final fuelItems = items
                    .where((item) => item.product.category == 'fuel')
                    .toList();
                if (fuelItems.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No inventory data'),
                    ),
                  );
                }
                return Column(
                  children: fuelItems.map((item) {
                    final isLow =
                        item.inventoryEntry.currentStock <=
                            item.inventoryEntry.minStock &&
                        item.inventoryEntry.minStock > 0;
                    final maxStock = item.inventoryEntry.minStock > 0
                        ? item.inventoryEntry.minStock * 3
                        : item.inventoryEntry.currentStock * 1.5;
                    final progress = maxStock > 0
                        ? (item.inventoryEntry.currentStock / maxStock).clamp(
                            0.0,
                            1.0,
                          )
                        : 0.0;
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
                                  Icon(
                                    isLow
                                        ? Icons.warning_amber
                                        : Icons.check_circle,
                                    color: isLow
                                        ? colorScheme.error
                                        : colorScheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item.product.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${item.inventoryEntry.currentStock.toStringAsFixed(1)} ${item.product.unit}',
                                style: TextStyle(
                                  color: isLow
                                      ? colorScheme.error
                                      : colorScheme.onSurface,
                                  fontWeight: isLow
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              color: isLow
                                  ? colorScheme.error
                                  : colorScheme.primary,
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

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

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
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
