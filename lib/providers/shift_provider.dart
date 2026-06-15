import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/shift_repository.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

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

final shiftSalesProvider = FutureProvider.family<List<ShiftSalesRow>, int>((ref, shiftId) {
  return ref.watch(shiftRepositoryProvider).getShiftSales(shiftId);
});

final todaySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  return ref.watch(shiftRepositoryProvider).getTodaySummary();
});

final weeklySalesProvider = FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  return ref.watch(shiftRepositoryProvider).getWeeklySalesData();
});

final weeklyExpensesProvider = FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  return ref.watch(shiftRepositoryProvider).getWeeklyExpensesData();
});

final weeklyProfitProvider = FutureProvider<List<MapEntry<DateTime, double>>>((ref) {
  return ref.watch(shiftRepositoryProvider).getWeeklyProfitData();
});

final monthlySummaryProvider = FutureProvider<Map<String, double>>((ref) {
  final now = DateTime.now();
  return ref.watch(shiftRepositoryProvider).getMonthlySummary(now.month, now.year);
});

final recentExpensesProvider = FutureProvider<List<Expense>>((ref) {
  return ref.watch(shiftRepositoryProvider).getRecentExpenses(limit: 5);
});

final employeeCountProvider = FutureProvider<int>((ref) {
  return ref.watch(shiftRepositoryProvider).getActiveEmployeeCount();
});

class ShiftNotifier extends StateNotifier<AsyncValue<void>> {
  final ShiftRepository _repo;
  final SyncService? _sync;

  ShiftNotifier(this._repo, this._sync) : super(const AsyncValue.data(null));

  Future<void> startShift(String type, {DateTime? dateTime}) async {
    state = const AsyncValue.loading();
    int id = 0;
    state = await AsyncValue.guard(() async {
      id = await _repo.createShift(type, dateTime: dateTime);
    });
    if (id > 0) {
      final shift = await _repo.getShiftById(id);
      if (shift != null) {
        await _sync?.syncRecord('shifts', id.toString(), {
          'id': shift.id,
          'type': shift.type,
          'status': shift.status,
          'startDate': shift.startDate.toIso8601String(),
          'endDate': shift.endDate?.toIso8601String(),
          'closedBy': shift.closedBy,
          'totalSales': shift.totalSales,
          'totalExpenses': shift.totalExpenses,
          'updatedAt': shift.updatedAt.toIso8601String(),
        });
      }
    }
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
    if (quantity <= 0) throw Exception('Sale quantity must be greater than 0');
    final totalAmount = cash + card + credit;
    if (totalAmount <= 0) throw Exception('Sale amount must be greater than 0');
    int id = 0;
    state = await AsyncValue.guard(() async {
      id = await _repo.addSaleToShift(
        shiftId, productId, openingReading, closingReading,
        pricePerUnit, cash, card, credit,
      );
    });
    if (id > 0) {
      final now = DateTime.now();
      await _sync?.syncRecord('shift_sales', id.toString(), {
        'id': id,
        'shiftId': shiftId,
        'productId': productId,
        'openingReading': openingReading,
        'closingReading': closingReading,
        'quantitySold': quantity,
        'totalAmount': totalAmount,
        'cashCollected': cash,
        'cardCollected': card,
        'creditCollected': credit,
        'updatedAt': now.toIso8601String(),
      });
    }
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
    if (quantity <= 0) throw Exception('Sale quantity must be greater than 0');
    final totalAmount = cash + card + credit;
    if (totalAmount <= 0) throw Exception('Sale amount must be greater than 0');
    state = await AsyncValue.guard(() => _repo.updateSaleInShift(
      saleId, shiftId, productId, openingReading, closingReading,
      pricePerUnit, cash, card, credit,
    ));
    if (_sync != null) {
      final now = DateTime.now();
      await _sync.syncRecord('shift_sales', saleId.toString(), {
        'id': saleId,
        'shiftId': shiftId,
        'productId': productId,
        'openingReading': openingReading,
        'closingReading': closingReading,
        'quantitySold': quantity,
        'totalAmount': totalAmount,
        'cashCollected': cash,
        'cardCollected': card,
        'creditCollected': credit,
        'updatedAt': now.toIso8601String(),
      });
    }
  }

  Future<void> deleteSaleFromShift(int saleId) async {
    state = await AsyncValue.guard(() => _repo.deleteSaleFromShift(saleId));
    await _sync?.deleteRecord('shift_sales', saleId.toString());
  }

  Future<void> closeShift(int shiftId, int? closedBy) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.closeShift(shiftId, closedBy));
    if (_sync != null) {
      final shift = await _repo.getShiftById(shiftId);
      if (shift != null) {
        await _sync.syncRecord('shifts', shiftId.toString(), {
          'id': shift.id,
          'type': shift.type,
          'status': shift.status,
          'startDate': shift.startDate.toIso8601String(),
          'endDate': shift.endDate?.toIso8601String(),
          'closedBy': shift.closedBy,
          'totalSales': shift.totalSales,
          'totalExpenses': shift.totalExpenses,
          'updatedAt': shift.updatedAt.toIso8601String(),
        });
      }
    }
  }
}

final shiftNotifierProvider = StateNotifierProvider<ShiftNotifier, AsyncValue<void>>((ref) {
  return ShiftNotifier(
    ref.watch(shiftRepositoryProvider),
    ref.read(syncServiceProvider),
  );
});
