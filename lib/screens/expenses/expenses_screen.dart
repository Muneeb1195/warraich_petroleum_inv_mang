import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/expense_provider.dart';
import '../../providers/shift_provider.dart';
import '../../utils/extensions.dart';
import 'add_expense_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allExpenses = ref.watch(allExpensesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: allExpenses.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses recorded'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.errorContainer,
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                  title: Text(expense.category.toUpperCase()),
                  subtitle: Text(
                    '${expense.date.formattedDate}${expense.description != null ? ' - ${expense.description}' : ''}',
                  ),
                  trailing: Text(
                    'Rs. ${expense.amount.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.error),
                  ),
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
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electricity':
        return Icons.electric_bolt;
      case 'wages':
        return Icons.people;
      case 'maintenance':
        return Icons.build;
      case 'transport':
        return Icons.local_shipping;
      case 'utilities':
        return Icons.water;
      case 'supplier':
        return Icons.inventory;
      default:
        return Icons.receipt;
    }
  }
}
