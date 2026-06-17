import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart';

class ShiftRepository {
  final ShiftDao _shiftDao;
  final ProductDao _productDao;
  final AppDatabase _db;

  ShiftRepository(this._shiftDao, this._productDao, this._db);

  Future<int> createShift(String type, {DateTime? dateTime}) async {
    return await _db.transaction(() async {
      final active = await _shiftDao.getActiveShift();
      if (active != null) throw Exception('An active shift already exists');
      return _shiftDao.createShift(
        ShiftsCompanion.insert(
          type: type,
          startDate: dateTime ?? DateTime.now(),
        ),
      );
    });
  }

  Future<Shift?> getActiveShift() => _shiftDao.getActiveShift();
  Future<Shift?> getShiftById(int id) => _shiftDao.getShiftById(id);
  Stream<Shift?> watchActiveShift() => _shiftDao.watchActiveShift();
  Stream<List<Shift>> watchAllShifts() => _shiftDao.watchAllShifts();

  Future<int> addSaleToShift(
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

    return _db.transaction(() async {
      final inventory = await _productDao.getInventory(productId);
      if (inventory != null && inventory.currentStock < quantity) {
        throw Exception(
          'Insufficient stock: ${inventory.currentStock.toStringAsFixed(1)} available, ${quantity.toStringAsFixed(1)} requested',
        );
      }

      final existingSales = await _shiftDao.getShiftSales(shiftId);
      final existingQtyForProduct = existingSales
          .where((row) => row.product.id == productId)
          .fold<double>(0.0, (sum, row) => sum + row.sale.quantitySold);

      if (inventory != null &&
          (existingQtyForProduct + quantity) > inventory.currentStock) {
        throw Exception(
          'Sale would exceed available stock: ${(inventory.currentStock - existingQtyForProduct).toStringAsFixed(1)} remaining for this product',
        );
      }

      return _shiftDao.addSaleToShift(
        ShiftSalesCompanion.insert(
          shiftId: shiftId,
          productId: productId,
          openingReading: Value(openingReading),
          closingReading: Value(closingReading),
          quantitySold: Value(quantity),
          totalAmount: Value(totalAmount),
          cashCollected: Value(cash),
          cardCollected: Value(card),
          creditCollected: Value(credit),
        ),
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
    final quantity = closingReading - openingReading;
    if (quantity <= 0) throw Exception('Sale quantity must be greater than 0');
    final totalAmount = cash + card + credit;
    if (totalAmount <= 0) throw Exception('Sale amount must be greater than 0');

    await _db.transaction(() async {
      final inventory = await _productDao.getInventory(productId);
      final existingSales = await _shiftDao.getShiftSales(shiftId);
      final existingQtyForProduct = existingSales
          .where(
            (row) => row.product.id == productId && row.sale.id != saleId,
          )
          .fold<double>(0.0, (sum, row) => sum + row.sale.quantitySold);

      if (inventory != null &&
          (existingQtyForProduct + quantity) > inventory.currentStock) {
        throw Exception(
          'Update would exceed available stock: ${(inventory.currentStock - existingQtyForProduct).toStringAsFixed(1)} remaining for this product',
        );
      }

      await _shiftDao.updateSaleInShift(
        saleId,
        ShiftSalesCompanion(
          shiftId: Value(shiftId),
          productId: Value(productId),
          openingReading: Value(openingReading),
          closingReading: Value(closingReading),
          quantitySold: Value(quantity),
          totalAmount: Value(totalAmount),
          cashCollected: Value(cash),
          cardCollected: Value(card),
          creditCollected: Value(credit),
        ),
      );
    });
  }

  Future<void> deleteSaleFromShift(int saleId) async {
    final sale = await _shiftDao.getSaleById(saleId);
    if (sale == null) return;
    final shift = await _shiftDao.getShiftById(sale.shiftId);
    if (shift == null) return;

    await _db.transaction(() async {
      if (sale.quantitySold > 0 && shift.status == 'closed') {
        await _productDao.addStock(
          sale.productId,
          sale.quantitySold,
          0,
          'Restored from deleted sale #$saleId',
        );
      }
      await _shiftDao.deleteSaleFromShift(saleId);
    });
  }

  Future<void> closeShift(int shiftId) async {
    final shift = await _shiftDao.getShiftById(shiftId);
    if (shift == null || shift.status == 'closed') return;

    await _db.transaction(() async {
      final sales = await _shiftDao.getShiftSales(shiftId);
      final totalSales = sales.fold<double>(
        0.0,
        (sum, row) => sum + row.sale.totalAmount,
      );
      final totalExpenses = await _shiftDao.getShiftExpenses(shiftId);

      for (final row in sales) {
        final inventoryItem = await _productDao.getInventory(row.product.id);
        if (inventoryItem != null && row.sale.quantitySold > 0) {
          await _productDao.deductStock(
            row.product.id,
            row.sale.quantitySold,
            shiftId,
          );
        }
      }

      await _shiftDao.closeShift(shiftId, totalSales, totalExpenses);
    });
  }

  Future<List<ShiftSalesRow>> getShiftSales(int shiftId) =>
      _shiftDao.getShiftSales(shiftId);
  Future<ShiftSale?> getSaleById(int saleId) => _shiftDao.getSaleById(saleId);
  Future<double> getShiftExpenses(int shiftId) =>
      _shiftDao.getShiftExpenses(shiftId);

  Future<Map<String, double>> getTodaySummary() => _shiftDao.getTodaySummary();
  Future<List<MapEntry<DateTime, double>>> getWeeklySalesData() =>
      _shiftDao.getWeeklySalesData();
  Future<List<MapEntry<DateTime, double>>> getWeeklyExpensesData() =>
      _shiftDao.getWeeklyExpensesData();
  Future<List<MapEntry<DateTime, double>>> getWeeklyProfitData() =>
      _shiftDao.getWeeklyProfitData();
  Future<Map<String, double>> getMonthlySummary(int month, int year) =>
      _shiftDao.getMonthlySummary(month, year);
  Future<List<Expense>> getRecentExpenses({int limit = 5}) =>
      _shiftDao.getRecentExpenses(limit: limit);
  Future<int> getActiveEmployeeCount() => _shiftDao.getActiveEmployeeCount();
}
