import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../database/app_database.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;
  final String? barcode;

  const ProductFormScreen({super.key, this.productId, this.barcode});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _buyPriceController;
  late TextEditingController _sellPriceController;
  late TextEditingController _qtyController;
  String? _category;

  bool _isLoading = true;
  bool _isSaving = false;
  Product? _existingProduct;

  final List<String> _categories = [
    'Alimentation',
    'Boissons',
    'Électronique',
    'Vêtements',
    'Hygiène',
    'Autre'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _barcodeController = TextEditingController(text: widget.barcode);
    _buyPriceController = TextEditingController();
    _sellPriceController = TextEditingController();
    _qtyController = TextEditingController(text: '0');
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.productId != null) {
      final db = ref.read(databaseProvider);
      final product = await db.getProductById(widget.productId!);
      if (product != null) {
        _existingProduct = product;
        _nameController.text = product.name;
        _barcodeController.text = product.barcode;
        _buyPriceController.text = product.buyPrice.toString();
        _sellPriceController.text = product.sellPrice.toString();
        _qtyController.text = product.quantity.toString();
        _category = product.category;
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    try {
      final name = _nameController.text.trim();
      final barcode = _barcodeController.text.trim();
      final buyPrice = double.tryParse(_buyPriceController.text) ?? 0.0;
      final sellPrice = double.tryParse(_sellPriceController.text) ?? 0.0;
      final quantity = int.tryParse(_qtyController.text) ?? 0;

      if (_existingProduct != null) {
        // Update
        final updated = _existingProduct!.copyWith(
          name: name,
          barcode: barcode,
          buyPrice: buyPrice,
          sellPrice: sellPrice,
          quantity: quantity,
          category: drift.Value(_category),
        );
        await db.updateProductRow(updated);
        // Note: quantity change here doesn't automatically insert a Movement.
        // For a full app, we might calculate delta and insert an adjustment.
      } else {
        // Insert
        final companion = ProductsCompanion(
          name: drift.Value(name),
          barcode: drift.Value(barcode),
          buyPrice: drift.Value(buyPrice),
          sellPrice: drift.Value(sellPrice),
          quantity: drift.Value(quantity),
          category: drift.Value(_category),
        );
        final newId = await db.insertProduct(companion);

        // Initial adjustment movement
        if (quantity != 0) {
          await db.insertMovement(MovementsCompanion(
            productId: drift.Value(newId),
            type: const drift.Value('adjustment'),
            quantity: drift.Value(quantity),
            note: const drift.Value('Initial stock'),
          ));
        }
      }

      // TODO: WooCommerce Sync logic would go here

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product saved: $name')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/products');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppTheme.saleRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isEdit = _existingProduct != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'New Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(labelText: 'Barcode *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Barcode is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name *'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _buyPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Buy Price (DZD) *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _sellPriceController,
                      decoration: const InputDecoration(
                          labelText: 'Sell Price (DZD) *'),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Required'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c));
                      }).toList(),
                      onChanged: (v) => setState(() => _category = v),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      // For edits, we might want to disable manual qty edit 
                      // and force movements instead, but keeping it simple for now.
                      enabled: !isEdit, 
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
