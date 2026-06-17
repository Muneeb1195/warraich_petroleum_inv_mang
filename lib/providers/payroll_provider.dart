import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/payroll_repository.dart';
import 'database_provider.dart';

final payrollRepositoryProvider = Provider<PayrollRepository>((ref) {
  return PayrollRepository(ref.watch(databaseProvider).payrollDao);
});

final currentMonthPayrollProvider = StreamProvider<List<PayrollRow>>((ref) {
  final now = DateTime.now();
  return ref.watch(payrollRepositoryProvider).watchPayroll(now.month, now.year);
});

class PayrollNotifier extends StateNotifier<AsyncValue<void>> {
  final PayrollRepository _repo;

  PayrollNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> generatePayroll(int employeeId, int month, int year) async {
    state = await AsyncValue.guard(() async {
      await _repo.generatePayroll(employeeId, month, year);
    });
  }

  Future<void> markAsPaid(int payrollId) async {
    state = await AsyncValue.guard(() => _repo.markAsPaid(payrollId));
  }
}

final payrollNotifierProvider =
    StateNotifierProvider<PayrollNotifier, AsyncValue<void>>((ref) {
      return PayrollNotifier(ref.watch(payrollRepositoryProvider));
    });
