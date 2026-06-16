import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:warraich_petroleum/database/app_database.dart';
import 'package:warraich_petroleum/services/merge_service.dart';

void main() {
  group('MergeService', () {
    test('merges new products from backup into current database', () async {
      final current = AppDatabase(executor: NativeDatabase.memory());
      final backup = AppDatabase(executor: NativeDatabase.memory());
      // Both have 6 seeded products. Add a unique product to backup only.
      await backup.into(backup.products).insert(ProductsCompanion.insert(
        name: 'Super Diesel',
        category: 'fuel',
        unit: 'liters',
        pricePerUnit: const Value(300),
      ));

      await MergeService.mergeDatabases(current, backup);

      final products = await current.select(current.products).get();
      // 6 seeded + 1 new = 7
      expect(products.length, 7);
      final superDiesel = products.firstWhere((p) => p.name == 'Super Diesel');
      expect(superDiesel.pricePerUnit, 300);

      await current.close();
      await backup.close();
    });

    test('updates products when backup has newer updatedAt', () async {
      final current = AppDatabase(executor: NativeDatabase.memory());
      final backup = AppDatabase(executor: NativeDatabase.memory());

      // Update a seeded product in backup with a later timestamp
      final seeded = (await backup.select(backup.products).get())
          .firstWhere((p) => p.name == 'Petrol Regular');
      await backup.update(backup.products).replace(seeded.copyWith(
        pricePerUnit: 250,
        updatedAt: DateTime(2099),
      ));

      await MergeService.mergeDatabases(current, backup);

      final products = await current.select(current.products).get();
      final petrol = products.firstWhere((p) => p.name == 'Petrol Regular');
      expect(petrol.pricePerUnit, 250);

      await current.close();
      await backup.close();
    });

    test('remaps foreign keys when merging shifts and sales', () async {
      final current = AppDatabase(executor: NativeDatabase.memory());
      final backup = AppDatabase(executor: NativeDatabase.memory());

      // Current DB: Employee "Ali"
      await current.into(current.employees).insert(
        EmployeesCompanion.insert(name: 'Ali', role: 'Operator'),
      );

      // Backup DB: Employee "Ali" (same) + "Ahmed" (new)
      await backup.into(backup.employees).insert(
        EmployeesCompanion.insert(name: 'Ali', role: 'Operator'),
      );
      final ahmedBackupId = await backup.into(backup.employees).insert(
        EmployeesCompanion.insert(name: 'Ahmed', role: 'Manager'),
      );

      // Backup DB: Shift closedBy=ahmedBackupId
      final shiftBackupId = await backup.into(backup.shifts).insert(
        ShiftsCompanion.insert(type: 'morning', startDate: DateTime(2024, 1, 1)),
      );
      await (backup.update(backup.shifts)
            ..where((s) => s.id.equals(shiftBackupId)))
          .write(ShiftsCompanion(closedBy: Value(ahmedBackupId)));

      await MergeService.mergeDatabases(current, backup);

      // Ahmed should now exist in current DB with a new id
      final employees = await current.select(current.employees).get();
      expect(employees.length, 2);
      final ahmed = employees.firstWhere((e) => e.name == 'Ahmed');
      expect(ahmed.role, 'Manager');

      // Shift should reference Ahmed's new id
      final shifts = await current.select(current.shifts).get();
      expect(shifts.length, 1);
      expect(shifts.first.closedBy, ahmed.id);

      await current.close();
      await backup.close();
    });

    test('does not duplicate records with matching natural keys', () async {
      final current = AppDatabase(executor: NativeDatabase.memory());
      final backup = AppDatabase(executor: NativeDatabase.memory());

      // Both have same employee (seeded + explicit)
      await current.into(current.employees).insert(
        EmployeesCompanion.insert(name: 'TestEmp', role: 'Operator'),
      );
      await backup.into(backup.employees).insert(
        EmployeesCompanion.insert(name: 'TestEmp', role: 'Operator'),
      );

      await MergeService.mergeDatabases(current, backup);

      final employees = await current.select(current.employees).get();
      final testEmps = employees.where((e) => e.name == 'TestEmp').toList();
      expect(testEmps.length, 1);

      await current.close();
      await backup.close();
    });

    test('merges expenses without duplicating', () async {
      final current = AppDatabase(executor: NativeDatabase.memory());
      final backup = AppDatabase(executor: NativeDatabase.memory());

      final date = DateTime(2024, 6, 15);

      // Both have same expense
      await current.into(current.expenses).insert(ExpensesCompanion.insert(
        category: 'Electricity',
        amount: 5000,
        date: date,
      ));
      await backup.into(backup.expenses).insert(ExpensesCompanion.insert(
        category: 'Electricity',
        amount: 5000,
        date: date,
      ));

      // Backup has different expense
      await backup.into(backup.expenses).insert(ExpensesCompanion.insert(
        category: 'Maintenance',
        amount: 2000,
        date: date,
      ));

      await MergeService.mergeDatabases(current, backup);

      final expenses = await current.select(current.expenses).get();
      expect(expenses.length, 2);

      await current.close();
      await backup.close();
    });
  });
}
