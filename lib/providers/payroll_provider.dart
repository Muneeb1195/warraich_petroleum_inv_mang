import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/daos/payroll_dao.dart';
import 'database_provider.dart';

final payrollDaoProvider = Provider<PayrollDao>((ref) {
  return ref.watch(databaseProvider).payrollDao;
});

final currentMonthPayrollProvider = StreamProvider<List<PayrollRow>>((ref) {
  final now = DateTime.now();
  return ref.watch(payrollDaoProvider).watchPayroll(now.month, now.year);
});

class PayrollNotifier extends StateNotifier<AsyncValue<void>> {
  final PayrollDao _dao;

  PayrollNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<void> generatePayroll(int employeeId, int month, int year) async {
    state = await AsyncValue.guard(() async {
      await _dao.generatePayroll(employeeId, month, year);
    });
  }

  Future<void> markAsPaid(int payrollId) async {
    state = await AsyncValue.guard(() async {
      await _dao.markAsPaid(payrollId);
    });
  }
}

final payrollNotifierProvider = StateNotifierProvider<PayrollNotifier, AsyncValue<void>>((ref) {
  return PayrollNotifier(ref.watch(payrollDaoProvider));
});
