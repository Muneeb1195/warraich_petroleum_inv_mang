import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'employee_dao.g.dart';

@DriftAccessor(tables: [Employees, Attendance])
class EmployeeDao extends DatabaseAccessor<AppDatabase> with _$EmployeeDaoMixin {
  EmployeeDao(super.db);

  Future<int> addEmployee(EmployeesCompanion employee) => into(employees).insert(employee);

  Future<List<Employee>> getAllEmployees() async {
    return (select(employees)..where((e) => e.isActive.equals(true))).get();
  }

  Stream<List<Employee>> watchAllEmployees() {
    return (select(employees)..where((e) => e.isActive.equals(true))).watch();
  }

  Future<void> updateEmployee(int id, EmployeesCompanion data) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(data);
  }

  Future<void> deactivateEmployee(int id) async {
    await (update(employees)..where((e) => e.id.equals(id))).write(
      EmployeesCompanion(isActive: const Value(false)),
    );
  }

  Future<void> recordAttendance(AttendanceCompanion attendance) =>
      into(this.attendance).insert(attendance);

  Future<List<AttendanceData>> getAttendance(int employeeId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day + 1);
    return (select(attendance)
          ..where((a) =>
              a.employeeId.equals(employeeId) &
              a.date.isBetweenValues(startOfDay, endOfDay)))
        .get();
  }

  Future<List<AttendanceData>> getMonthlyAttendance(int employeeId, int month, int year) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    return (select(attendance)
          ..where((a) =>
              a.employeeId.equals(employeeId) &
              a.date.isBetweenValues(start, end)))
        .get();
  }

  Stream<List<Employee>> watchEmployeesByShift(String shift) {
    return (select(employees)
          ..where((e) =>
              (e.defaultShift.equals(shift) | e.defaultShift.equals('both')) &
              e.isActive.equals(true)))
        .watch();
  }
}
