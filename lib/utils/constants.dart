const kAppName = 'Warraich Petroleum';
const kCurrency = 'Rs.';
const kDbFileName = 'warraich_petroleum.db';
const kPreRestoreDbFileName = 'pre_restore_backup.db';

const kExpenseCategories = [
  'Electricity',
  'Maintenance',
  'Transport',
  'Utilities',
  'Misc',
];

const kShiftTypes = ['morning', 'evening'];
const kEmployeeRoles = [
  'Operator',
  'Manager',
  'Cleaner',
  'Supervisor',
  'Other',
];
const kDefaultShifts = ['morning', 'evening', 'both'];

String formatMoney(double value, {bool abbreviate = true}) {
  final isNegative = value < 0;
  final absVal = value.abs();
  String formatted;
  if (abbreviate && absVal >= 999500) {
    formatted = '$kCurrency ${(absVal / 1000000).toStringAsFixed(1)}M';
  } else if (abbreviate && absVal >= 1000) {
    formatted = '$kCurrency ${(absVal / 1000).toStringAsFixed(1)}k';
  } else {
    formatted = '$kCurrency ${absVal.toStringAsFixed(0)}';
  }
  return isNegative ? '-$formatted' : formatted;
}
