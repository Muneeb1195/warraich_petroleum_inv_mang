import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'shift_dao.g.dart';

@DriftAccessor(tables: [Shifts, ShiftSales, Products, Inventory, InventoryTransactions, Employees, Expenses])
class ShiftDao extends DatabaseAccessor<AppDatabase> with _$ShiftDaoMixin {
  ShiftDao(super.db);

  Future<int> createShift(ShiftsCompanion shift) => into(shifts).insert(shift);

  Future<Shift?> getActiveShift() async {
    return (select(shifts)..where((s) => s.status.equals('active'))).getSingleOrNull();
  }

  Future<Shift?> getShiftById(int id) async {
    return (select(shifts)..where((s) => s.id.equals(id))).getSingleOrNull();
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

  Future<void> updateSaleInShift(int saleId, ShiftSalesCompanion sale) async {
    await (update(shiftSales)..where((s) => s.id.equals(saleId))).write(sale);
  }

  Future<void> deleteSaleFromShift(int saleId) async {
    await (delete(shiftSales)..where((s) => s.id.equals(saleId))).go();
  }

  Future<void> closeShift(int shiftId, int? closedBy, double totalSales, double totalExpenses) async {
    await (update(shifts)..where((s) => s.id.equals(shiftId))).write(ShiftsCompanion(
      status: const Value('closed'),
      endDate: Value(DateTime.now()),
      closedBy: Value(closedBy),
      totalSales: Value(totalSales),
      totalExpenses: Value(totalExpenses),
    ));
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
          ..where((e) => e.date.isBetweenValues(startOfDay, endOfDay) & e.category.equals('Supplier').not()))
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
    final sevenDaysAgo = DateTime(now.year, now.month, now.day - 6);
    final endOfToday = DateTime(now.year, now.month, now.day + 1);

    // Fetch all closed shifts in the entire week in a single query
    final allShifts = await (select(shifts)
          ..where((s) =>
              s.startDate.isBetweenValues(sevenDaysAgo, endOfToday) &
              s.status.equals('closed')))
        .get();

    final results = <MapEntry<DateTime, double>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));

      // Filter shifts for this day in-memory
      final dayShifts = allShifts.where((s) =>
          s.startDate.isAfter(day.subtract(const Duration(microseconds: 1))) &&
          s.startDate.isBefore(nextDay));

      final totalSales = dayShifts.fold<double>(0.0, (sum, s) => sum + s.totalSales);
      results.add(MapEntry(day, totalSales));
    }

    return results;
  }

  Future<List<MapEntry<DateTime, double>>> getWeeklyExpensesData() async {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day - 6);
    final endOfToday = DateTime(now.year, now.month, now.day + 1);

    final allExpenses = await (select(db.expenses)
          ..where((e) => e.date.isBetweenValues(sevenDaysAgo, endOfToday) & e.category.equals('Supplier').not()))
        .get();

    final results = <MapEntry<DateTime, double>>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final nextDay = day.add(const Duration(days: 1));

      final dayExpenses = allExpenses.where((e) =>
          e.date.isAfter(day.subtract(const Duration(microseconds: 1))) &&
          e.date.isBefore(nextDay));

      final totalExpenses = dayExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);
      results.add(MapEntry(day, totalExpenses));
    }

    return results;
  }

  Future<List<MapEntry<DateTime, double>>> getWeeklyProfitData() async {
    final sales = await getWeeklySalesData();
    final expenses = await getWeeklyExpensesData();

    return List.generate(7, (i) {
      return MapEntry(sales[i].key, sales[i].value - expenses[i].value);
    });
  }

  Future<Map<String, double>> getMonthlySummary(int month, int year) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);

    final monthShifts = await (select(shifts)
          ..where((s) => s.startDate.isBetweenValues(start, end) & s.status.equals('closed')))
        .get();

    final monthExpenses = await (select(db.expenses)
          ..where((e) => e.date.isBetweenValues(start, end) & e.category.equals('Supplier').not()))
        .get();

    final totalSales = monthShifts.fold<double>(0.0, (sum, s) => sum + s.totalSales);
    final totalExpenses = monthExpenses.fold<double>(0.0, (sum, e) => sum + e.amount);

    return {
      'sales': totalSales,
      'expenses': totalExpenses,
      'profit': totalSales - totalExpenses,
    };
  }

  Future<int> getActiveEmployeeCount() async {
    final result = await (select(db.employees)..where((e) => e.isActive.equals(true))).get();
    return result.length;
  }

  Future<List<Expense>> getRecentExpenses({int limit = 5}) async {
    return (select(db.expenses)
          ..orderBy([(e) => OrderingTerm.desc(e.date)])
          ..limit(limit))
        .get();
  }
}

class ShiftSalesRow {
  final ShiftSale sale;
  final Product product;
  ShiftSalesRow({required this.sale, required this.product});
}
