import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/shift_provider.dart';
import '../../utils/extensions.dart';
import '../../utils/constants.dart';
import '../../utils/responsive.dart';
import '../shifts/shift_detail_screen.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  String _filterType = 'all';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Shift> _applyFilters(List<Shift> shifts) {
    var filtered = shifts;

    if (_filterType == 'morning') {
      filtered = filtered.where((s) => s.type == 'morning').toList();
    } else if (_filterType == 'evening') {
      filtered = filtered.where((s) => s.type == 'evening').toList();
    } else if (_filterType == 'closed') {
      filtered = filtered.where((s) => s.status == 'closed').toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered
          .where(
            (s) =>
                s.type.toLowerCase().contains(q) ||
                (s.notes?.toLowerCase().contains(q) ?? false) ||
                s.startDate.formattedDate.toLowerCase().contains(q) ||
                s.status.toLowerCase().contains(q),
          )
          .toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where((s) => !s.startDate.isBefore(_startDate!.startOfDay))
          .toList();
    }
    if (_endDate != null) {
      filtered = filtered
          .where((s) => !s.startDate.isAfter(_endDate!.endOfDay))
          .toList();
    }

    return filtered;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : DateTimeRange(
              start: now.subtract(const Duration(days: 30)),
              end: now,
            ),
    );
    if (range != null && mounted) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allShifts = ref.watch(allShiftsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final body = allShifts.when(
      data: (shifts) {
        final filtered = _applyFilters(shifts);
        if (filtered.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isNotEmpty || _startDate != null
                  ? 'No shifts match your search'
                  : 'No sales history',
            ),
          );
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
                  backgroundColor: isActive
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primaryContainer,
                  child: Icon(
                    isActive ? Icons.schedule : Icons.check_circle,
                    color: isActive
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  '${shift.type.toUpperCase()} - ${shift.startDate.formattedDate}',
                ),
                subtitle: Text(
                  'Sales: $kCurrency ${shift.totalSales.toStringAsFixed(0)} | Exp: $kCurrency ${shift.totalExpenses.toStringAsFixed(0)}',
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$kCurrency ${profit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: profit >= 0 ? colorScheme.tertiary : colorScheme.error,
                      ),
                    ),
                    if (isActive)
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShiftDetailScreen(shiftId: shift.id),
                  ),
                ),
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
          if (_startDate != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date filter',
              onPressed: () => setState(() {
                _startDate = null;
                _endDate = null;
              }),
            ),
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by date range',
            onPressed: _pickDateRange,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _filterType = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Shifts')),
              const PopupMenuItem(
                value: 'morning',
                child: Text('Morning Only'),
              ),
              const PopupMenuItem(
                value: 'evening',
                child: Text('Evening Only'),
              ),
              const PopupMenuItem(value: 'closed', child: Text('Closed Only')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search shifts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          if (_startDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Chip(
                avatar: const Icon(Icons.date_range, size: 18),
                label: Text(
                  '${_startDate!.formattedDate} - ${_endDate!.formattedDate}',
                ),
                onDeleted: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allShiftsProvider);
              },
              child: isWide(context)
                  ? Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
                        child: body,
                      ),
                    )
                  : body,
            ),
          ),
        ],
      ),
    );
  }
}
