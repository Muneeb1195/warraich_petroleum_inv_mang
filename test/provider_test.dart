import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:warraich_petroleum/database/app_database.dart';
import 'package:warraich_petroleum/providers/database_provider.dart';
import 'package:warraich_petroleum/providers/shift_provider.dart';
import 'package:warraich_petroleum/providers/expense_provider.dart';
import 'package:warraich_petroleum/providers/employee_provider.dart';

ProviderContainer createContainer() {
  final db = AppDatabase(executor: NativeDatabase.memory());
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWith((ref) => db),
    ],
  );
}

void main() {
  group('ShiftNotifier', () {
    test('starts a shift and rejects duplicate', () async {
      final container = createContainer();
      addTearDown(() => container.dispose());

      final notifier = container.read(shiftNotifierProvider.notifier);
      await notifier.startShift('morning');
      expect(container.read(shiftNotifierProvider).hasError, isFalse);

      await notifier.startShift('evening');
      expect(container.read(shiftNotifierProvider).hasError, isTrue);
    });

    test('adds and deletes a sale with stock restoration from closed shift', () async {
      final container = createContainer();
      addTearDown(() => container.dispose());

      final db = container.read(databaseProvider);
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 1000, 240, null);

      final notifier = container.read(shiftNotifierProvider.notifier);
      await notifier.startShift('morning');
      var shift = await db.shiftDao.getActiveShift();

      await notifier.addSaleToShift(shift!.id, product.id, 0, 100, 250, 25000, 0, 0);
      expect(container.read(shiftNotifierProvider).hasError, isFalse);

      await notifier.closeShift(shift.id, null);
      expect(container.read(shiftNotifierProvider).hasError, isFalse);

      shift = await db.shiftDao.getShiftById(shift.id);
      expect(shift!.status, 'closed');

      var inv = await db.productDao.getInventory(product.id);
      expect(inv!.currentStock, 900);

      final sales = await db.shiftDao.getShiftSales(shift.id);
      await notifier.deleteSaleFromShift(sales.first.sale.id);
      expect(container.read(shiftNotifierProvider).hasError, isFalse);

      inv = await db.productDao.getInventory(product.id);
      expect(inv!.currentStock, 1000);
    });

    test('does not restore stock when deleting from active shift', () async {
      final container = createContainer();
      addTearDown(() => container.dispose());

      final db = container.read(databaseProvider);
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 1000, 240, null);

      final notifier = container.read(shiftNotifierProvider.notifier);
      await notifier.startShift('morning');
      final shift = await db.shiftDao.getActiveShift();

      await notifier.addSaleToShift(shift!.id, product.id, 0, 100, 250, 25000, 0, 0);
      final sales = await db.shiftDao.getShiftSales(shift.id);

      await notifier.deleteSaleFromShift(sales.first.sale.id);
      expect(container.read(shiftNotifierProvider).hasError, isFalse);

      final inv = await db.productDao.getInventory(product.id);
      expect(inv!.currentStock, 1000);
    });

    test('rejects sale with zero quantity', () async {
      final container = createContainer();
      addTearDown(() => container.dispose());

      final db = container.read(databaseProvider);
      final product = (await db.select(db.products).get()).first;
      await db.productDao.addStock(product.id, 1000, 240, null);
      final notifier = container.read(shiftNotifierProvider.notifier);
      await notifier.startShift('morning');
      final shift = await db.shiftDao.getActiveShift();

      expect(
        () => notifier.addSaleToShift(shift!.id, product.id, 100, 100, 250, 0, 0, 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('ExpenseNotifier', () {
    test('adds, updates, and deletes an expense', () async {
      final container = createContainer();
      addTearDown(() => container.dispose());

      final notifier = container.read(expenseNotifierProvider.notifier);
      await notifier.addExpense(category: 'Electricity', amount: 5000, date: DateTime.now());
      expect(container.read(expenseNotifierProvider).hasError, isFalse);

      final db = container.read(databaseProvider);
      var expenses = await db.select(db.expenses).get();
      expect(expenses.length, 1);
      expect(expenses.first.amount, 5000);

      await notifier.updateExpense(id: expenses.first.id, category: 'Maintenance', amount: 6000, date: DateTime.now());
      expenses = await db.select(db.expenses).get();
      expect(expenses.first.category, 'Maintenance');
      expect(expenses.first.amount, 6000);

      await notifier.deleteExpense(expenses.first.id);
      expenses = await db.select(db.expenses).get();
      expect(expenses.isEmpty, isTrue);
    });
  });

  group('EmployeeNotifier', () {
    test('adds and deactivates an employee', () async {
      final container = createContainer();
      addTearDown(() => container.dispose());

      final notifier = container.read(employeeNotifierProvider.notifier);
      await notifier.addEmployee(name: 'Test User', role: 'Operator', salary: 30000);
      expect(container.read(employeeNotifierProvider).hasError, isFalse);

      final db = container.read(databaseProvider);
      var employees = await db.select(db.employees).get();
      expect(employees.length, 1);
      expect(employees.first.name, 'Test User');

      await notifier.deactivateEmployee(employees.first.id);
      employees = await db.select(db.employees).get();
      expect(employees.first.isActive, isFalse);
    });
  });
}
