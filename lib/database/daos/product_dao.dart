import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/tables.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, Inventory, InventoryTransactions, Expenses])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Future<List<Product>> getAllProducts() async {
    return (select(products)..where((p) => p.isActive.equals(true))).get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)..where((p) => p.isActive.equals(true))).watch();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    return (select(products)
          ..where((p) => p.category.equals(category) & p.isActive.equals(true)))
        .get();
  }

  Future<Product?> getProductById(int id) async {
    return (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> addProduct(ProductsCompanion data) => into(products).insert(data);

  Future<int> updateProduct(int id, ProductsCompanion data) async {
    return (update(products)..where((p) => p.id.equals(id))).write(data);
  }

  Future<int> updateProductPrice(int productId, double price, double cost) async {
    return (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(
        pricePerUnit: Value(price),
        costPerUnit: Value(cost),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<InventoryData?> getInventory(int productId) async {
    return (select(inventory)
          ..where((i) => i.productId.equals(productId)))
        .getSingleOrNull();
  }

  Stream<InventoryData?> watchInventory(int productId) {
    return (select(inventory)
          ..where((i) => i.productId.equals(productId)))
        .watchSingleOrNull();
  }

  Future<List<InventoryRow>> getAllInventory() async {
    final query = select(inventory).join([
      innerJoin(products, products.id.equalsExp(inventory.productId)),
    ]);
    final results = await query.get();
    return results.map((row) {
      return InventoryRow(
        inventoryEntry: row.readTable(inventory),
        product: row.readTable(products),
      );
    }).toList();
  }

  Stream<List<InventoryRow>> watchAllInventory() {
    final query = select(inventory).join([
      innerJoin(products, products.id.equalsExp(inventory.productId)),
    ]);
    return query.watch().map((rows) {
      return rows.map((row) {
        return InventoryRow(
          inventoryEntry: row.readTable(inventory),
          product: row.readTable(products),
        );
      }).toList();
    });
  }

  Future<void> addStock(int productId, double quantity, double unitCost, String? notes) async {
    await transaction(() async {
      final product = await (select(products)..where((p) => p.id.equals(productId))).getSingleOrNull();

      await into(inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        productId: productId,
        type: 'purchase',
        quantity: quantity,
        unitCost: Value(unitCost),
        notes: Value(notes),
      ));

      final current = await getInventory(productId);
      if (current != null) {
        await (update(inventory)..where((i) => i.id.equals(current.id))).write(
          InventoryCompanion(
            currentStock: Value(current.currentStock + quantity),
            lastUpdated: Value(DateTime.now()),
          ),
        );
      }

      final totalCost = quantity * unitCost;
      if (totalCost > 0) {
        final description = StringBuffer('Stock: ${product?.name ?? "Unknown"}');
        if (notes != null && notes.isNotEmpty) description.write(' - $notes');
        await into(expenses).insert(ExpensesCompanion.insert(
          category: 'Supplier',
          amount: totalCost,
          date: DateTime.now(),
          description: Value(description.toString()),
        ));
      }
    });
  }

  Future<void> deductStock(int productId, double quantity, int? shiftId) async {
    await transaction(() async {
      final current = await getInventory(productId);
      if (current == null) return;

        if (current.currentStock < quantity) {
          throw Exception('Insufficient stock for $productId');
        }

      await into(inventoryTransactions).insert(InventoryTransactionsCompanion.insert(
        productId: productId,
        type: 'sale',
        quantity: -quantity,
        referenceId: Value(shiftId),
      ));

      await (update(inventory)..where((i) => i.id.equals(current.id))).write(
        InventoryCompanion(
          currentStock: Value(current.currentStock - quantity),
          lastUpdated: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<List<InventoryTransaction>> getTransactions(int productId) async {
    return (select(inventoryTransactions)
          ..where((t) => t.productId.equals(productId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<List<InventoryRow>> getLowStockProducts() async {
    final query = select(inventory).join([
      innerJoin(products, products.id.equalsExp(inventory.productId)),
    ])
      ..where(inventory.currentStock.isSmallerThan(inventory.minStock));
    final results = await query.get();
    return results.map((row) {
      return InventoryRow(
        inventoryEntry: row.readTable(inventory),
        product: row.readTable(products),
      );
    }).toList();
  }
}

class InventoryRow {
  final InventoryData inventoryEntry;
  final Product product;
  InventoryRow({required this.inventoryEntry, required this.product});
}
