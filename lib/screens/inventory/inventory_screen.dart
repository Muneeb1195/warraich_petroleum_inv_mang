import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/product_provider.dart';
import '../../providers/database_provider.dart';
import '../../database/app_database.dart';
import 'add_stock_screen.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allInventory = ref.watch(allInventoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStockScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Stock'),
      ),
      body: allInventory.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No inventory data'));
          }
          final fuelItems = items.where((i) => i.product.category == 'fuel').toList();
          final lubeItems = items.where((i) => i.product.category == 'lube').toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Fuel Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...fuelItems.map((item) => _buildInventoryCard(context, ref, item, colorScheme)),
              const SizedBox(height: 16),
              Text(
                'Lube Products',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...lubeItems.map((item) => _buildInventoryCard(context, ref, item, colorScheme)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context, WidgetRef ref, dynamic item, ColorScheme colorScheme) {
    final stock = item.inventoryEntry.currentStock;
    final minStock = item.inventoryEntry.minStock;
    final isLow = minStock > 0 && stock <= minStock;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLow ? colorScheme.errorContainer : colorScheme.primaryContainer,
          child: Icon(
            isLow ? Icons.warning_amber : Icons.check_circle,
            color: isLow ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(item.product.name),
        subtitle: Text(
          minStock > 0
              ? 'Min: ${minStock.toStringAsFixed(1)} ${item.product.unit}'
              : 'Tap to set min stock',
          style: TextStyle(color: minStock > 0 ? colorScheme.onSurfaceVariant : colorScheme.primary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${stock.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isLow ? colorScheme.error : colorScheme.onSurface,
              ),
            ),
            Text(item.product.unit, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () => _showMinStockDialog(context, ref, item),
        onLongPress: () => _showTransactionHistory(context, ref, item),
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, WidgetRef ref, dynamic item) {
    final database = ref.read(databaseProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return FutureBuilder(
            future: database.productDao.getTransactions(item.product.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final transactions = snapshot.data ?? [];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${item.product.name} - History',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: transactions.isEmpty
                        ? const Center(child: Text('No transactions yet'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final t = transactions[index];
                              final isPurchase = t.type == 'purchase';
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isPurchase
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  child: Icon(
                                    isPurchase ? Icons.add_circle : Icons.remove_circle,
                                    color: isPurchase ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                ),
                                title: Text(isPurchase ? 'Purchase' : 'Sale'),
                                subtitle: Text(
                                  '${t.quantity.abs().toStringAsFixed(1)} ${item.product.unit}${t.notes != null ? ' - ${t.notes}' : ''}',
                                ),
                                trailing: Text(
                                  t.createdAt.toString().substring(0, 16),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showMinStockDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final controller = TextEditingController(
      text: item.inventoryEntry.minStock > 0 ? item.inventoryEntry.minStock.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Min Stock: ${item.product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Minimum Stock Level',
            suffixText: item.product.unit,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final minStock = double.tryParse(controller.text) ?? 0;
              final database = ref.read(databaseProvider);
              await (database.update(database.inventory)
                    ..where((i) => i.id.equals(item.inventoryEntry.id)))
                  .write(InventoryCompanion(
                    minStock: Value(minStock),
                  ));
              ref.invalidate(allInventoryProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
