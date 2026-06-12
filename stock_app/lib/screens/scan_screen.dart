import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../database/app_database.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes.first.rawValue == null) return;
    
    setState(() => _isProcessing = true);
    
    final code = barcodes.first.rawValue!;
    final db = ref.read(databaseProvider);
    
    try {
      final product = await db.getProductByBarcode(code);
      if (product != null) {
        // Stop scanning while sheet is open
        _controller.stop();
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => ScanActionSheet(product: product),
          );
        }
        // Resume scanning after sheet closes
        if (mounted) {
          _controller.start();
        }
      } else {
        if (mounted) {
          context.push('/product/new?barcode=$code');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error finding product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    'Camera Error: ${error.errorCode}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
          ),
          
          // Overlay UI
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryGreen, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          
          // Hint Text
          const Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Text(
              'Point at Barcode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          
          // App Bar Area with Torch Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                color: Colors.white,
                icon: const Icon(Icons.flashlight_on_rounded),
                onPressed: () => _controller.toggleTorch(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan Action Sheet ──────────────────────────────────────────────

class ScanActionSheet extends ConsumerStatefulWidget {
  final Product product;
  const ScanActionSheet({super.key, required this.product});

  @override
  ConsumerState<ScanActionSheet> createState() => _ScanActionSheetState();
}

class _ScanActionSheetState extends ConsumerState<ScanActionSheet> {
  final _qtyController = TextEditingController(text: '1');
  bool _isSaving = false;

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  Future<void> _processTransaction(String type) async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) return;

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    try {
      if (type == 'sale') {
        await db.sellProduct(widget.product.id, qty);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sold $qty × ${widget.product.name}')),
          );
        }
      } else {
        await db.restockProduct(widget.product.id, qty);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Restocked $qty × ${widget.product.name}')),
          );
        }
      }
      // Invalidate providers to refresh dashboard/lists
      ref.invalidate(dashboardStatsProvider);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.saleRed),
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.product.name,
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Current Stock: ${widget.product.quantity}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _qtyController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Quantity',
              alignLabelWithHint: true,
            ),
          ),
          
          const SizedBox(height: 24),
          
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.saleRed,
                    ),
                    onPressed: () => _processTransaction('sale'),
                    child: const Text('Sell'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.restockGreen,
                    ),
                    onPressed: () => _processTransaction('restock'),
                    child: const Text('Restock'),
                  ),
                ),
              ],
            ),
            
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/product/${widget.product.id}');
            },
            child: const Text('View Product Details'),
          ),
        ],
      ),
    );
  }
}
