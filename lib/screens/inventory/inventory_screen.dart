import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../providers/product_provider.dart';
import '../../providers/database_provider.dart';
import '../../database/app_database.dart';
import '../../utils/responsive.dart';
import 'add_stock_screen.dart';
import '../../utils/error_utils.dart';

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
      body: RefreshIndicator(
        onRefresh: () async { ref.invalidate(allInventoryProvider); },
        child: _buildBody(context, ref, allInventory, colorScheme),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, AsyncValue allInventory, ColorScheme colorScheme) {
    final content = allInventory.when(
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
            if (isWide(context))
              GridView.count(
                crossAxisCount: fuelItems.isEmpty ? 1 : (fuelItems.length <= 3 ? fuelItems.length : 2),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: fuelItems.map((item) => _buildInventoryCard(context, ref, item, colorScheme)).toList().cast<Widget>(),
              )
            else
              ...fuelItems.map((item) => _buildInventoryCard(context, ref, item, colorScheme)),
            const SizedBox(height: 16),
            Text(
              'Lube Products',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (isWide(context))
              GridView.count(
                crossAxisCount: lubeItems.isEmpty ? 1 : (lubeItems.length <= 3 ? lubeItems.length : 2),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.8,
                children: lubeItems.map((item) => _buildInventoryCard(context, ref, item, colorScheme)).toList().cast<Widget>(),
              )
            else
              ...lubeItems.map((item) => _buildInventoryCard(context, ref, item, colorScheme)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );

    if (isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: content,
        ),
      );
    }
    return content;
  }

  Widget _buildInventoryCard(BuildContext context, WidgetRef ref, dynamic item, ColorScheme colorScheme) {
    final stock = item.inventoryEntry.currentStock;
    final minStock = item.inventoryEntry.minStock;
    final maxStock = item.inventoryEntry.maxStock;
    final isLow = minStock > 0 && stock <= minStock;

    final Color levelColor;
    if (isLow) {
      levelColor = colorScheme.error;
    } else if (maxStock > 0 && stock > maxStock * 0.9) {
      levelColor = Colors.orange;
    } else {
      levelColor = Colors.green;
    }

    final double fillRatio;
    if (maxStock > 0) {
      fillRatio = (stock / maxStock).clamp(0.0, 1.0);
    } else if (minStock > 0) {
      fillRatio = (stock / (minStock * 3)).clamp(0.0, 1.0);
    } else {
      fillRatio = stock > 0 ? 1.0 : 0.0;
    }

    final bool hasLimits = maxStock > 0 || minStock > 0;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStockDialog(context, ref, item),
        onLongPress: () => _showTransactionHistory(context, ref, item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isLow ? colorScheme.errorContainer : colorScheme.primaryContainer,
                    child: Icon(
                      isLow ? Icons.warning_amber : Icons.check_circle,
                      color: isLow ? colorScheme.onErrorContainer : colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.product.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          hasLimits
                              ? 'Min: ${minStock.toStringAsFixed(0)} | Max: ${maxStock.toStringAsFixed(0)} ${item.product.unit}'
                              : 'Tap to set stock levels',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasLimits ? colorScheme.onSurfaceVariant : colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        stock.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isLow ? colorScheme.error : colorScheme.onSurface,
                        ),
                      ),
                      Text(item.product.unit, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fillRatio,
                  minHeight: 8,
                  backgroundColor: levelColor.withValues(alpha: 0.15),
                  color: levelColor,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isLow ? 'Low stock' : maxStock > 0 && stock > maxStock * 0.9 ? 'Near full' : 'Good',
                    style: TextStyle(fontSize: 11, color: levelColor, fontWeight: FontWeight.w600),
                  ),
                  if (maxStock > 0)
                    Text(
                      '${(fillRatio * 100).toInt()}% full',
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionHistory(BuildContext context, WidgetRef ref, dynamic item) {
    final database = ref.read(databaseProvider);
    final transactionsFuture = database.productDao.getTransactions(item.product.id);

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
            future: transactionsFuture,
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

  void _showStockDialog(BuildContext context, WidgetRef ref, dynamic item) {
    final minController = TextEditingController(
      text: item.inventoryEntry.minStock > 0 ? item.inventoryEntry.minStock.toString() : '',
    );
    final maxController = TextEditingController(
      text: item.inventoryEntry.maxStock > 0 ? item.inventoryEntry.maxStock.toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Stock Levels: ${item.product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Minimum Stock',
                suffixText: item.product.unit,
                helperText: 'Low stock warning threshold',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Maximum Stock (Tank Capacity)',
                suffixText: item.product.unit,
                helperText: 'Tank full capacity for visual indicator',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final minStock = double.tryParse(minController.text) ?? 0;
              final maxStock = double.tryParse(maxController.text) ?? 0;
              final database = ref.read(databaseProvider);
              try {
                await (database.update(database.inventory)
                      ..where((i) => i.id.equals(item.inventoryEntry.id)))
                    .write(InventoryCompanion(
                      minStock: Value(minStock),
                      maxStock: Value(maxStock),
                    ));
                ref.invalidate(allInventoryProvider);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) context.showError(e, source: 'updateMinStock');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ).then((_) { minController.dispose(); maxController.dispose(); });
  }
}
