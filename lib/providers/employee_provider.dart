import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/employee_repository.dart';
import 'database_provider.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(databaseProvider).employeeDao);
});

final allEmployeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchAll();
});

class EmployeeNotifier extends StateNotifier<AsyncValue<void>> {
  final EmployeeRepository _repo;

  EmployeeNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addEmployee({
    required String name,
    String? phone,
    required String role,
    String defaultShift = 'both',
    double salary = 0,
  }) async {
    state = const AsyncValue.data(null);
    state = await AsyncValue.guard(() async {
      await _repo.addEmployee(
        name: name,
        phone: phone,
        role: role,
        defaultShift: defaultShift,
        salary: salary,
      );
    });
  }

  Future<void> updateEmployee(int id, EmployeesCompanion data) async {
    state = const AsyncValue.data(null);
    state = await AsyncValue.guard(() => _repo.updateEmployee(id, data));
  }

  Future<void> deactivateEmployee(int id) async {
    state = const AsyncValue.data(null);
    state = await AsyncValue.guard(() => _repo.deactivateEmployee(id));
  }
}

final employeeNotifierProvider =
    StateNotifierProvider<EmployeeNotifier, AsyncValue<void>>((ref) {
      return EmployeeNotifier(ref.watch(employeeRepositoryProvider));
    });
