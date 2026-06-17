import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/constants.dart';

class PdfService {
  static String _formatCurrency(double value) {
    final formatter = NumberFormat('#,##0.00');
    return '$kCurrency ${formatter.format(value)}';
  }

  static Future<void> generateShiftReport({
    required String shiftType,
    required String date,
    required List<Map<String, dynamic>> salesData,
    required double totalSales,
    required double totalExpenses,
    required double profit,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              kAppName,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Header(
            level: 1,
            child: pw.Text('Shift Report - ${shiftType.toUpperCase()}'),
          ),
          pw.Text('Date: $date'),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Product', 'Quantity', 'Rate', 'Amount'],
            data: salesData
                .map(
                  (row) => [
                    row['product'] ?? '',
                    '${row['quantity'] ?? 0}',
                    '${row['rate'] ?? 0}',
                    '${row['amount'] ?? 0}',
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Sales:'),
              pw.Text(_formatCurrency(totalSales)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Expenses:'),
              pw.Text(_formatCurrency(totalExpenses)),
            ],
          ),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Net Profit:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                _formatCurrency(profit),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  static Future<void> generateMonthlyReport({
    required int month,
    required int year,
    required Map<String, double> expenseSummary,
    required double totalSales,
    required double totalExpenses,
  }) async {
    final pdf = pw.Document();
    final monthName = DateFormat('MMMM yyyy').format(DateTime(year, month));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              kAppName,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Header(level: 1, child: pw.Text('Monthly Report - $monthName')),
          pw.SizedBox(height: 20),
          pw.Header(level: 2, child: pw.Text('Sales Summary')),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Sales:'),
              pw.Text(_formatCurrency(totalSales)),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 2, child: pw.Text('Expense Breakdown')),
          pw.TableHelper.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Category', 'Amount'],
            data: expenseSummary.entries
                .map(
                  (e) => [
                    e.key.toUpperCase(),
                    _formatCurrency(e.value),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 10),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total Expenses:'),
              pw.Text(_formatCurrency(totalExpenses)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Net Profit:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              pw.Text(
                _formatCurrency(totalSales - totalExpenses),
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
