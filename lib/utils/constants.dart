const kAppName = 'Warraich Petroleum';
const kCurrency = 'Rs.';

const kExpenseCategories = [
  'Electricity',
  'Maintenance',
  'Transport',
  'Utilities',
  'Misc',
];

const kShiftTypes = ['morning', 'evening'];
const kEmployeeRoles = ['Operator', 'Manager', 'Cleaner', 'Supervisor', 'Other'];
const kDefaultShifts = ['morning', 'evening', 'both'];

String formatMoney(double value) {
  final isNegative = value < 0;
  final absVal = value.abs();
  String formatted;
  if (absVal >= 999500) {
    formatted = '$kCurrency ${(absVal / 1000000).toStringAsFixed(1)}M';
  } else if (absVal >= 1000) {
    formatted = '$kCurrency ${(absVal / 1000).toStringAsFixed(1)}k';
  } else {
    formatted = '$kCurrency ${absVal.toStringAsFixed(0)}';
  }
  return isNegative ? '-$formatted' : formatted;
}
