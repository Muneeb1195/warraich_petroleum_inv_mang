import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/expense_repository.dart';
import 'database_provider.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseProvider).expenseDao);
});

final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});

final expenseSummaryProvider = FutureProvider.family<Map<String, double>, ({DateTime start, DateTime end})>((ref, dates) {
  return ref.watch(expenseRepositoryProvider).getSummaryByCategory(dates.start, dates.end);
});

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repo;

  ExpenseNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> addExpense({
    required String category,
    required double amount,
    String? description,
    required DateTime date,
    int? shiftId,
    int? createdBy,
  }) async {
    state = await AsyncValue.guard(() async {
      await _repo.addExpense(
        category: category,
        amount: amount,
        description: description,
        date: date,
        shiftId: shiftId,
        createdBy: createdBy,
      );
    });
  }

  Future<void> updateExpense({
    required int id,
    required String category,
    required double amount,
    String? description,
    required DateTime date,
    int? shiftId,
  }) async {
    state = await AsyncValue.guard(() => _repo.updateExpense(
      id: id,
      category: category,
      amount: amount,
      description: description,
      date: date,
      shiftId: shiftId,
    ));
  }

  Future<void> deleteExpense(int id) async {
    state = await AsyncValue.guard(() => _repo.deleteExpense(id));
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  return ExpenseNotifier(
    ref.watch(expenseRepositoryProvider),
  );
});
