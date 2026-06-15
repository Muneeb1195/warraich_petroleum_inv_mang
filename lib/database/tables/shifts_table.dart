import 'package:drift/drift.dart';
import 'products_table.dart';
import 'employees_table.dart';

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // morning / evening
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))(); // active / closed
  RealColumn get totalSales => real().withDefault(const Constant(0))();
  RealColumn get totalExpenses => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  IntColumn get closedBy => integer().nullable().references(Employees, #id)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class ShiftSales extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shiftId => integer().references(Shifts, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get openingReading => real().withDefault(const Constant(0))();
  RealColumn get closingReading => real().withDefault(const Constant(0))();
  RealColumn get quantitySold => real().withDefault(const Constant(0))();
  RealColumn get totalAmount => real().withDefault(const Constant(0))();
  RealColumn get cashCollected => real().withDefault(const Constant(0))();
  RealColumn get cardCollected => real().withDefault(const Constant(0))();
  RealColumn get creditCollected => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
