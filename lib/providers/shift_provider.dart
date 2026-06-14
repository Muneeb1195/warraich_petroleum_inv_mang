import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/shift_dao.dart';
import 'database_provider.dart';

final shiftDaoProvider = Provider<ShiftDao>((ref) {
  return ref.watch(databaseProvider).shiftDao;
});

final activeShiftProvider = StreamProvider<Shift?>((ref) {
  return ref.watch(shiftDaoProvider).watchActiveShift();
});

final allShiftsProvider = StreamProvider<List<Shift>>((ref) {
  return ref.watch(shiftDaoProvider).watchAllShifts();
});

final shiftSalesProvider = FutureProvider.family<List<ShiftSalesRow>, int>((ref, shiftId) {
  return ref.watch(shiftDaoProvider).getShiftSales(shiftId);
});

final todaySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(shiftDaoProvider).getTodaySummary();
});

final weeklySalesProvider = FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  return ref.watch(shiftDaoProvider).getWeeklySalesData();
});

final weeklyExpensesProvider = FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  return ref.watch(shiftDaoProvider).getWeeklyExpensesData();
});

final weeklyProfitProvider = FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  return ref.watch(shiftDaoProvider).getWeeklyProfitData();
});

final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  final now = DateTime.now();
  return ref.watch(shiftDaoProvider).getMonthlySummary(now.month, now.year);
});

final recentExpensesProvider = FutureProvider<List<Expense>>((ref) {
  return ref.watch(shiftDaoProvider).getRecentExpenses(limit: 5);
});

final employeeCountProvider = FutureProvider<int>((ref) {
  return ref.watch(shiftDaoProvider).getActiveEmployeeCount();
});

class ShiftNotifier extends StateNotifier<AsyncValue<void>> {
  final ShiftDao _dao;
  final AppDatabase _db;

  ShiftNotifier(this._dao, this._db) : super(const AsyncValue.data(null));

  Future<void> startShift(String type, {DateTime? dateTime}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final active = await _dao.getActiveShift();
      if (active != null) throw Exception('An active shift already exists');
      await _dao.createShift(ShiftsCompanion.insert(
        type: type,
        startDate: dateTime ?? DateTime.now(),
      ));
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
    final quantity = closingReading - openingReading;
    final totalAmount = cash + card + credit;
    state = await AsyncValue.guard(() async {
      await _dao.addSaleToShift(ShiftSalesCompanion.insert(
        shiftId: shiftId,
        productId: productId,
        openingReading: Value(openingReading),
        closingReading: Value(closingReading),
        quantitySold: Value(quantity),
        totalAmount: Value(totalAmount),
        cashCollected: Value(cash),
        cardCollected: Value(card),
        creditCollected: Value(credit),
      ));
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
    final quantity = closingReading - openingReading;
    final totalAmount = cash + card + credit;
    state = await AsyncValue.guard(() async {
      await _dao.updateSaleInShift(saleId, ShiftSalesCompanion(
        shiftId: Value(shiftId),
        productId: Value(productId),
        openingReading: Value(openingReading),
        closingReading: Value(closingReading),
        quantitySold: Value(quantity),
        totalAmount: Value(totalAmount),
        cashCollected: Value(cash),
        cardCollected: Value(card),
        creditCollected: Value(credit),
      ));
    });
  }

  Future<void> deleteSaleFromShift(int saleId) async {
    state = await AsyncValue.guard(() async {
      await _dao.deleteSaleFromShift(saleId);
    });
  }

  Future<void> closeShift(int shiftId, int? closedBy) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final shift = await _dao.getShiftById(shiftId);
      if (shift == null || shift.status == 'closed') return;

      await _db.transaction(() async {
        final sales = await _dao.getShiftSales(shiftId);
        final totalSales = sales.fold<double>(0.0, (sum, row) => sum + row.sale.totalAmount);
        final totalExpenses = await _dao.getShiftExpenses(shiftId);

        for (final row in sales) {
          final inventoryItem = await _db.productDao.getInventory(row.product.id);
          if (inventoryItem != null && row.sale.quantitySold > 0) {
            await _db.productDao.deductStock(row.product.id, row.sale.quantitySold, shiftId);
          }
        }

        await _dao.closeShift(shiftId, closedBy, totalSales, totalExpenses);
      });
    });
  }
}

final shiftNotifierProvider = StateNotifierProvider<ShiftNotifier, AsyncValue<void>>((ref) {
  final dao = ref.watch(shiftDaoProvider);
  final db = ref.watch(databaseProvider);
  return ShiftNotifier(dao, db);
});
