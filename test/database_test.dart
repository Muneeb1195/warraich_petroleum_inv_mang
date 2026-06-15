import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:warraich_petroleum/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(executor: NativeDatabase.memory());
    await Future.delayed(Duration.zero);
  });

  tearDown(() async {
    await db.close();
  });

  group('Products & Inventory', () {
    test('seeds 6 products on creation', () async {
      final products = await db.select(db.products).get();
      expect(products.length, 6);
    });

    test('updates product price', () async {
      final product = (await db.select(db.products).get()).first;
      await (db.update(db.products)..where((p) => p.id.equals(product.id)))
          .write(const ProductsCompanion(pricePerUnit: Value(250.0)));
      final updated = await (db.select(db.products)..where((p) => p.id.equals(product.id)))
          .getSingle();
      expect(updated.pricePerUnit, 250.0);
    });

    test('adds stock and creates supplier expense', () async {
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 500, 245.0, null);
      final inventory = await db.productDao.getInventory(product.id);
      expect(inventory, isNotNull);
      expect(inventory!.currentStock, 500);

      final expenses = await db.select(db.expenses).get();
      expect(expenses.any((e) => e.category == 'Supplier'), isTrue);
    });

    test('deducts stock and throws on insufficient', () async {
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 100, 240.0, null);
      await db.productDao.deductStock(product.id, 60, null);
      final inv = await db.productDao.getInventory(product.id);
      expect(inv!.currentStock, 40);

      expect(
        () => db.productDao.deductStock(product.id, 100, null),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Shifts & Sales', () {
    test('creates and closes a shift with inventory deduction', () async {
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 1000, 240.0, null);
      final today = DateTime.now();

      final shiftId = await db.into(db.shifts).insert(ShiftsCompanion.insert(
        type: 'morning',
        startDate: today,
      ));

      await db.into(db.shiftSales).insert(ShiftSalesCompanion.insert(
        shiftId: shiftId,
        productId: product.id,
        openingReading: const Value(0),
        closingReading: const Value(50),
        quantitySold: const Value(50),
        totalAmount: const Value(12500),
        cashCollected: const Value(12500),
        cardCollected: const Value(0),
        creditCollected: const Value(0),
      ));

      await db.shiftDao.closeShift(shiftId, null, 12500, 0);

      final closed = await db.shiftDao.getShiftById(shiftId);
      expect(closed, isNotNull);
      expect(closed!.status, 'closed');
      expect(closed.totalSales, 12500);

      final inv = await db.productDao.getInventory(product.id);
      expect(inv!.currentStock, 1000);
    });

    test('gets active shift', () async {
      final today = DateTime.now();
      await db.into(db.shifts).insert(ShiftsCompanion.insert(
        type: 'evening',
        startDate: today,
      ));

      final active = await db.shiftDao.getActiveShift();
      expect(active, isNotNull);
      expect(active!.type, 'evening');
    });
  });

  group('Expenses', () {
    test('adds and queries expenses', () async {
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        category: 'Electricity',
        amount: 5000,
        date: DateTime.now(),
      ));
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
        category: 'Transport',
        amount: 2000,
        date: DateTime.now(),
      ));

      final all = await db.select(db.expenses).get();
      expect(all.length, 2);
      expect(all.fold<double>(0, (s, e) => s + e.amount), 7000);
    });
  });

  group('Employees & Payroll', () {
    test('adds employee', () async {
      final id = await db.into(db.employees).insert(EmployeesCompanion.insert(
        name: 'John Doe',
        role: 'Operator',
        salary: const Value(30000.0),
      ));
      final emp = await (db.select(db.employees)..where((e) => e.id.equals(id)))
          .getSingle();
      expect(emp.name, 'John Doe');
      expect(emp.salary, 30000.0);
    });

    test('generates and pays payroll', () async {
      final empId = await db.into(db.employees).insert(EmployeesCompanion.insert(
        name: 'Jane Doe',
        role: 'Manager',
        salary: const Value(50000.0),
      ));

      await db.payrollDao.generatePayroll(empId, 6, 2024);
      var records = await db.payrollDao.getPayroll(6, 2024);
      expect(records.length, 1);
      expect(records.first.netPay, 50000.0);

      await db.payrollDao.markAsPaid(records.first.id);
      records = await db.payrollDao.getPayroll(6, 2024);
      expect(records.first.isPaid, isTrue);
    });
  });

  group('Dashboard Summary', () {
    test('returns zero when no data', () async {
      final summary = await db.shiftDao.getTodaySummary();
      expect(summary['sales'], 0.0);
      expect(summary['expenses'], 0.0);
      expect(summary['profit'], 0.0);
    });

    test('reflects closed shifts', () async {
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 1000, 240.0, null);
      final today = DateTime.now();

      final shiftId = await db.into(db.shifts).insert(ShiftsCompanion.insert(
        type: 'morning',
        startDate: today,
      ));
      await db.into(db.shiftSales).insert(ShiftSalesCompanion.insert(
        shiftId: shiftId,
        productId: product.id,
        openingReading: const Value(0),
        closingReading: const Value(100),
        quantitySold: const Value(100),
        totalAmount: const Value(25000),
        cashCollected: const Value(25000),
        cardCollected: const Value(0),
        creditCollected: const Value(0),
      ));
      await db.shiftDao.closeShift(shiftId, null, 25000, 0);

      final summary = await db.shiftDao.getTodaySummary();
      expect(summary['sales'], 25000.0);
    });
  });
}
