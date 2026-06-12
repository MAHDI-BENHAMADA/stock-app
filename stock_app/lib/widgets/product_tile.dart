import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/app_database.dart';
import '../theme/app_theme.dart';

class ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductTile({
    super.key,
    required this.product,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat =
        NumberFormat.currency(locale: 'fr_DZ', symbol: 'DA', decimalDigits: 0);
    final isLowStock = product.quantity < 5;
    final margin = product.sellPrice - product.buyPrice;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLowStock
                ? AppTheme.warningOrange.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            // Product icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _categoryIcon(product.category),
                color: AppTheme.primaryGreen,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        currencyFormat.format(product.sellPrice),
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.secondaryGold,
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                      if (margin > 0) ...[
                        const SizedBox(width: 8),
                        Text(
                          '+${currencyFormat.format(margin)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primaryGreen,
                                    fontSize: 11,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Quantity badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isLowStock
                    ? AppTheme.saleRed.withValues(alpha: 0.12)
                    : AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${product.quantity}',
                style: TextStyle(
                  color: isLowStock
                      ? AppTheme.saleRed
                      : AppTheme.primaryGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'alimentation':
      case 'food':
        return Icons.restaurant_rounded;
      case 'boissons':
      case 'drinks':
        return Icons.local_drink_rounded;
      case 'hygiène':
      case 'hygiene':
        return Icons.clean_hands_rounded;
      case 'électronique':
      case 'electronics':
        return Icons.devices_rounded;
      case 'vêtements':
      case 'clothing':
        return Icons.checkroom_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}
