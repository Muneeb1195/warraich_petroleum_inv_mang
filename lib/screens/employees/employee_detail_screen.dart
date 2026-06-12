import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/employee_provider.dart';
import '../../providers/payroll_provider.dart';
import '../../database/daos/payroll_dao.dart';

class EmployeeDetailScreen extends ConsumerWidget {
  final int employeeId;
  const EmployeeDetailScreen({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEmployees = ref.watch(allEmployeesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Employee Details')),
      body: allEmployees.when(
        data: (employees) {
          final employee = employees.firstWhere(
            (e) => e.id == employeeId,
            orElse: () => throw Exception('Employee not found'),
          );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          employee.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        employee.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee.role,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Info', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _InfoRow(label: 'Phone', value: employee.phone ?? 'N/A'),
                      _InfoRow(label: 'Shift', value: employee.defaultShift),
                      _InfoRow(label: 'Salary', value: 'Rs. ${employee.salary.toStringAsFixed(0)}/month'),
                      _InfoRow(label: 'Joining Date', value: employee.joiningDate.toString().substring(0, 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildPayrollHistory(context, ref, employeeId, colorScheme),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPayrollHistory(BuildContext context, WidgetRef ref, int employeeId, ColorScheme colorScheme) {
    final payrollDao = ref.watch(payrollDaoProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payroll History', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            FutureBuilder<List>(
              future: _loadPayroll(payrollDao, employeeId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data ?? [];
                if (records.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No payroll records yet'),
                    ),
                  );
                }
                return Column(
                  children: records.map((record) {
                    final isPaid = record.isPaid as bool;
                    final month = record.month as int;
                    final year = record.year as int;
                    final netPay = record.netPay as double;
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: isPaid ? colorScheme.primaryContainer : colorScheme.errorContainer,
                        child: Icon(
                          isPaid ? Icons.check_circle : Icons.pending,
                          size: 18,
                          color: isPaid ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                        ),
                      ),
                      title: Text('$month/$year'),
                      subtitle: Text('Net: Rs. ${netPay.toStringAsFixed(0)}'),
                      trailing: isPaid
                          ? const Text('Paid', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))
                          : const Text('Pending', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<List> _loadPayroll(PayrollDao dao, int employeeId) async {
    final results = <dynamic>[];
    final now = DateTime.now();
    for (int i = 0; i < 6; i++) {
      var month = now.month - i;
      var year = now.year;
      if (month <= 0) {
        month += 12;
        year -= 1;
      }
      final payroll = await dao.getPayroll(month, year);
      results.addAll(payroll.where((p) => p.employeeId == employeeId));
    }
    return results;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
