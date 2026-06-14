// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payroll_dao.dart';

// ignore_for_file: type=lint
mixin _$PayrollDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $PayrollTable get payroll => attachedDatabase.payroll;
  PayrollDaoManager get managers => PayrollDaoManager(this);
}

class PayrollDaoManager {
  final _$PayrollDaoMixin _db;
  PayrollDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$PayrollTableTableManager get payroll =>
      $$PayrollTableTableManager(_db.attachedDatabase, _db.payroll);
}
