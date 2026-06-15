import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/expense_repository.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

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
  final SyncService? _sync;

  ExpenseNotifier(this._repo, this._sync) : super(const AsyncValue.data(null));

  Future<void> addExpense({
    required String category,
    required double amount,
    String? description,
    required DateTime date,
    int? shiftId,
    int? createdBy,
  }) async {
    int id = 0;
    state = await AsyncValue.guard(() async {
      id = await _repo.addExpense(
        category: category,
        amount: amount,
        description: description,
        date: date,
        shiftId: shiftId,
        createdBy: createdBy,
      );
    });
    if (id > 0) {
      final saved = await _repo.getExpenseById(id);
      final nowStr = saved != null
          ? saved.updatedAt.toIso8601String()
          : DateTime.now().toIso8601String();
      await _sync?.syncRecord('expenses', id.toString(), {
        'id': id,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'shiftId': shiftId,
        'createdBy': createdBy,
        'updatedAt': nowStr,
      });
    }
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
    if (_sync != null) {
      final saved = await _repo.getExpenseById(id);
      final nowStr = saved != null
          ? saved.updatedAt.toIso8601String()
          : DateTime.now().toIso8601String();
      await _sync.syncRecord('expenses', id.toString(), {
        'id': id,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'shiftId': shiftId,
        'updatedAt': nowStr,
      });
    }
  }

  Future<void> deleteExpense(int id) async {
    state = await AsyncValue.guard(() => _repo.deleteExpense(id));
    await _sync?.deleteRecord('expenses', id.toString());
  }
}

final expenseNotifierProvider = StateNotifierProvider<ExpenseNotifier, AsyncValue<void>>((ref) {
  return ExpenseNotifier(
    ref.watch(expenseRepositoryProvider),
    ref.read(syncServiceProvider),
  );
});
