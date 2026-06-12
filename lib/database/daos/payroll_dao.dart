import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'payroll_dao.g.dart';

@DriftAccessor(tables: [Payroll, Employees, Attendance])
class PayrollDao extends DatabaseAccessor<AppDatabase> with _$PayrollDaoMixin {
  PayrollDao(super.db);

  Future<int> generatePayroll(int employeeId, int month, int year) async {
    final employee = await (select(employees)..where((e) => e.id.equals(employeeId))).getSingleOrNull();
    if (employee == null) throw Exception('Employee not found');

    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final attendanceList = await (select(attendance)
          ..where((a) =>
              a.employeeId.equals(employeeId) &
              a.date.isBetweenValues(start, end)))
        .get();

    final daysLate = attendanceList.where((a) => a.status == 'late').length;
    final workingDaysInMonth = 30;
    final dailyRate = employee.salary / workingDaysInMonth;
    final deductions = daysLate * (dailyRate * 0.1);

    final netPay = employee.salary - deductions;

    return into(payroll).insert(PayrollCompanion.insert(
      employeeId: employeeId,
      month: month,
      year: year,
      baseSalary: employee.salary,
      deductions: Value(deductions),
      netPay: netPay,
    ));
  }

  Future<List<PayrollData>> getPayroll(int month, int year) async {
    return (select(payroll)
          ..where((p) => p.month.equals(month) & p.year.equals(year)))
        .get();
  }

  Stream<List<PayrollRow>> watchPayroll(int month, int year) {
    final query = select(payroll).join([
      innerJoin(employees, employees.id.equalsExp(payroll.employeeId)),
    ])
      ..where(payroll.month.equals(month) & payroll.year.equals(year));
    return query.watch().map((rows) {
      return rows.map((row) {
        return PayrollRow(
          payrollEntry: row.readTable(payroll),
          employee: row.readTable(employees),
        );
      }).toList();
    });
  }

  Future<void> markAsPaid(int payrollId) async {
    await (update(payroll)..where((p) => p.id.equals(payrollId))).write(
      PayrollCompanion(
        isPaid: const Value(true),
        paidDate: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updatePayroll(int id, PayrollCompanion data) async {
    await (update(payroll)..where((p) => p.id.equals(id))).write(data);
  }
}

class PayrollRow {
  final PayrollData payrollEntry;
  final Employee employee;
  PayrollRow({required this.payrollEntry, required this.employee});
}
