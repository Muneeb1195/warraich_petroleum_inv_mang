import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/employee_provider.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});
  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEmployees = ref.watch(allEmployeesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final body = allEmployees.when(
      data: (employees) {
        if (employees.isEmpty) return const Center(child: Text('No employees added yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: colorScheme.primaryContainer, child: Text(employee.name.substring(0, 1).toUpperCase(), style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold))),
                title: Text(employee.name),
                subtitle: Text('${employee.role} - ${employee.defaultShift} shift'),
                trailing: Text('Rs. ${employee.salary.toStringAsFixed(0)}', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Employees')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEmployeeScreen())),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
      body: _isDesktop ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body)) : body,
    );
  }
}

class AddEmployeeScreen extends ConsumerStatefulWidget {
  const AddEmployeeScreen({super.key});
  @override
  ConsumerState<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends ConsumerState<AddEmployeeScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _salaryController = TextEditingController();
  String _selectedRole = 'Operator';
  String _selectedShift = 'both';
  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeNotifierProvider);

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 16),
            TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone (optional)', prefixIcon: Icon(Icons.phone))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'Operator', child: Text('Operator')),
                DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                DropdownMenuItem(value: 'Cleaner', child: Text('Cleaner')),
                DropdownMenuItem(value: 'Supervisor', child: Text('Supervisor')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) { if (v != null) setState(() => _selectedRole = v); },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedShift,
              decoration: const InputDecoration(labelText: 'Default Shift'),
              items: const [
                DropdownMenuItem(value: 'morning', child: Text('Morning')),
                DropdownMenuItem(value: 'evening', child: Text('Evening')),
                DropdownMenuItem(value: 'both', child: Text('Both')),
              ],
              onChanged: (v) { if (v != null) setState(() => _selectedShift = v); },
            ),
            const SizedBox(height: 16),
            TextField(controller: _salaryController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Salary (Rs.)', prefixIcon: Icon(Icons.attach_money))),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: employeeState.isLoading ? null : () async {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter employee name')));
                  return;
                }
                await ref.read(employeeNotifierProvider.notifier).addEmployee(
                  name: _nameController.text,
                  phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
                  role: _selectedRole,
                  defaultShift: _selectedShift,
                  salary: double.tryParse(_salaryController.text) ?? 0,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee added')));
                }
              },
              child: employeeState.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Employee'),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: _isDesktop ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body)) : body,
    );
  }
}
