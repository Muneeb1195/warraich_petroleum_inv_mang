// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_dao.dart';

// ignore_for_file: type=lint
mixin _$ShiftDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $ShiftsTable get shifts => attachedDatabase.shifts;
  $ProductsTable get products => attachedDatabase.products;
  $ShiftSalesTable get shiftSales => attachedDatabase.shiftSales;
  $InventoryTable get inventory => attachedDatabase.inventory;
  $InventoryTransactionsTable get inventoryTransactions =>
      attachedDatabase.inventoryTransactions;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  ShiftDaoManager get managers => ShiftDaoManager(this);
}

class ShiftDaoManager {
  final _$ShiftDaoMixin _db;
  ShiftDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$ShiftsTableTableManager get shifts =>
      $$ShiftsTableTableManager(_db.attachedDatabase, _db.shifts);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$ShiftSalesTableTableManager get shiftSales =>
      $$ShiftSalesTableTableManager(_db.attachedDatabase, _db.shiftSales);
  $$InventoryTableTableManager get inventory =>
      $$InventoryTableTableManager(_db.attachedDatabase, _db.inventory);
  $$InventoryTransactionsTableTableManager get inventoryTransactions =>
      $$InventoryTransactionsTableTableManager(
        _db.attachedDatabase,
        _db.inventoryTransactions,
      );
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
}
