import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  String get formattedDate => DateFormat('dd MMM yyyy').format(this);
  String get formattedDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(this);
  String get formattedTime => DateFormat('hh:mm a').format(this);
  String get formattedMonth => DateFormat('MMMM yyyy').format(this);
  String get formattedDay => DateFormat('EEEE, dd MMM yyyy').format(this);

  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59);
  DateTime get startOfMonth => DateTime(year, month);
  DateTime get endOfMonth => DateTime(year, month + 1, 0, 23, 59, 59);
}

extension DoubleExtension on double {
  String get formatted => toStringAsFixed(2);
  String get formattedWithCurrency => 'Rs. ${toStringAsFixed(2)}';
}
