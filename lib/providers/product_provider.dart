import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../database/app_database.dart';
import '../repositories/product_repository.dart';
import '../services/sync_service.dart';
import 'database_provider.dart';
import 'sync_provider.dart';

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
  final SyncService? _sync;

  ProductNotifier(this._repo, this._sync) : super(const AsyncValue.data(null));

  Future<void> updatePrice(int productId, double price, double cost) async {
    state = await AsyncValue.guard(() => _repo.updatePrice(productId, price, cost));
    if (_sync != null) {
      final product = await _repo.getProductById(productId);
      if (product != null) {
        await _sync.syncRecord('products', productId.toString(), {
          'id': product.id,
          'name': product.name,
          'category': product.category,
          'unit': product.unit,
          'pricePerUnit': product.pricePerUnit,
          'costPerUnit': product.costPerUnit,
          'isActive': product.isActive,
          'updatedAt': product.updatedAt.toIso8601String(),
        });
      }
    }
  }

  Future<void> addStock(int productId, double quantity, double cost, String? notes) async {
    state = await AsyncValue.guard(() => _repo.addStock(productId, quantity, cost, notes));
    if (_sync != null) {
      final product = await _repo.getProductById(productId);
      if (product != null) {
        await _sync.syncRecord('products', productId.toString(), {
          'id': product.id,
          'name': product.name,
          'category': product.category,
          'unit': product.unit,
          'pricePerUnit': product.pricePerUnit,
          'costPerUnit': product.costPerUnit,
          'isActive': product.isActive,
          'updatedAt': product.updatedAt.toIso8601String(),
        });
      }
    }
  }
}

final productNotifierProvider = StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(
    ref.watch(productRepositoryProvider),
    ref.read(syncServiceProvider),
  );
});
