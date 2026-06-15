import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/payroll_repository.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(ref.watch(databaseProvider).payrollDao);
});

final currentMonthPayrollProvider = StreamProvider<List<PayrollRow>>((ref) {
  final now = DateTime.now();
  return ref.watch(payrollRepositoryProvider).watchPayroll(now.month, now.year);
});

class PayrollNotifier extends StateNotifier<AsyncValue<void>> {
  final PayrollRepository _repo;
  final SyncService? _sync;

  PayrollNotifier(this._repo, this._sync) : super(const AsyncValue.data(null));

  Future<void> generatePayroll(int employeeId, int month, int year) async {
    int id = 0;
    state = await AsyncValue.guard(() async {
      id = await _repo.generatePayroll(employeeId, month, year);
    });
    if (id > 0) {
      final payroll = await _repo.getPayrollById(id);
      if (payroll != null) {
        await _sync?.syncRecord('payroll', id.toString(), {
          'id': payroll.id,
          'employeeId': payroll.employeeId,
          'month': payroll.month,
          'year': payroll.year,
          'baseSalary': payroll.baseSalary,
          'deductions': payroll.deductions,
          'advances': payroll.advances,
          'bonuses': payroll.bonuses,
          'netPay': payroll.netPay,
          'isPaid': payroll.isPaid,
          'paidDate': payroll.paidDate?.toIso8601String(),
          'updatedAt': payroll.updatedAt.toIso8601String(),
        });
      }
    }
  }

  Future<void> markAsPaid(int payrollId) async {
    state = await AsyncValue.guard(() => _repo.markAsPaid(payrollId));
    if (_sync != null) {
      final payroll = await _repo.getPayrollById(payrollId);
      if (payroll != null) {
        await _sync.syncRecord('payroll', payrollId.toString(), {
          'id': payroll.id,
          'employeeId': payroll.employeeId,
          'month': payroll.month,
          'year': payroll.year,
          'baseSalary': payroll.baseSalary,
          'deductions': payroll.deductions,
          'advances': payroll.advances,
          'bonuses': payroll.bonuses,
          'netPay': payroll.netPay,
          'isPaid': payroll.isPaid,
          'paidDate': payroll.paidDate?.toIso8601String(),
          'updatedAt': payroll.updatedAt.toIso8601String(),
        });
      }
    }
  }
}

final payrollNotifierProvider = StateNotifierProvider<PayrollNotifier, AsyncValue<void>>((ref) {
  return PayrollNotifier(
    ref.watch(payrollRepositoryProvider),
    ref.read(syncServiceProvider),
  );
});
