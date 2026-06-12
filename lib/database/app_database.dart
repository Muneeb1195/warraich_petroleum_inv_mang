import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/tables.dart';
import 'daos/daos.dart';

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
    Attendance,
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
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedProducts();
        },
      );

  Future<void> _seedProducts() async {
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
      name: 'Engine Oil',
      category: 'lube',
      unit: 'pieces',
      pricePerUnit: const Value(0),
      costPerUnit: const Value(0),
    ));
    await into(products).insert(ProductsCompanion.insert(
      name: 'Gear Oil',
      category: 'lube',
      unit: 'pieces',
      pricePerUnit: const Value(0),
      costPerUnit: const Value(0),
    ));
    await into(products).insert(ProductsCompanion.insert(
      name: 'Brake Fluid',
      category: 'lube',
      unit: 'pieces',
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
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'warraich_petroleum.db'));
    return NativeDatabase.createInBackground(file);
  });
}
