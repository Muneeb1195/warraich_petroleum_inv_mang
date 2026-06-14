import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/shifts/shifts_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/employees/employees_screen.dart';
import '../screens/payroll/payroll_screen.dart';
import '../screens/history/sales_history_screen.dart';
import '../screens/reports/pdf_report_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/shift_provider.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _mobileScreens = [
    const DashboardScreen(),
    const ShiftsScreen(),
    const InventoryScreen(),
    const ExpensesScreen(),
    const SettingsScreen(),
  ];

  final _desktopScreens = [
    const DashboardScreen(),
    const ShiftsScreen(),
    const InventoryScreen(),
    const ExpensesScreen(),
    const EmployeesScreen(),
    const PayrollScreen(),
    const SalesHistoryScreen(),
    const PdfReportScreen(),
    const SettingsScreen(),
  ];

  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  @override
  Widget build(BuildContext context) {
    final activeShift = ref.watch(activeShiftProvider);

    if (_isDesktop) {
    return Scaffold(
      key: _scaffoldKey,
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
                  icon: Icon(Icons.people_outlined),
                  selectedIcon: Icon(Icons.people),
                  label: Text('Employees'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments),
                  label: Text('Payroll'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('Sales History'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  selectedIcon: Icon(Icons.picture_as_pdf),
                  label: Text('Reports'),
                ),
                const NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _desktopScreens,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.local_gas_station, size: 36, color: colorScheme.onPrimaryContainer),
                  const SizedBox(height: 8),
                  Text('Warraich Petroleum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
            _DrawerItem(icon: Icons.people, title: 'Employees', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeesScreen())); }),
            _DrawerItem(icon: Icons.payments, title: 'Payroll', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PayrollScreen())); }),
            _DrawerItem(icon: Icons.history, title: 'Sales History', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SalesHistoryScreen())); }),
            _DrawerItem(icon: Icons.picture_as_pdf, title: 'Reports', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfReportScreen())); }),
            const Divider(),
            _DrawerItem(icon: Icons.settings, title: 'Settings', onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())); }),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _mobileScreens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            setState(() => _currentIndex = index);
          }
        },
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

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }
}
