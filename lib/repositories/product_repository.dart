import '../database/app_database.dart';

class ProductRepository {
  final ProductDao _dao;

  ProductRepository(this._dao);

  Future<void> updatePrice(int productId, double price, double cost) async {
    await _dao.updateProductPrice(productId, price, cost);
  }

  Future<void> addStock(
    int productId,
    double quantity,
    double cost,
    String? notes,
  ) async {
    await _dao.addStock(productId, quantity, cost, notes);
  }

  Future<Product?> getProductById(int id) => _dao.getProductById(id);

  Future<List<InventoryRow>> getLowStock() => _dao.getLowStockProducts();

  Stream<List<Product>> watchAllProducts() => _dao.watchAllProducts();
  Stream<List<InventoryRow>> watchAllInventory() => _dao.watchAllInventory();
}
