import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../database/daos/product_dao.dart';
import 'database_provider.dart';

final productDaoProvider = Provider<ProductDao>((ref) {
  return ref.watch(databaseProvider).productDao;
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productDaoProvider).watchAllProducts();
});

final allInventoryProvider = StreamProvider<List<InventoryRow>>((ref) {
  return ref.watch(productDaoProvider).watchAllInventory();
});

final lowStockProvider = FutureProvider<List<InventoryRow>>((ref) {
  return ref.watch(productDaoProvider).getLowStockProducts();
});

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductDao _dao;

  ProductNotifier(this._dao) : super(const AsyncValue.data(null));

  Future<void> updatePrice(int productId, double price, double cost) async {
    state = await AsyncValue.guard(() async {
      await _dao.updateProductPrice(productId, price, cost);
    });
  }

  Future<void> addStock(int productId, double quantity, double cost, String? notes) async {
    state = await AsyncValue.guard(() async {
      await _dao.addStock(productId, quantity, cost, notes);
    });
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(ref.watch(productDaoProvider));
});
