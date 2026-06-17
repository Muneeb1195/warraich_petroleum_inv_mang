import 'package:drift/drift.dart';
import 'products_table.dart';

class Inventory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get currentStock => real().withDefault(const Constant(0))();
  RealColumn get minStock => real().withDefault(const Constant(0))();
  RealColumn get maxStock => real().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdated =>
      dateTime().withDefault(currentDateAndTime)();
}

class InventoryTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get type => text()(); // purchase / sale / adjustment
  RealColumn get quantity => real()();
  RealColumn get unitCost => real().withDefault(const Constant(0))();
  IntColumn get referenceId => integer().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
