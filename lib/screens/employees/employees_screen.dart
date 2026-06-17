import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/employee_provider.dart';
import '../../providers/format_provider.dart';
import '../../utils/constants.dart';
import '../../utils/error_utils.dart';
import '../../utils/responsive.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEmployees = ref.watch(allEmployeesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final body = allEmployees.when(
      data: (employees) {
        if (employees.isEmpty)
          return const Center(child: Text('No employees added yet'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: employees.length,
          itemBuilder: (context, index) {
            final employee = employees[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    employee.name.isEmpty
                        ? '?'
                        : employee.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(employee.name),
                subtitle: Text(
                  '${employee.role} - ${employee.defaultShift} shift',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fm(ref, employee.salary),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditDialog(context, ref, employee);
                        } else if (value == 'delete') {
                          _confirmDelete(context, ref, employee);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete,
                              color: colorScheme.error,
                            ),
                            title: Text(
                              'Deactivate',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(allEmployeesProvider);
        },
        child: isWide(context)
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                  child: body,
                ),
              )
            : body,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEmployeeScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee'),
      ),
    );
  }
}

void _showEditDialog(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) {
  final nameController = TextEditingController(text: employee.name);
  final phoneController = TextEditingController(text: employee.phone ?? '');
  final salaryController =
      TextEditingController(text: employee.salary.toStringAsFixed(0));
  String selectedRole = employee.role;
  String selectedShift = employee.defaultShift;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Edit Employee'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'Operator', child: Text('Operator')),
                  DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'Cleaner', child: Text('Cleaner')),
                  DropdownMenuItem(
                    value: 'Supervisor',
                    child: Text('Supervisor'),
                  ),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedRole = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedShift,
                decoration: const InputDecoration(labelText: 'Default Shift'),
                items: const [
                  DropdownMenuItem(value: 'morning', child: Text('Morning')),
                  DropdownMenuItem(value: 'evening', child: Text('Evening')),
                  DropdownMenuItem(value: 'both', child: Text('Both')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedShift = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary ($kCurrency)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final salary = double.tryParse(salaryController.text) ?? 0;
              if (nameController.text.isEmpty || salary <= 0) return;
              await ref.read(employeeNotifierProvider.notifier).updateEmployee(
                    employee.id,
                    EmployeesCompanion(
                      name: Value(nameController.text),
                      phone: Value(
                        phoneController.text.isNotEmpty
                            ? phoneController.text
                            : null,
                      ),
                      role: Value(selectedRole),
                      defaultShift: Value(selectedShift),
                      salary: Value(salary),
                      updatedAt: Value(DateTime.now()),
                    ),
                  );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Employee employee,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Deactivate Employee'),
      content: Text(
        'Are you sure you want to deactivate ${employee.name}? '
        'They will no longer appear in the employee list.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await ref
                .read(employeeNotifierProvider.notifier)
                .deactivateEmployee(employee.id);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('Deactivate'),
        ),
      ],
    ),
  );
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

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeNotifierProvider);

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone (optional)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(value: 'Operator', child: Text('Operator')),
                DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                DropdownMenuItem(value: 'Cleaner', child: Text('Cleaner')),
                DropdownMenuItem(
                  value: 'Supervisor',
                  child: Text('Supervisor'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _selectedRole = v);
              },
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
              onChanged: (v) {
                if (v != null) setState(() => _selectedShift = v);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _salaryController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Salary ($kCurrency)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: employeeState.isLoading
                  ? null
                  : () async {
                      if (_nameController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter employee name')),
                        );
                        return;
                      }
                      final salary =
                          double.tryParse(_salaryController.text) ?? 0;
                      if (salary <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Enter a valid salary')),
                        );
                        return;
                      }
                      try {
                        await ref
                            .read(employeeNotifierProvider.notifier)
                            .addEmployee(
                              name: _nameController.text,
                              phone: _phoneController.text.isNotEmpty
                                  ? _phoneController.text
                                  : null,
                              role: _selectedRole,
                              defaultShift: _selectedShift,
                              salary: salary,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          context.showSuccess('Employee added');
                        }
                      } catch (e) {
                        if (context.mounted)
                          context.showError(e, source: 'addEmployee');
                      }
                    },
              child: employeeState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Employee'),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
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
