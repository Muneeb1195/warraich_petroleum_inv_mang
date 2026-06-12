import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/shift_provider.dart';

class NewShiftScreen extends ConsumerStatefulWidget {
  const NewShiftScreen({super.key});

  @override
  ConsumerState<NewShiftScreen> createState() => _NewShiftScreenState();
}

class _NewShiftScreenState extends ConsumerState<NewShiftScreen> {
  String _selectedType = 'morning';

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
                    Text(
                      'Shift Type',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'morning',
                          label: Text('Morning'),
                          icon: Icon(Icons.wb_sunny),
                        ),
                        ButtonSegment(
                          value: 'evening',
                          label: Text('Evening'),
                          icon: Icon(Icons.nightlight_round),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (selected) {
                        setState(() => _selectedType = selected.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Time',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateTime.now().toString().substring(0, 19),
                      style: Theme.of(context).textTheme.bodyLarge,
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
                      await ref.read(shiftNotifierProvider.notifier).startShift(_selectedType);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$_selectedType shift started')),
                        );
                      }
                    },
              child: shiftState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Start Shift'),
            ),
          ],
        ),
      ),
    );
  }
}
