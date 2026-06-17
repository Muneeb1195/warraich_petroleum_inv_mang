import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/shift_repository.dart';
import 'database_provider.dart';

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ShiftRepository(db.shiftDao, db.productDao, db);
});

final activeShiftProvider = StreamProvider<Shift?>((ref) {
  return ref.watch(shiftRepositoryProvider).watchActiveShift();
});

final allShiftsProvider = StreamProvider<List<Shift>>((ref) {
  return ref.watch(shiftRepositoryProvider).watchAllShifts();
});

final shiftSalesProvider = FutureProvider.family<List<ShiftSalesRow>, int>((
  ref,
  shiftId,
) {
  return ref.watch(shiftRepositoryProvider).getShiftSales(shiftId);
});

final todaySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(shiftRepositoryProvider).getTodaySummary();
});

final weeklySalesProvider = FutureProvider<List<MapEntry<DateTime, double>>>((
  ref,
) {
  return ref.watch(shiftRepositoryProvider).getWeeklySalesData();
});

final weeklyExpensesProvider = FutureProvider<List<MapEntry<DateTime, double>>>(
  (ref) {
    return ref.watch(shiftRepositoryProvider).getWeeklyExpensesData();
  },
);

final weeklyProfitProvider = FutureProvider<List<MapEntry<DateTime, double>>>((
  ref,
) {
  return ref.watch(shiftRepositoryProvider).getWeeklyProfitData();
});

final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  final now = DateTime.now();
  return ref
      .watch(shiftRepositoryProvider)
      .getMonthlySummary(now.month, now.year);
});

final recentExpensesProvider = FutureProvider<List<Expense>>((ref) {
  return ref.watch(shiftRepositoryProvider).getRecentExpenses(limit: 5);
});

final employeeCountProvider = FutureProvider<int>((ref) {
  return ref.watch(shiftRepositoryProvider).getActiveEmployeeCount();
});

class ShiftNotifier extends StateNotifier<AsyncValue<void>> {
  final ShiftRepository _repo;

  ShiftNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> startShift(String type, {DateTime? dateTime}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repo.createShift(type, dateTime: dateTime);
    });
  }

  Future<void> addSaleToShift(
    int shiftId,
    int productId,
    double openingReading,
    double closingReading,
    double pricePerUnit,
    double cash,
    double card,
    double credit,
  ) async {
    state = const AsyncValue.data(null);
    state = await AsyncValue.guard(() async {
      final quantity = closingReading - openingReading;
      if (quantity <= 0)
        throw Exception('Sale quantity must be greater than 0');
      final totalAmount = cash + card + credit;
      if (totalAmount <= 0)
        throw Exception('Sale amount must be greater than 0');
      await _repo.addSaleToShift(
        shiftId,
        productId,
        openingReading,
        closingReading,
        pricePerUnit,
        cash,
        card,
        credit,
      );
    });
  }

  Future<void> updateSaleInShift(
    int saleId,
    int shiftId,
    int productId,
    double openingReading,
    double closingReading,
    double pricePerUnit,
    double cash,
    double card,
    double credit,
  ) async {
    state = const AsyncValue.data(null);
    state = await AsyncValue.guard(() async {
      final quantity = closingReading - openingReading;
      if (quantity <= 0)
        throw Exception('Sale quantity must be greater than 0');
      final totalAmount = cash + card + credit;
      if (totalAmount <= 0)
        throw Exception('Sale amount must be greater than 0');
      await _repo.updateSaleInShift(
        saleId,
        shiftId,
        productId,
        openingReading,
        closingReading,
        pricePerUnit,
        cash,
        card,
        credit,
      );
    });
  }

  Future<void> deleteSaleFromShift(int saleId) async {
    state = const AsyncValue.data(null);
    state = await AsyncValue.guard(() => _repo.deleteSaleFromShift(saleId));
  }

  Future<void> closeShift(int shiftId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.closeShift(shiftId));
  }
}

final shiftNotifierProvider =
    StateNotifierProvider<ShiftNotifier, AsyncValue<void>>((ref) {
      return ShiftNotifier(ref.watch(shiftRepositoryProvider));
    });
