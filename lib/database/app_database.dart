import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tables.dart';
import 'daos/daos.dart';
export 'daos/daos.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Products,
    Inventory,
    InventoryTransactions,
    Shifts,
    ShiftSales,
    Expenses,
    Employees,
    Payroll,
    AppSettings,
  ],
  daos: [
    ShiftDao,
    ProductDao,
    ExpenseDao,
    EmployeeDao,
    PayrollDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedProducts();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.deleteTable('products');
            await m.deleteTable('inventory');
            await m.createTable(products);
            await m.createTable(inventory);
            await _seedProducts();
          }
          if (from < 3) {
            await m.addColumn(inventory, inventory.maxStock);
          }
          if (from < 4) {
            await _ensureUpdatedAtColumns(m);
          }
          if (from < 5) {
            await _ensureUpdatedAtColumns(m);
          }
        },
      );

  Future<void> _ensureUpdatedAtColumns(Migrator m) async {
    for (final col in [
      (shifts as TableInfo, shifts.updatedAt),
      (shiftSales as TableInfo, shiftSales.updatedAt),
      (expenses as TableInfo, expenses.updatedAt),
      (products as TableInfo, products.updatedAt),
      (employees as TableInfo, employees.updatedAt),
      (payroll as TableInfo, payroll.updatedAt),
    ]) {
      final name = col.$1.actualTableName;
      final has = await (m.database.customSelect(
        'PRAGMA table_info($name)',
      )).get().then((rows) =>
          rows.any((r) => r.data['name'] == 'updated_at'));
      if (!has) {
        // Use raw SQL with constant default — SQLite rejects
        // non-constant defaults (like CAST(strftime(...))) in
        // ALTER TABLE ADD COLUMN.
        await m.database.customStatement(
          'ALTER TABLE $name ADD COLUMN updated_at INTEGER NOT NULL DEFAULT 0',
        );
      }
    }
  }

  Future<void> _seedProducts() async {
    await transaction(() async {
      await into(products).insert(ProductsCompanion.insert(
        name: 'Petrol Hi-Octane',
        category: 'fuel',
        unit: 'liters',
        pricePerUnit: const Value(0),
        costPerUnit: const Value(0),
      ));
      await into(products).insert(ProductsCompanion.insert(
        name: 'Petrol Regular',
        category: 'fuel',
        unit: 'liters',
        pricePerUnit: const Value(0),
        costPerUnit: const Value(0),
      ));
      await into(products).insert(ProductsCompanion.insert(
        name: 'Diesel',
        category: 'fuel',
        unit: 'liters',
        pricePerUnit: const Value(0),
        costPerUnit: const Value(0),
      ));
      await into(products).insert(ProductsCompanion.insert(
        name: 'Engine Oil 4L',
        category: 'lube',
        unit: 'pieces',
        pricePerUnit: const Value(0),
        costPerUnit: const Value(0),
      ));
      await into(products).insert(ProductsCompanion.insert(
        name: 'Engine Oil 3L',
        category: 'lube',
        unit: 'pieces',
        pricePerUnit: const Value(0),
        costPerUnit: const Value(0),
      ));
      await into(products).insert(ProductsCompanion.insert(
        name: 'Engine Oil (Liters)',
        category: 'lube',
        unit: 'liters',
        pricePerUnit: const Value(0),
        costPerUnit: const Value(0),
      ));

      for (final product in await select(products).get()) {
        await into(inventory).insert(InventoryCompanion.insert(
          productId: product.id,
          currentStock: const Value(0),
          minStock: const Value(0),
        ));
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'warraich_petroleum.db'));
    return NativeDatabase.createInBackground(file);
  });
}
