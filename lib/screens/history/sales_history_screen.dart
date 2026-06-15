
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/shift_provider.dart';
import '../../utils/extensions.dart';
import '../../utils/constants.dart';
import '../shifts/shift_detail_screen.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _filterType = 'all';
  bool _isWide(BuildContext context) => MediaQuery.sizeOf(context).width > 800;

  @override
  Widget build(BuildContext context) {
    final allShifts = ref.watch(allShiftsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final body = allShifts.when(
      data: (shifts) {
        var filtered = shifts;
        if (_filterType == 'morning') {
          filtered = shifts.where((s) => s.type == 'morning').toList();
        } else if (_filterType == 'evening') {
          filtered = shifts.where((s) => s.type == 'evening').toList();
        } else if (_filterType == 'closed') {
          filtered = shifts.where((s) => s.status == 'closed').toList();
        }

        if (filtered.isEmpty) {
          return const Center(child: Text('No sales history'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final shift = filtered[index];
            final isActive = shift.status == 'active';
            final profit = shift.totalSales - shift.totalExpenses;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive ? colorScheme.surfaceContainerHighest : colorScheme.primaryContainer,
                  child: Icon(isActive ? Icons.schedule : Icons.check_circle, color: isActive ? colorScheme.onSurfaceVariant : colorScheme.onPrimaryContainer),
                ),
                title: Text('${shift.type.toUpperCase()} - ${shift.startDate.formattedDate}'),
                subtitle: Text('Sales: $kCurrency ${shift.totalSales.toStringAsFixed(0)} | Exp: $kCurrency ${shift.totalExpenses.toStringAsFixed(0)}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$kCurrency ${profit.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: profit >= 0 ? Colors.green : colorScheme.error)),
                    if (isActive) Text('Active', style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftDetailScreen(shiftId: shift.id))),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterType = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Shifts')),
              const PopupMenuItem(value: 'morning', child: Text('Morning Only')),
              const PopupMenuItem(value: 'evening', child: Text('Evening Only')),
              const PopupMenuItem(value: 'closed', child: Text('Closed Only')),
            ],
          ),
        ],
      ),
      body: _isWide(context)
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body))
          : body,
    );
  }
}
