import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/employee_dao.dart';
import 'database_provider.dart';

final employeeDaoProvider = Provider<EmployeeDao>((ref) {
  return ref.watch(databaseProvider).employeeDao;
});

final allEmployeesProvider = StreamProvider<List<Employee>>((ref) {
  return ref.watch(employeeDaoProvider).watchAllEmployees();
});

class EmployeeNotifier extends StateNotifier<AsyncValue<void>> {
  final EmployeeDao _dao;

  EmployeeNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<void> addEmployee({
    required String name,
    String? phone,
    required String role,
    String defaultShift = 'both',
    double salary = 0,
  }) async {
    state = await AsyncValue.guard(() async {
      await _dao.addEmployee(EmployeesCompanion.insert(
        name: name,
        phone: Value(phone),
        role: role,
        defaultShift: Value(defaultShift),
        salary: Value(salary),
      ));
    });
  }

  Future<void> updateEmployee(int id, EmployeesCompanion data) async {
    state = await AsyncValue.guard(() async {
      await _dao.updateEmployee(id, data);
    });
  }

  Future<void> deactivateEmployee(int id) async {
    state = await AsyncValue.guard(() async {
      await _dao.deactivateEmployee(id);
    });
  }
}

final employeeNotifierProvider = StateNotifierProvider<EmployeeNotifier, AsyncValue<void>>((ref) {
  return EmployeeNotifier(ref.watch(employeeDaoProvider));
});
