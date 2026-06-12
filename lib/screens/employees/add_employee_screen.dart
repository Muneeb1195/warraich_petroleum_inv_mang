import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/employee_provider.dart';
import '../../utils/constants.dart';

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
  Widget build(BuildContext context) {
    final employeeState = ref.watch(employeeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Add Employee')),
      body: Padding(
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
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: kEmployeeRoles.map((role) {
                  return DropdownMenuItem(value: role, child: Text(role));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedRole = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedShift,
                decoration: const InputDecoration(labelText: 'Default Shift'),
                items: kDefaultShifts.map((shift) {
                  return DropdownMenuItem(
                    value: shift,
                    child: Text(shift[0].toUpperCase() + shift.substring(1)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedShift = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _salaryController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monthly Salary (Rs.)',
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
                        await ref.read(employeeNotifierProvider.notifier).addEmployee(
                              name: _nameController.text,
                              phone: _phoneController.text.isNotEmpty
                                  ? _phoneController.text
                                  : null,
                              role: _selectedRole,
                              defaultShift: _selectedShift,
                              salary: double.tryParse(_salaryController.text) ?? 0,
                            );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Employee added')),
                          );
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
      ),
    );
  }
}
