import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/shift_provider.dart';
import '../../providers/product_provider.dart';
import '../../database/daos/shift_dao.dart';

class ShiftDetailScreen extends ConsumerStatefulWidget {
  final int shiftId;
  const ShiftDetailScreen({super.key, required this.shiftId});

  @override
  ConsumerState<ShiftDetailScreen> createState() => _ShiftDetailScreenState();
}

class _ShiftDetailScreenState extends ConsumerState<ShiftDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final shiftSales = ref.watch(shiftSalesProvider(widget.shiftId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Details'),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_entry',
                child: ListTile(
                  leading: Icon(Icons.local_gas_station),
                  title: Text('Add Entry'),
                ),
              ),
              const PopupMenuItem(
                value: 'close',
                child: ListTile(
                  leading: Icon(Icons.stop_circle),
                  title: Text('Close Shift'),
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'add_entry') {
                _showAddFuelDialog(context);
              } else if (value == 'close') {
                _confirmCloseShift(context);
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          shiftSales.when(
            data: (sales) {
              final totalSales = sales.fold<double>(0, (sum, row) => sum + row.sale.totalAmount);
              final totalCash = sales.fold<double>(0, (sum, row) => sum + row.sale.cashCollected);
              final totalCard = sales.fold<double>(0, (sum, row) => sum + row.sale.cardCollected);
              final totalCredit = sales.fold<double>(0, (sum, row) => sum + row.sale.creditCollected);

              return Column(
                children: [
                  _buildSummaryCard(context, colorScheme, totalSales, totalCash, totalCard, totalCredit),
                  const SizedBox(height: 16),
                  _buildSalesList(context, colorScheme, sales),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFuelDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ColorScheme colorScheme, double total, double cash, double card, double credit) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shift Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(label: 'Total Sales', value: 'Rs. ${total.toStringAsFixed(0)}', color: colorScheme.primary, icon: Icons.trending_up),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryTile(label: 'Cash', value: 'Rs. ${cash.toStringAsFixed(0)}', color: Colors.green, icon: Icons.money),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _SummaryTile(label: 'Card/Raast', value: 'Rs. ${card.toStringAsFixed(0)}', color: Colors.blue, icon: Icons.credit_card),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryTile(label: 'Credit', value: 'Rs. ${credit.toStringAsFixed(0)}', color: Colors.orange, icon: Icons.receipt_long),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(BuildContext context, ColorScheme colorScheme, List<ShiftSalesRow> sales) {
    if (sales.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.local_gas_station, size: 48, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('No entries yet', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text('Tap + to add a fuel or lube entry', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text('Entries (${sales.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ...sales.map((row) => _buildSaleTile(context, colorScheme, row)),
        ],
      ),
    );
  }

  Widget _buildSaleTile(BuildContext context, ColorScheme colorScheme, ShiftSalesRow row) {
    final sale = row.sale;
    final product = row.product;

    String paymentLabel = '';
    Color paymentColor = colorScheme.onSurface;
    if (sale.cashCollected > 0) {
      paymentLabel = 'Cash: ${sale.cashCollected.toStringAsFixed(0)}';
      paymentColor = Colors.green;
    } else if (sale.cardCollected > 0) {
      paymentLabel = 'Card/Raast: ${sale.cardCollected.toStringAsFixed(0)}';
      paymentColor = Colors.blue;
    } else if (sale.creditCollected > 0) {
      paymentLabel = 'Credit: ${sale.creditCollected.toStringAsFixed(0)}';
      paymentColor = Colors.orange;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: product.category == 'fuel' ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
        child: Icon(
          product.category == 'fuel' ? Icons.local_gas_station : Icons.oil_barrel,
          color: product.category == 'fuel' ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
          size: 20,
        ),
      ),
      title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            'Reading: ${sale.openingReading.toStringAsFixed(1)} → ${sale.closingReading.toStringAsFixed(1)} | ${sale.quantitySold.toStringAsFixed(1)} ${product.unit}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (paymentLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            _PaymentChip(label: paymentLabel, color: paymentColor),
          ],
        ],
      ),
      trailing: Text(
        'Rs. ${sale.totalAmount.toStringAsFixed(0)}',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
      ),
    );
  }

  void _showAddFuelDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddFuelSheet(shiftId: widget.shiftId),
    );
  }

  void _confirmCloseShift(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Shift?'),
        content: const Text('This action is irreversible. All sales records will be finalized and inventory will be deducted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(shiftNotifierProvider.notifier).closeShift(widget.shiftId, 1);
              if (context.mounted) {
                ref.invalidate(shiftSalesProvider(widget.shiftId));
                ref.invalidate(todaySummaryProvider);
                ref.invalidate(weeklySalesProvider);
                ref.invalidate(allInventoryProvider);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shift closed')));
              }
            },
            child: const Text('Close Shift'),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryTile({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color))]),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _PaymentChip extends StatelessWidget {
  final String label;
  final Color color;

  const _PaymentChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

class _AddFuelSheet extends ConsumerStatefulWidget {
  final int shiftId;

  const _AddFuelSheet({required this.shiftId});

  @override
  ConsumerState<_AddFuelSheet> createState() => _AddFuelSheetState();
}

class _AddFuelSheetState extends ConsumerState<_AddFuelSheet> {
  int? _selectedProductId;
  String _paymentMethod = 'cash';
  final _openingController = TextEditingController();
  final _closingController = TextEditingController();
  final _amountController = TextEditingController();

  List<dynamic> get _products => ref.watch(allProductsProvider).valueOrNull ?? [];

  double get _quantity {
    final opening = double.tryParse(_openingController.text) ?? 0;
    final closing = double.tryParse(_closingController.text) ?? 0;
    return closing - opening;
  }

  double get _pricePerUnit {
    if (_selectedProductId == null) return 0;
    final product = _products.firstWhere((p) => p.id == _selectedProductId);
    return product.pricePerUnit as double;
  }

  double get _totalAmount => _quantity * _pricePerUnit;

  void _updateAmount() {
    if (_totalAmount > 0) {
      _amountController.text = _totalAmount.toStringAsFixed(0);
    }
  }

  @override
  void initState() {
    super.initState();
    _openingController.addListener(() {
      setState(() {});
      _updateAmount();
    });
    _closingController.addListener(() {
      setState(() {});
      _updateAmount();
    });
  }

  @override
  void dispose() {
    _openingController.dispose();
    _closingController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Entry', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedProductId,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: _products.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem(value: p.id as int, child: Text(p.name as String));
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedProductId = value);
                      _updateAmount();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment'),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'card', child: Text('Card')),
                      DropdownMenuItem(value: 'raast', child: Text('Raast')),
                      DropdownMenuItem(value: 'credit', child: Text('Credit')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _paymentMethod = value);
                    },
                  ),
                ),
              ],
            ),
            if (_selectedProductId != null) ...[
              const SizedBox(height: 8),
              Text('Price: Rs. ${_pricePerUnit.toStringAsFixed(1)} / unit', style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextField(controller: _openingController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Reading'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _closingController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Closing Reading'))),
              ],
            ),
            if (_quantity != 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _quantity > 0 ? colorScheme.primaryContainer.withValues(alpha: 0.5) : colorScheme.errorContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Qty: ${_quantity.toStringAsFixed(1)} units', style: TextStyle(color: _quantity > 0 ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer)),
                    Text(
                      'Total: Rs. ${_totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: _quantity > 0 ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (Rs.)', prefixIcon: Icon(Icons.attach_money)),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _selectedProductId == null || _quantity <= 0
                  ? null
                  : () async {
                      final amount = double.tryParse(_amountController.text) ?? _totalAmount;
                      final cash = _paymentMethod == 'cash' ? amount : 0.0;
                      final card = (_paymentMethod == 'card' || _paymentMethod == 'raast') ? amount : 0.0;
                      final credit = _paymentMethod == 'credit' ? amount : 0.0;
                      await ref.read(shiftNotifierProvider.notifier).addSaleToShift(
                            widget.shiftId,
                            _selectedProductId!,
                            double.tryParse(_openingController.text) ?? 0,
                            double.tryParse(_closingController.text) ?? 0,
                            _pricePerUnit,
                            cash,
                            card,
                            credit,
                          );
                      ref.invalidate(shiftSalesProvider(widget.shiftId));
                      if (context.mounted) Navigator.pop(context);
                    },
              child: const Text('Add Entry'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
