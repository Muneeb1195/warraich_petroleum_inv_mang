import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/shift_provider.dart';

class NewShiftScreen extends ConsumerStatefulWidget {
  const NewShiftScreen({super.key});

  @override
  ConsumerState<NewShiftScreen> createState() => _NewShiftScreenState();
}

bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  class _NewShiftScreenState extends ConsumerState<NewShiftScreen> {
  String _selectedType = 'morning';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    final shiftState = ref.watch(shiftNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Start New Shift')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shift Type', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'morning', label: Text('Morning'), icon: Icon(Icons.wb_sunny)),
                        ButtonSegment(value: 'evening', label: Text('Evening'), icon: Icon(Icons.nightlight_round)),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (selected) => setState(() => _selectedType = selected.first),
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
                    Text('Date & Time', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today),
                      title: Text(DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _selectedDate = date);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time),
                      title: Text(_selectedTime.format(context)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime,
                        );
                        if (time != null) setState(() => _selectedTime = time);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: shiftState.isLoading
                  ? null
                  : () async {
                      final dateTime = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      );
                      await ref.read(shiftNotifierProvider.notifier).startShift(_selectedType, dateTime: dateTime);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$_selectedType shift started')),
                        );
                      }
                    },
              child: shiftState.isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Start Shift'),
            ),
          ],
        ),
      ),
    );
  }
}
