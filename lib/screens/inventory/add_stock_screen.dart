import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_provider.dart';
import '../../providers/shift_provider.dart';
import '../../utils/constants.dart';
import '../../utils/responsive.dart';

class AddStockScreen extends ConsumerStatefulWidget {
  const AddStockScreen({super.key});

  @override
  ConsumerState<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends ConsumerState<AddStockScreen> {
  int? _selectedProductId;
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  double get _totalCost {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final cost = double.tryParse(_costController.text) ?? 0;
    return quantity * cost;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allProducts = ref.watch(allProductsProvider);
    final productState = ref.watch(productNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final body = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          allProducts.when(
            data: (products) => DropdownButtonFormField<int>(
              initialValue: _selectedProductId,
              decoration: const InputDecoration(labelText: 'Product'),
              items: products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))).toList(),
              onChanged: (value) {
                setState(() => _selectedProductId = value);
                if (value != null) {
                  final product = products.firstWhere((p) => p.id == value, orElse: () => products.first);
                  _costController.text = product.costPerUnit.toString();
                }
              },
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Error: $e'),
          ),
          const SizedBox(height: 16),
          TextField(controller: _quantityController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
          const SizedBox(height: 16),
          TextField(controller: _costController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Unit Cost (Rs.)')),
          if (_totalCost > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: colorScheme.primaryContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Cost', style: TextStyle(color: colorScheme.onPrimaryContainer)),
                  Text('$kCurrency ${_totalCost.toStringAsFixed(0)}', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(controller: _notesController, decoration: const InputDecoration(labelText: 'Notes (optional)')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _selectedProductId == null || productState.isLoading
                ? null
                : () async {
                    final quantity = double.tryParse(_quantityController.text) ?? 0;
                    if (quantity <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
                      return;
                    }
                    await ref.read(productNotifierProvider.notifier).addStock(
                          _selectedProductId!,
                          quantity,
                          double.tryParse(_costController.text) ?? 0,
                          _notesController.text.isNotEmpty ? _notesController.text : null,
                        );
                    ref.invalidate(allInventoryProvider);
                    ref.invalidate(todaySummaryProvider);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock added')));
                    }
                  },
            child: productState.isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Stock'),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Stock')),
      body: isWide(context)
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body))
          : body,
    );
  }
}
