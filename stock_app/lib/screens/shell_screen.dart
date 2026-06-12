import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/scan')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/history')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/');
              case 1:
                context.go('/scan');
              case 2:
                context.go('/products');
              case 3:
                context.go('/history');
            }
          },
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined, color: AppTheme.textMuted),
              selectedIcon:
                  const Icon(Icons.dashboard_rounded, color: AppTheme.primaryGreen),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon:
                  Icon(Icons.qr_code_scanner_outlined, color: AppTheme.textMuted),
              selectedIcon: const Icon(Icons.qr_code_scanner_rounded,
                  color: AppTheme.primaryGreen),
              label: 'Scan',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined, color: AppTheme.textMuted),
              selectedIcon: const Icon(Icons.inventory_2_rounded,
                  color: AppTheme.primaryGreen),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined, color: AppTheme.textMuted),
              selectedIcon:
                  const Icon(Icons.history_rounded, color: AppTheme.primaryGreen),
              label: 'History',
            ),
          ],
        ),
      ),
    );
  }
}
