import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/payroll_provider.dart';
import '../../providers/employee_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/shift_provider.dart';
import '../../utils/extensions.dart';

class PayrollScreen extends ConsumerWidget {
  const PayrollScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payrollData = ref.watch(currentMonthPayrollProvider);
    final allEmployees = ref.watch(allEmployeesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Payroll')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _generatePayroll(context, ref, allEmployees),
        icon: const Icon(Icons.calculate),
        label: const Text('Generate Payroll'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTime.now().formattedMonth,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate payroll for this month',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Payroll Records',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          payrollData.when(
            data: (records) {
              if (records.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No payroll records for this month. Tap Generate Payroll to start.'),
                  ),
                );
              }
              return Column(
                children: records.map((row) {
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: row.payrollEntry.isPaid ? colorScheme.primaryContainer : colorScheme.errorContainer,
                        child: Icon(
                          row.payrollEntry.isPaid ? Icons.check_circle : Icons.pending,
                          color: row.payrollEntry.isPaid ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                        ),
                      ),
                      title: Text(row.employee.name),
                      subtitle: Text(
                        'Base: Rs. ${row.payrollEntry.baseSalary.toStringAsFixed(0)} | Deductions: Rs. ${row.payrollEntry.deductions.toStringAsFixed(0)}',
                      ),
                      trailing: row.payrollEntry.isPaid
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                Text(
                                  'Rs. ${row.payrollEntry.netPay.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await ref.read(payrollNotifierProvider.notifier).markAsPaid(row.payrollEntry.id);
                                    await ref.read(expenseNotifierProvider.notifier).addExpense(
                                      category: 'Misc',
                                      amount: row.payrollEntry.netPay,
                                      description: 'Wages - ${row.employee.name} (${row.payrollEntry.month}/${row.payrollEntry.year})',
                                      date: DateTime.now(),
                                    );
                                    ref.invalidate(todaySummaryProvider);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('${row.employee.name} marked as paid')),
                                      );
                                    }
                                  },
                                  child: const Text('Mark Paid'),
                                ),
                                Text(
                                  'Rs. ${row.payrollEntry.netPay.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary),
                                ),
                              ],
                            ),
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
    );
  }

  void _generatePayroll(BuildContext context, WidgetRef ref, AsyncValue<List<dynamic>> employees) {
    employees.whenData((empList) {
      if (empList.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add employees first')),
        );
        return;
      }

      final now = DateTime.now();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Generate Payroll'),
          content: Text('Generate payroll for ${empList.length} employees for ${now.month}/${now.year}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                for (final emp in empList) {
                  await ref.read(payrollNotifierProvider.notifier).generatePayroll(emp.id, now.month, now.year);
                }
                ref.invalidate(currentMonthPayrollProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payroll generated')),
                  );
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      );
    });
  }
}
