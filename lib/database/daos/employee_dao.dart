import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'employee_dao.g.dart';

@DriftAccessor(tables: [Employees])
class EmployeeDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeeDaoMixin {
  EmployeeDao(super.db);

  Future<int> addEmployee(EmployeesCompanion employee) =>
      into(employees).insert(employee);

  Future<Employee?> getEmployeeById(int id) async {
    return (select(employees)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Stream<List<Employee>> watchAllEmployees() {
    return (select(employees)..where((e) => e.isActive.equals(true))).watch();
  }

  Future<void> updateEmployee(int id, EmployeesCompanion data) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(data);
  }

  Future<void> deactivateEmployee(int id) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(
      EmployeesCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
