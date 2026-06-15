import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/product_repository.dart';
import 'database_provider.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(databaseProvider).productDao);
});

final allProductsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllProducts();
});

final allInventoryProvider = StreamProvider<List<InventoryRow>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllInventory();
});

final lowStockProvider = FutureProvider<List<InventoryRow>>((ref) {
  return ref.watch(productRepositoryProvider).getLowStock();
});

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final ProductRepository _repo;

  ProductNotifier(this._repo) : super(const AsyncValue.data(null));

  Future<void> updatePrice(int productId, double price, double cost) async {
    state = await AsyncValue.guard(() => _repo.updatePrice(productId, price, cost));
  }

  Future<void> addStock(int productId, double quantity, double cost, String? notes) async {
    state = await AsyncValue.guard(() => _repo.addStock(productId, quantity, cost, notes));
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(
    ref.watch(productRepositoryProvider),
  );
});
