import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'payroll_dao.g.dart';

@DriftAccessor(tables: [Payroll, Employees])
class PayrollDao extends DatabaseAccessor<AppDatabase> with _$PayrollDaoMixin {
  PayrollDao(super.db);

  Future<PayrollData?> getPayrollById(int id) async {
    return (select(payroll)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> generatePayrollRaw(PayrollCompanion data) =>
      into(payroll).insert(data);

  Future<int> generatePayroll(int employeeId, int month, int year) async {
    final employee = await (select(
      employees,
    )..where((e) => e.id.equals(employeeId))).getSingleOrNull();
    if (employee == null) throw Exception('Employee not found');

    // Check if payroll already exists for this month and year
    final existing =
        await (select(payroll)..where(
              (p) =>
                  p.employeeId.equals(employeeId) &
                  p.month.equals(month) &
                  p.year.equals(year),
            ))
            .getSingleOrNull();

    if (existing != null) {
      if (existing.isPaid) {
        // If already paid, do not overwrite or duplicate
        return existing.id;
      }
      // If not paid, delete the existing one and regenerate
      await (delete(payroll)..where((p) => p.id.equals(existing.id))).go();
    }

    return into(payroll).insert(
      PayrollCompanion.insert(
        employeeId: employeeId,
        month: month,
        year: year,
        baseSalary: employee.salary,
        deductions: const Value(0.0),
        netPay: employee.salary,
      ),
    );
  }

  Future<List<PayrollData>> getPayroll(int month, int year) async {
    return (select(
      payroll,
    )..where((p) => p.month.equals(month) & p.year.equals(year))).get();
  }

  Stream<List<PayrollRow>> watchPayroll(int month, int year) {
    final query = select(payroll).join([
      innerJoin(employees, employees.id.equalsExp(payroll.employeeId)),
    ])..where(payroll.month.equals(month) & payroll.year.equals(year));
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
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class PayrollRow {
  final PayrollData payrollEntry;
  final Employee employee;
  PayrollRow({required this.payrollEntry, required this.employee});
}
