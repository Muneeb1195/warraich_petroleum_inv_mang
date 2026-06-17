import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';
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
  daos: [ShiftDao, ProductDao, ExpenseDao, EmployeeDao, PayrollDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({QueryExecutor? executor}) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedProducts();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2 changed Products schema (added costPerUnit, pricePerUnit).
        // Delete+recreate is destructive but only runs for v1 upgraders.
        // Existing product/inventory data from v1 will be lost and re-seeded.
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
        // v5 had no schema changes (code-only)
      }
      if (from < 6) {
        await _addIndexesAndConstraints(m);
      }
      if (from < 7) {
        await _removeUnusedColumns(m);
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
      )).get().then((rows) => rows.any((r) => r.data['name'] == 'updated_at'));
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

  Future<void> _addIndexesAndConstraints(Migrator m) async {
    // Unique constraint: one inventory row per product
    await m.database.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_inventory_product_id ON inventory(product_id)',
    );
    // Unique constraint: one payroll record per employee per month/year
    await m.database.customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_payroll_employee_month_year ON payroll(employee_id, month, year)',
    );
    // Performance indexes for frequently queried columns
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shift_sales_shift_id ON shift_sales(shift_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shift_sales_product_id ON shift_sales(product_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shifts_start_date ON shifts(start_date)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shifts_status ON shifts(status)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_inventory_transactions_product_id ON inventory_transactions(product_id)',
    );
  }

  Future<void> _removeUnusedColumns(Migrator m) async {
    // Remove Expenses.createdBy — never populated in normal usage
    final expensesHasCreatedBy = await (m.database.customSelect(
      'PRAGMA table_info(expenses)',
    ))
        .get()
        .then(
          (rows) => rows.any((r) => r.data['name'] == 'created_by'),
        );
    if (expensesHasCreatedBy) {
      await m.database.customStatement(
        'ALTER TABLE expenses DROP COLUMN created_by',
      );
    }
    // Remove Shifts.closedBy — never populated in normal usage
    final shiftsHasClosedBy = await (m.database.customSelect(
      'PRAGMA table_info(shifts)',
    ))
        .get()
        .then(
          (rows) => rows.any((r) => r.data['name'] == 'closed_by'),
        );
    if (shiftsHasClosedBy) {
      await m.database.customStatement(
        'ALTER TABLE shifts DROP COLUMN closed_by',
      );
    }
  }

  Future<void> _seedProducts() async {
    // Seed with zero prices — user sets prices before first shift via Settings
    await transaction(() async {
      await into(products).insert(
        ProductsCompanion.insert(
          name: 'Petrol Hi-Octane',
          category: 'fuel',
          unit: 'liters',
          pricePerUnit: const Value(0),
          costPerUnit: const Value(0),
        ),
      );
      await into(products).insert(
        ProductsCompanion.insert(
          name: 'Petrol Regular',
          category: 'fuel',
          unit: 'liters',
          pricePerUnit: const Value(0),
          costPerUnit: const Value(0),
        ),
      );
      await into(products).insert(
        ProductsCompanion.insert(
          name: 'Diesel',
          category: 'fuel',
          unit: 'liters',
          pricePerUnit: const Value(0),
          costPerUnit: const Value(0),
        ),
      );
      await into(products).insert(
        ProductsCompanion.insert(
          name: 'Engine Oil 4L',
          category: 'lube',
          unit: 'pieces',
          pricePerUnit: const Value(0),
          costPerUnit: const Value(0),
        ),
      );
      await into(products).insert(
        ProductsCompanion.insert(
          name: 'Engine Oil 3L',
          category: 'lube',
          unit: 'pieces',
          pricePerUnit: const Value(0),
          costPerUnit: const Value(0),
        ),
      );
      await into(products).insert(
        ProductsCompanion.insert(
          name: 'Engine Oil (Liters)',
          category: 'lube',
          unit: 'liters',
          pricePerUnit: const Value(0),
          costPerUnit: const Value(0),
        ),
      );

      for (final product in await select(products).get()) {
        await into(inventory).insert(
          InventoryCompanion.insert(
            productId: product.id,
            currentStock: const Value(0),
            minStock: const Value(0),
          ),
        );
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, kDbFileName));
    return NativeDatabase.createInBackground(file);
  });
}
