import 'package:drift/drift.dart';
import 'shifts_table.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get shiftId => integer().nullable().references(Shifts, #id)();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
