import 'package:drift/drift.dart';
import 'shifts_table.dart';
import 'employees_table.dart';

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()(); // electricity/wages/maintenance/transport/utilities/supplier/misc
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get date => dateTime()();
  IntColumn get shiftId => integer().nullable().references(Shifts, #id)();
  IntColumn get createdBy => integer().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
