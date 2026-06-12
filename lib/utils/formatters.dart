import 'package:intl/intl.dart';

class Formatters {
  static final currencyFormat = NumberFormat.currency(
    symbol: 'Rs. ',
    decimalDigits: 2,
  );

  static final numberFormat = NumberFormat('#,##0.00');
  static final percentFormat = NumberFormat.percentPattern();

  static String currency(double amount) => currencyFormat.format(amount);
  static String number(double value) => numberFormat.format(value);
}
