import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/app_database.dart';
import '../../providers/expense_provider.dart';
import '../../providers/shift_provider.dart';
import '../../utils/constants.dart';
import '../../utils/error_utils.dart';
import '../../utils/extensions.dart';
import '../../utils/responsive.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  const AddExpenseScreen({super.key, this.expense});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  late String _selectedCategory;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _selectedCategory = e?.category ?? 'Misc';
    _amountController = TextEditingController(
      text: e != null ? e.amount.toString() : '',
    );
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _selectedDate = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseNotifierProvider);
    final activeShift = ref.watch(activeShiftProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Expense' : 'Add Expense')),
      body: _buildBody(context, expenseState, activeShift),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue expenseState,
    AsyncValue activeShift,
  ) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isEditing)
            activeShift.when(
              data: (shift) {
                if (shift == null) return const SizedBox.shrink();
                return Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.link,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Linked to ${shift.type.toUpperCase()} shift',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, e) => const SizedBox.shrink(),
            ),
          if (!_isEditing) const SizedBox(height: 12),
          Text(
            'Category',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kExpenseCategories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount ($kCurrency)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text('Date: ${_selectedDate.formattedDate}'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null && context.mounted)
                setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: expenseState.isLoading
                ? null
                : () async {
                    final amount = double.tryParse(_amountController.text) ?? 0;
                    if (amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount')),
                      );
                      return;
                    }
                    try {
                      if (_isEditing) {
                        await ref
                            .read(expenseNotifierProvider.notifier)
                            .updateExpense(
                              id: widget.expense!.id,
                              category: _selectedCategory,
                              amount: amount,
                              description:
                                  _descriptionController.text.isNotEmpty
                                  ? _descriptionController.text
                                  : null,
                              date: _selectedDate,
                            );
                      } else {
                        final activeShiftData = ref
                            .read(activeShiftProvider)
                            .asData
                            ?.value;
                        await ref
                            .read(expenseNotifierProvider.notifier)
                            .addExpense(
                              category: _selectedCategory,
                              amount: amount,
                              description:
                                  _descriptionController.text.isNotEmpty
                                  ? _descriptionController.text
                                  : null,
                              date: _selectedDate,
                              shiftId: activeShiftData?.id,
                            );
                      }
                      if (context.mounted) {
                        ref.invalidate(todaySummaryProvider);
                        ref.invalidate(weeklyExpensesProvider);
                        ref.invalidate(weeklyProfitProvider);
                        ref.invalidate(monthlySummaryProvider);
                        Navigator.pop(context);
                        context.showSuccess(
                          _isEditing ? 'Expense updated' : 'Expense added',
                        );
                      }
                    } catch (e) {
                      if (context.mounted)
                        context.showError(e, source: 'saveExpense');
                    }
                  },
            child: expenseState.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_isEditing ? 'Update Expense' : 'Add Expense'),
          ),
        ],
      ),
    );

    if (isWide(context)) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
          child: content,
        ),
      );
    }
    return content;
  }
}
