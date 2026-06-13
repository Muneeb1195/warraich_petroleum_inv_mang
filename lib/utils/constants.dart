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
  if (value >= 1000000) {
    return 'Rs. ${(value / 1000000).toStringAsFixed(1)}M';
  } else if (value >= 1000) {
    return 'Rs. ${(value / 1000).toStringAsFixed(1)}k';
  }
  return 'Rs. ${value.toStringAsFixed(0)}';
}
