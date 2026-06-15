import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';

class EmployeeRepository {
  final EmployeeDao _dao;

  EmployeeRepository(this._dao);

  Future<int> addEmployee({
    required String name,
    String? phone,
    required String role,
    String defaultShift = 'both',
    double salary = 0,
  }) async {
    return _dao.addEmployee(EmployeesCompanion.insert(
      name: name,
      phone: Value(phone),
      role: role,
      defaultShift: Value(defaultShift),
      salary: Value(salary),
    ));
  }

  Future<void> updateEmployee(int id, EmployeesCompanion data) async {
    await _dao.updateEmployee(id, data);
  }

  Future<Employee?> getEmployeeById(int id) => _dao.getEmployeeById(id);

  Future<void> deactivateEmployee(int id) async {
    await _dao.deactivateEmployee(id);
  }

  Stream<List<Employee>> watchAll() => _dao.watchAllEmployees();
}
