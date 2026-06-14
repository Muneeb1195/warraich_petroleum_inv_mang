import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/shift_provider.dart';
import '../../providers/expense_provider.dart';
import '../../services/pdf_service.dart';

class PdfReportScreen extends ConsumerStatefulWidget {
  const PdfReportScreen({super.key});

  @override
  ConsumerState<PdfReportScreen> createState() => _PdfReportScreenState();
}

class _PdfReportScreenState extends ConsumerState<PdfReportScreen> {
  int? _selectedShiftId;
  DateTime _selectedMonth = DateTime.now();
  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final allShifts = ref.watch(allShiftsProvider);

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shift Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                allShifts.when(
                  data: (shifts) {
                    final closedShifts = shifts.where((s) => s.status == 'closed').toList();
                    if (closedShifts.isEmpty) return const Text('No closed shifts available');
                    return Column(
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedShiftId,
                          decoration: const InputDecoration(labelText: 'Select Shift'),
                          items: closedShifts.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.type.toUpperCase()} - ${s.startDate.toString().substring(0, 10)}'))).toList(),
                          onChanged: (value) => setState(() => _selectedShiftId = value),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _selectedShiftId == null
                                ? null
                                : () async {
                                    final shift = closedShifts.firstWhere((s) => s.id == _selectedShiftId);
                                    final sales = await ref.read(shiftSalesProvider(_selectedShiftId!).future);
                                    final mappedSales = sales.map((row) => {'product': row.product.name, 'quantity': row.sale.quantitySold, 'rate': row.product.pricePerUnit, 'amount': row.sale.totalAmount}).toList();
                                    final dateFormatted = DateFormat('yyyy-MM-dd').format(shift.startDate);
                                    await PdfService.generateShiftReport(shiftType: shift.type.toUpperCase(), date: dateFormatted, salesData: mappedSales, totalSales: shift.totalSales, totalExpenses: shift.totalExpenses, profit: shift.totalSales - shift.totalExpenses);
                                  },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: const Text('Generate Shift Report'),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monthly Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (date != null) setState(() => _selectedMonth = date);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final summary = await ref.read(expenseSummaryProvider((start: DateTime(_selectedMonth.year, _selectedMonth.month), end: DateTime(_selectedMonth.year, _selectedMonth.month + 1))).future);
                      final totalExpenses = summary.values.fold<double>(0, (s, v) => s + v);
                      final shifts = ref.read(allShiftsProvider).valueOrNull ?? [];
                      final monthShifts = shifts.where((s) => s.startDate.month == _selectedMonth.month && s.startDate.year == _selectedMonth.year && s.status == 'closed').toList();
                      final totalSales = monthShifts.fold<double>(0, (s, shift) => s + shift.totalSales);
                      await PdfService.generateMonthlyReport(month: _selectedMonth.month, year: _selectedMonth.year, expenseSummary: summary, totalSales: totalSales, totalExpenses: totalExpenses);
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate Monthly Report'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Expense Report', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_month),
                  title: Text(DateFormat('MMMM yyyy').format(_selectedMonth)),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: _selectedMonth, firstDate: DateTime(2020), lastDate: DateTime.now());
                    if (date != null) setState(() => _selectedMonth = date);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final summary = await ref.read(expenseSummaryProvider((start: DateTime(_selectedMonth.year, _selectedMonth.month), end: DateTime(_selectedMonth.year, _selectedMonth.month + 1))).future);
                      final totalExpenses = summary.values.fold<double>(0, (s, v) => s + v);
                      await PdfService.generateMonthlyReport(month: _selectedMonth.month, year: _selectedMonth.year, expenseSummary: summary, totalSales: 0, totalExpenses: totalExpenses);
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generate Expense Report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: _isDesktop
          ? Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: body))
          : body,
    );
  }
}
