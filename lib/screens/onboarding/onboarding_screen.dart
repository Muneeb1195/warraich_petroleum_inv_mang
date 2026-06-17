import 'package:flutter/material.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/constants.dart';
import '../home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingPage(
      icon: Icons.local_gas_station,
      title: kAppName,
      description:
          'Complete petrol pump management system. Track sales, manage inventory, handle expenses, and generate reports — all in one place.',
    ),
    _OnboardingPage(
      icon: Icons.schedule,
      title: 'Shifts & Sales',
      description:
          'Manage morning and evening shifts. Record fuel sales with pump readings, track cash/card/credit payments, and view daily summaries.',
    ),
    _OnboardingPage(
      icon: Icons.receipt_long,
      title: 'Expenses & Inventory',
      description:
          'Log expenses by category, track stock levels for fuel and lubricants, set minimum stock alerts, and manage supplier payments.',
    ),
    _OnboardingPage(
      icon: Icons.people,
      title: 'Employees & Reports',
      description:
          'Manage staff, generate payroll, view sales history with date filters, and export PDF reports for accounting.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _finish(context),
                  child: const Text('Skip'),
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: _pages
                    .map((page) => _buildPage(context, page, colorScheme))
                    .toList(),
              ),
            ),
            _buildBottomBar(context, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    _OnboardingPage page,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 64,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } else {
                  _finish(context);
                }
              },
              child: Text(
                _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _finish(BuildContext context) {
    completeOnboarding();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}
