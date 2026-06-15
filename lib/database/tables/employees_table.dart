import 'package:drift/drift.dart';

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text()(); // operator/manager/cleaner/etc
  TextColumn get defaultShift => text().withDefault(const Constant('both'))(); // morning/evening/both
  RealColumn get salary => real().withDefault(const Constant(0))();
  DateTimeColumn get joiningDate => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Payroll extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  RealColumn get baseSalary => real()();
  RealColumn get deductions => real().withDefault(const Constant(0))();
  RealColumn get advances => real().withDefault(const Constant(0))();
  RealColumn get bonuses => real().withDefault(const Constant(0))();
  RealColumn get netPay => real()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
