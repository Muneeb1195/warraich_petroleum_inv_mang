
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import '../../providers/shift_provider.dart';
import '../../utils/constants.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExpenses = ref.watch(allExpensesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: _buildBody(context, ref, allExpenses, colorScheme),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AsyncValue allExpenses, ColorScheme colorScheme) {
    final content = allExpenses.when(
      data: (expenses) {
        if (expenses.isEmpty) {
          return const Center(child: Text('No expenses recorded'));
        }

        final grouped = <String, List<dynamic>>{};
        for (final expense in expenses) {
          final dateKey = '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}-${expense.date.day.toString().padLeft(2, '0')}';
          grouped.putIfAbsent(dateKey, () => []).add(expense);
        }

        final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
        final todayKey = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

        return ListView(
          padding: const EdgeInsets.all(16),
          children: sortedDates.map((dateKey) {
            final dateExpenses = grouped[dateKey]!;
            final total = dateExpenses.fold<double>(0, (sum, e) => sum + e.amount);
            final date = dateExpenses.first.date;
            final isToday = dateKey == todayKey;
            final dateLabel = (date.year == DateTime.now().year && date.month == DateTime.now().month && date.day == DateTime.now().day) ? 'Today' : DateFormat('dd MMM yyyy').format(date);

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                initiallyExpanded: isToday,
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text('${dateExpenses.length}', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ),
                title: Text(dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${dateExpenses.length} expenses • ${formatMoney(total)}'),
                children: dateExpenses.map((expense) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.errorContainer,
                    child: Icon(_getCategoryIcon(expense.category), color: colorScheme.onErrorContainer, size: 20),
                  ),
                  title: Text(expense.category.toUpperCase(), style: const TextStyle(fontSize: 14)),
                  subtitle: Text(expense.description ?? '', style: const TextStyle(fontSize: 12)),
                  trailing: Text(formatMoney(expense.amount), style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error)),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Expense?'),
                        content: const Text('This action cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          FilledButton(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await ref.read(expenseNotifierProvider.notifier).deleteExpense(expense.id);
                              ref.invalidate(todaySummaryProvider);
                              ref.invalidate(weeklyExpensesProvider);
                              ref.invalidate(weeklyProfitProvider);
                              ref.invalidate(monthlySummaryProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense deleted')));
                              }
                            },
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                )).toList(),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );

    if (_isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: content,
        ),
      );
    }
    return content;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electricity': return Icons.electric_bolt;
      case 'maintenance': return Icons.build;
      case 'transport': return Icons.local_shipping;
      case 'utilities': return Icons.water;
      default: return Icons.receipt;
    }
  }
}
