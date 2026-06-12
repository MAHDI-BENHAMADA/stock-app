import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_widget.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _filter = 'All'; // All | Sale | Restock | Adjustment

  @override
  Widget build(BuildContext context) {
    final movementsAsync = ref.watch(allMovementsWithProductProvider);
    final dateFormat = DateFormat('MMM d, y • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movement History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Sale', 'Restock', 'Adjustment'].map((type) {
                final isSelected = _filter == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _filter = type);
                    },
                    selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryGreen,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: movementsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (movements) {
          final filtered = movements.where((m) {
            if (_filter == 'All') return true;
            return m.movement.type.toLowerCase() == _filter.toLowerCase();
          }).toList();

          if (filtered.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_rounded,
              title: 'No movements yet',
              subtitle: 'Sales and restocks will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = filtered[index];
              final m = item.movement;
              final p = item.product;

              final isSale = m.type == 'sale';
              final isRestock = m.type == 'restock';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSale
                            ? AppTheme.saleRed.withValues(alpha: 0.1)
                            : isRestock
                                ? AppTheme.restockGreen.withValues(alpha: 0.1)
                                : AppTheme.adjustmentGray.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isSale ? Icons.remove : isRestock ? Icons.add : Icons.edit,
                        color: isSale
                            ? AppTheme.saleRed
                            : isRestock
                                ? AppTheme.restockGreen
                                : AppTheme.adjustmentGray,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(m.createdAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${m.quantity > 0 ? '+' : ''}${m.quantity}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: isSale
                                ? AppTheme.saleRed
                                : isRestock
                                    ? AppTheme.restockGreen
                                    : AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
