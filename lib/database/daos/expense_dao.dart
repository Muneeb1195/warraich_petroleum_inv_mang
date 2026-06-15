import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Future<int> addExpense(ExpensesCompanion expense) => into(expenses).insert(expense);

  Future<List<Expense>> getAllExpenses() async {
    return (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).get();
  }

  Stream<List<Expense>> watchAllExpenses() {
    return (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.date)])).watch();
  }

  Future<List<Expense>> getExpensesByCategory(String category) async {
    return (select(expenses)
          ..where((e) => e.category.equals(category))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) async {
    return (select(expenses)
          ..where((e) => e.date.isBetweenValues(start, end))
          ..orderBy([(e) => OrderingTerm.desc(e.date)]))
        .get();
  }

  Future<Map<String, double>> getExpenseSummaryByCategory(DateTime start, DateTime end) async {
    final expensesList = await getExpensesByDateRange(start, end);
    final summary = <String, double>{};
    for (final expense in expensesList) {
      summary[expense.category] = (summary[expense.category] ?? 0) + expense.amount;
    }
    return summary;
  }

  Future<double> getTotalExpenses(DateTime start, DateTime end) async {
    final expensesList = await getExpensesByDateRange(start, end);
    return expensesList.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Future<void> updateExpense(int id, ExpensesCompanion expense) async {
    await (update(expenses)..where((e) => e.id.equals(id))).write(expense);
  }

  Future<Expense?> getExpenseById(int id) async {
    return (select(expenses)..where((e) => e.id.equals(id))).getSingleOrNull();
  }

  Future<void> deleteExpense(int id) async {
    await (delete(expenses)..where((e) => e.id.equals(id))).go();
  }
}
