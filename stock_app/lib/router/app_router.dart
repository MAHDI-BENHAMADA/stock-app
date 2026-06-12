import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../screens/shell_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/product_list_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScanScreen(),
            ),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductListScreen(),
            ),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HistoryScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/product/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final barcode = state.uri.queryParameters['barcode'];
          return ProductFormScreen(barcode: barcode);
        },
      ),
      GoRoute(
        path: '/product/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/product/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
