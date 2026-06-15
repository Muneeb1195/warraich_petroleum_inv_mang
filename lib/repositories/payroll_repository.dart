import '../database/app_database.dart';
import '../database/daos/payroll_dao.dart';

class PayrollRepository {
  final PayrollDao _dao;

  PayrollRepository(this._dao);

  Future<int> generatePayroll(int employeeId, int month, int year) async {
    return _dao.generatePayroll(employeeId, month, year);
  }

  Future<PayrollData?> getPayrollById(int id) => _dao.getPayrollById(id);

  Future<void> markAsPaid(int payrollId) async {
    await _dao.markAsPaid(payrollId);
  }

  Stream<List<PayrollRow>> watchPayroll(int month, int year) =>
      _dao.watchPayroll(month, year);
}
