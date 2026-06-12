import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/metric_card.dart';
import '../widgets/product_tile.dart';
import '../widgets/empty_state_widget.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final threshold = ref.watch(lowStockThresholdProvider);
    final lowStockAsync = ref.watch(lowStockProductsProvider(threshold));

    final currencyFormat = NumberFormat.currency(
        locale: 'fr_DZ', symbol: 'DA', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
        },
        color: AppTheme.primaryGreen,
        backgroundColor: AppTheme.cardDarkElevated,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Metrics Grid
            statsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Center(
                child: Text('Error loading stats: $err',
                    style: const TextStyle(color: AppTheme.saleRed)),
              ),
              data: (stats) => GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  MetricCard(
                    title: 'Total Stock Value',
                    value: currencyFormat.format(stats.totalStockValue),
                    subtitle: 'Profit: ${currencyFormat.format(stats.potentialProfit)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: AppTheme.primaryGreen,
                  ),
                  MetricCard(
                    title: 'Today Sales',
                    value: '${stats.todaySales}',
                    icon: Icons.trending_up_rounded,
                    iconColor: AppTheme.secondaryGold,
                  ),
                  MetricCard(
                    title: 'Low Stock',
                    value: '${stats.lowStockCount}',
                    subtitle: 'Below $threshold items',
                    icon: Icons.warning_rounded,
                    iconColor: AppTheme.warningOrange,
                  ),
                  MetricCard(
                    title: 'Total Products',
                    value: '${stats.totalProducts}',
                    icon: Icons.inventory_2_rounded,
                    iconColor: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Low Stock Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Low Stock Alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.push('/products'),
                  child: const Text('See All',
                      style: TextStyle(color: AppTheme.primaryGreen)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            lowStockAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: AppTheme.saleRed)),
              ),
              data: (products) {
                if (products.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Stock is healthy',
                    subtitle: 'No items are running low right now.',
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductTile(
                      product: product,
                      onTap: () => context.push('/product/${product.id}'),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
