import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/shifts/shifts_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/shift_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  final _screens = [
    const DashboardScreen(),
    const ShiftsScreen(),
    const InventoryScreen(),
    const ExpensesScreen(),
    const SettingsScreen(),
  ];

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final activeShift = ref.watch(activeShiftProvider);

    if (_isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(Icons.local_gas_station, color: colorScheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'WP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: activeShift.hasValue && activeShift.value != null,
                    child: const Icon(Icons.dashboard_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: activeShift.hasValue && activeShift.value != null,
                    child: const Icon(Icons.dashboard),
                  ),
                  label: const Text('Dashboard'),
                ),
                NavigationRailDestination(
                  icon: Badge(
                    isLabelVisible: activeShift.hasValue && activeShift.value != null,
                    child: const Icon(Icons.schedule_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: activeShift.hasValue && activeShift.value != null,
                    child: const Icon(Icons.schedule),
                  ),
                  label: const Text('Shifts'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: Text('Inventory'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long),
                  label: Text('Expenses'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.more_horiz_outlined),
                  selectedIcon: Icon(Icons.more_horiz),
                  label: Text('More'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: activeShift.hasValue && activeShift.value != null,
              child: const Icon(Icons.schedule_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: activeShift.hasValue && activeShift.value != null,
              child: const Icon(Icons.schedule),
            ),
            label: 'Shifts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Expenses',
          ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_outlined),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  ColorScheme get colorScheme => Theme.of(context).colorScheme;
}
