import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'shift_dao.g.dart';

@DriftAccessor(tables: [Shifts, ShiftSales, Products, Inventory, InventoryTransactions, Employees, Expenses])
class ShiftDao extends DatabaseAccessor<AppDatabase> with _$ShiftDaoMixin {
  ShiftDao(super.db);

  Future<int> createShift(ShiftsCompanion shift) => into(shifts).insert(shift);

  Future<Shift?> getActiveShift() async {
    final query = select(shifts)..where((s) => s.status.equals('active'));
    return query.getSingleOrNull();
  }

  Future<List<Shift>> getAllShifts() async {
    final query = select(shifts)..orderBy([(s) => OrderingTerm.desc(s.startDate)]);
    return query.get();
  }

  Future<List<Shift>> getShiftsByDateRange(DateTime start, DateTime end) async {
    final query = select(shifts)
      ..where((s) => s.startDate.isBetweenValues(start, end))
      ..orderBy([(s) => OrderingTerm.desc(s.startDate)]);
    return query.get();
  }

  Future<List<ShiftSalesRow>> getShiftSales(int shiftId) async {
    final query = select(shiftSales).join([
      innerJoin(products, products.id.equalsExp(shiftSales.productId)),
    ])
      ..where(shiftSales.shiftId.equals(shiftId));
    final results = await query.get();
    return results.map((row) {
      return ShiftSalesRow(
        sale: row.readTable(shiftSales),
        product: row.readTable(products),
      );
    }).toList();
  }

  Future<void> addSaleToShift(ShiftSalesCompanion sale) => into(shiftSales).insert(sale);

  Future<void> closeShift(int shiftId, int closedBy, double totalSales, double totalExpenses) async {
    await (update(shifts)..where((s) => s.id.equals(shiftId))).write(ShiftsCompanion(
      status: const Value('closed'),
      endDate: Value(DateTime.now()),
      closedBy: Value(closedBy),
      totalSales: Value(totalSales),
      totalExpenses: Value(totalExpenses),
    ));
  }

  Future<double> calculateShiftTotalSales(int shiftId) async {
    final query = select(shiftSales)
      ..where((s) => s.shiftId.equals(shiftId));
    final sales = await query.get();
    return sales.fold<double>(0.0, (sum, sale) => sum + sale.totalAmount);
  }

  Future<double> getShiftExpenses(int shiftId) async {
    final query = select(db.expenses)
      ..where((e) => e.shiftId.equals(shiftId));
    final expenses = await query.get();
    return expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
  }

  Stream<Shift?> watchActiveShift() {
    final query = select(shifts)..where((s) => s.status.equals('active'));
    return query.watchSingleOrNull();
  }

  Stream<List<Shift>> watchAllShifts() {
    final query = select(shifts)..orderBy([(s) => OrderingTerm.desc(s.startDate)]);
    return query.watch();
  }

  Future<Map<String, double>> getTodaySummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final todayShifts = await (select(shifts)
          ..where((s) =>
              s.startDate.isBetweenValues(startOfDay, endOfDay) &
              s.status.equals('closed')))
        .get();

    final todayExpenses = await (select(db.expenses)
          ..where((e) => e.date.isBetweenValues(startOfDay, endOfDay)))
        .get();

    final totalSales = todayShifts.fold<double>(0.0, (sum, s) => sum + s.totalSales);
    final totalExpenses = todayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    return {
      'sales': totalSales,
      'expenses': totalExpenses,
      'profit': totalSales - totalExpenses,
    };
  }

  Future<List<MapEntry<DateTime, double>>> getWeeklySalesData() async {
    final now = DateTime.now();
    final results = <MapEntry<DateTime, double>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));

      final dayShifts = await (select(shifts)
            ..where((s) =>
                s.startDate.isBetweenValues(day, nextDay) &
                s.status.equals('closed')))
          .get();

      final totalSales = dayShifts.fold<double>(0.0, (sum, s) => sum + s.totalSales);
      results.add(MapEntry(day, totalSales));
    }

    return results;
  }
}

class ShiftSalesRow {
  final ShiftSale sale;
  final Product product;
  ShiftSalesRow({required this.sale, required this.product});
}
