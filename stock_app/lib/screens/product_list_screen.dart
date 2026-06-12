import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/product_tile.dart';
import '../widgets/empty_state_widget.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products by name or barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ),
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error: $err', style: const TextStyle(color: AppTheme.saleRed)),
        ),
        data: (products) {
          final filtered = products.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.name.toLowerCase().contains(q) ||
                p.barcode.toLowerCase().contains(q);
          }).toList();

          if (filtered.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.inventory_2_outlined,
              title: _searchQuery.isEmpty ? 'No products yet' : 'No matches found',
              subtitle: _searchQuery.isEmpty
                  ? 'Add your first product by tapping the + button.'
                  : 'Try a different search term.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final product = filtered[index];
              return ProductTile(
                product: product,
                onTap: () => context.push('/product/${product.id}'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/product/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
