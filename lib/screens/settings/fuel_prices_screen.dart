import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';

class FuelPricesScreen extends ConsumerStatefulWidget {
  const FuelPricesScreen({super.key});

  @override
  ConsumerState<FuelPricesScreen> createState() => _FuelPricesScreenState();
}

class _FuelPricesScreenState extends ConsumerState<FuelPricesScreen> {
  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(allProductsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Fuel & Product Prices')),
      body: allProducts.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products found'));
          }

          if (_isDesktop) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildPriceCard(context, products[index], colorScheme);
                  },
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return _buildPriceCard(context, products[index], colorScheme);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPriceCard(BuildContext context, dynamic product, ColorScheme colorScheme) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: product.category == 'fuel'
              ? colorScheme.primaryContainer
              : colorScheme.tertiaryContainer,
          child: Icon(
            product.category == 'fuel' ? Icons.local_gas_station : Icons.oil_barrel,
            color: product.category == 'fuel'
                ? colorScheme.onPrimaryContainer
                : colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(product.name),
        subtitle: Text(
          'Cost: Rs. ${product.costPerUnit.toStringAsFixed(1)} | Selling: Rs. ${product.pricePerUnit.toStringAsFixed(1)}',
        ),
        trailing: const Icon(Icons.edit),
        onTap: () => _showEditPriceDialog(context, product),
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, dynamic product) {
    final sellingController = TextEditingController(
      text: product.pricePerUnit.toString(),
    );
    final costController = TextEditingController(
      text: product.costPerUnit.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${product.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cost Price (Rs.)',
                  prefixIcon: Icon(Icons.shopping_cart),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sellingController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Selling Price (Rs.)',
                  prefixIcon: Icon(Icons.sell),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final selling = double.tryParse(sellingController.text) ?? 0;
              final cost = double.tryParse(costController.text) ?? 0;
              await ref.read(productNotifierProvider.notifier).updatePrice(
                    product.id,
                    selling,
                    cost,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} prices updated')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
