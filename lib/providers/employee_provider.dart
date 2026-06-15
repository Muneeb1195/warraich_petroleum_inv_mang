import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/employee_repository.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(databaseProvider).employeeDao);
});

final allEmployeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchAll();
});

class EmployeeNotifier extends StateNotifier<AsyncValue<void>> {
  final EmployeeRepository _repo;
  final SyncService? _sync;

  EmployeeNotifier(this._repo, this._sync) : super(const AsyncValue.data(null));

  Future<void> addEmployee({
    required String name,
    String? phone,
    required String role,
    String defaultShift = 'both',
    double salary = 0,
  }) async {
    int id = 0;
    state = await AsyncValue.guard(() async {
      id = await _repo.addEmployee(
        name: name,
        phone: phone,
        role: role,
        defaultShift: defaultShift,
        salary: salary,
      );
    });
    if (id > 0) {
      await _sync?.syncRecord('employees', id.toString(), {
        'id': id,
        'name': name,
        'phone': phone,
        'role': role,
        'defaultShift': defaultShift,
        'salary': salary,
        'isActive': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateEmployee(int id, EmployeesCompanion data) async {
    state = await AsyncValue.guard(() => _repo.updateEmployee(id, data));
    if (_sync != null) {
      final employee = await _repo.getEmployeeById(id);
      if (employee != null) {
        await _sync.syncRecord('employees', id.toString(), {
          'id': employee.id,
          'name': employee.name,
          'phone': employee.phone,
          'role': employee.role,
          'defaultShift': employee.defaultShift,
          'salary': employee.salary,
          'isActive': employee.isActive,
          'updatedAt': employee.updatedAt.toIso8601String(),
        });
      }
    }
  }

  Future<void> deactivateEmployee(int id) async {
    state = await AsyncValue.guard(() => _repo.deactivateEmployee(id));
    await _sync?.deleteRecord('employees', id.toString());
  }
}

final employeeNotifierProvider = StateNotifierProvider<EmployeeNotifier, AsyncValue<void>>((ref) {
  return EmployeeNotifier(
    ref.watch(employeeRepositoryProvider),
    ref.read(syncServiceProvider),
  );
});
