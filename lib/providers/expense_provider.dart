import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/expense_dao.dart';
import 'database_provider.dart';

final expenseDaoProvider = Provider<ExpenseDao>((ref) {
  return ref.watch(databaseProvider).expenseDao;
});

final allExpensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseDaoProvider).watchAllExpenses();
});

final expenseSummaryProvider = FutureProvider.family<Map<String, double>, ({DateTime start, DateTime end})>((ref, dates) {
  return ref.watch(expenseDaoProvider).getExpenseSummaryByCategory(dates.start, dates.end);
});

class ExpenseNotifier extends StateNotifier<AsyncValue<void>> {
  final ExpenseDao _dao;

  ExpenseNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<void> addExpense({
    required String category,
    required double amount,
    String? description,
    required DateTime date,
    int? shiftId,
    int? createdBy,
  }) async {
    state = await AsyncValue.guard(() async {
      await _dao.addExpense(ExpensesCompanion.insert(
        category: category,
        amount: amount,
        description: Value(description),
        date: date,
        shiftId: Value(shiftId),
        createdBy: Value(createdBy),
      ));
    });
  }

  Future<void> deleteExpense(int id) async {
    state = await AsyncValue.guard(() async {
      await _dao.deleteExpense(id);
    });
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  return ExpenseNotifier(ref.watch(expenseDaoProvider));
});
