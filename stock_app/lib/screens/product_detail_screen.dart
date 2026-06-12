import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../database/app_database.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.currency(
        locale: 'fr_DZ', symbol: 'DA', decimalDigits: 0);
    final dateFormat = DateFormat('MMM d, y HH:mm');

    // We can get the product directly from the future or a stream
    final db = ref.watch(databaseProvider);
    final movementsAsync = ref.watch(movementsForProductProvider(productId));

    return FutureBuilder<Product?>(
      future: db.getProductById(productId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(child: Text('Error: ${snapshot.error}')));
        }
        final product = snapshot.data;
        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Product not found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(product.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/product/${product.id}/edit'),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppTheme.saleRed),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Product?'),
                      content: const Text(
                          'This will permanently remove the product.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.saleRed),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await db.deleteProductById(product.id);
                    if (context.mounted) {
                      context.go('/products');
                    }
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem(context, 'Category',
                              product.category ?? 'Uncategorized'),
                          _buildDetailItem(context, 'Quantity',
                              '${product.quantity}',
                              valueColor: product.quantity < 5
                                  ? AppTheme.saleRed
                                  : AppTheme.primaryGreen),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildDetailItem(context, 'Buy Price',
                              currencyFormat.format(product.buyPrice)),
                          _buildDetailItem(context, 'Sell Price',
                              currencyFormat.format(product.sellPrice)),
                        ],
                      ),
                      if (product.wooId != null) ...[
                        const Divider(height: 32),
                        _buildDetailItem(
                            context, 'WooCommerce ID', '${product.wooId}'),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Barcode display
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    BarcodeWidget(
                      barcode: Barcode.code128(),
                      data: product.barcode,
                      height: 80,
                      drawText: false,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.barcode,
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Movement History
              Text(
                'Recent Movements',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              movementsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error: $err'),
                data: (movements) {
                  if (movements.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No movements recorded yet.'),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: movements.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final m = movements[index];
                      final isSale = m.type == 'sale';
                      final isRestock = m.type == 'restock';

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isSale
                              ? AppTheme.saleRed.withValues(alpha: 0.1)
                              : isRestock
                                  ? AppTheme.restockGreen.withValues(alpha: 0.1)
                                  : AppTheme.adjustmentGray
                                      .withValues(alpha: 0.1),
                          child: Icon(
                            isSale
                                ? Icons.remove
                                : isRestock
                                    ? Icons.add
                                    : Icons.edit,
                            color: isSale
                                ? AppTheme.saleRed
                                : isRestock
                                    ? AppTheme.restockGreen
                                    : AppTheme.adjustmentGray,
                          ),
                        ),
                        title: Text(
                            '${m.type[0].toUpperCase()}${m.type.substring(1)}'),
                        subtitle: Text(dateFormat.format(m.createdAt)),
                        trailing: Text(
                          '${m.quantity > 0 ? '+' : ''}${m.quantity}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSale
                                ? AppTheme.saleRed
                                : isRestock
                                    ? AppTheme.restockGreen
                                    : AppTheme.textPrimary,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value,
      {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
