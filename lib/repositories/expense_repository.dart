import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';

class ExpenseRepository {
  final ExpenseDao _dao;

  ExpenseRepository(this._dao);

  Future<int> addExpense({
    required String category,
    required double amount,
    String? description,
    required DateTime date,
    int? shiftId,
    int? createdBy,
  }) async {
    return _dao.addExpense(ExpensesCompanion.insert(
      category: category,
      amount: amount,
      description: Value(description),
      date: date,
      shiftId: Value(shiftId),
      createdBy: Value(createdBy),
    ));
  }

  Future<void> updateExpense({
    required int id,
    required String category,
    required double amount,
    String? description,
    required DateTime date,
    int? shiftId,
  }) async {
    await _dao.updateExpense(id, ExpensesCompanion(
      category: Value(category),
      amount: Value(amount),
      description: Value(description),
      date: Value(date),
      shiftId: Value(shiftId),
    ));
  }

  Future<void> deleteExpense(int id) async {
    await _dao.deleteExpense(id);
  }

  Future<Expense?> getExpenseById(int id) => _dao.getExpenseById(id);

  Stream<List<Expense>> watchAll() => _dao.watchAllExpenses();

  Future<Map<String, double>> getSummaryByCategory(DateTime start, DateTime end) =>
      _dao.getExpenseSummaryByCategory(start, end);
}
