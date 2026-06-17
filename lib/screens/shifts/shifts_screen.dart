import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../database/app_database.dart';
import '../../providers/shift_provider.dart';
import '../../providers/format_provider.dart';
import '../../utils/constants.dart';
import '../../utils/responsive.dart';
import 'new_shift_screen.dart';
import 'shift_detail_screen.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShift = ref.watch(activeShiftProvider);
    final allShifts = ref.watch(allShiftsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Shifts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NewShiftScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Shift'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(activeShiftProvider);
          ref.invalidate(allShiftsProvider);
        },
        child: _buildBody(context, ref, activeShift, allShifts, colorScheme),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> activeShift,
    AsyncValue<List<Shift>> allShifts,
    ColorScheme colorScheme,
  ) {
    final content = ListView(
      padding: const EdgeInsets.all(16),
      children: [
        activeShift.when(
          data: (shift) {
            if (shift == null) return const SizedBox.shrink();
            return Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
                title: Text('${shift.type.toUpperCase()} Shift - ACTIVE'),
                subtitle: Text(
                  'Started: ${DateFormat('dd MMM yyyy, hh:mm a').format(shift.startDate)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShiftDetailScreen(shiftId: shift.id),
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
        const SizedBox(height: 16),
        Text(
          'History',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        allShifts.when(
          data: (shifts) {
            if (shifts.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No shifts recorded yet'),
                ),
              );
            }
            return Column(
              children: shifts.map<Widget>((shift) {
                final isActive = shift.status == 'active';
                final profit = shift.totalSales - shift.totalExpenses;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isActive ? Icons.schedule : Icons.check_circle,
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      '${shift.type.toUpperCase()} Shift',
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      isActive
                          ? DateFormat(
                              'EEEE, dd MMM yyyy',
                            ).format(shift.startDate)
                          : '${DateFormat('EEEE, dd MMM yyyy').format(shift.startDate)} | Exp: ${fm(ref, shift.totalExpenses)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fm(ref, shift.totalSales),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isActive)
                          Text(
                            profit >= 0
                                ? '+${fm(ref, profit)}'
                                : fm(ref, profit),
                            style: TextStyle(
                              fontSize: 11,
                              color: profit >= 0 ? colorScheme.tertiary : colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ShiftDetailScreen(shiftId: shift.id),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
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
