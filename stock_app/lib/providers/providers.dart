import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

// ─── Database singleton ────────────────────────────────────────────
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

// ─── Product providers ─────────────────────────────────────────────
final allProductsProvider = StreamProvider<List<Product>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllProducts();
});

final lowStockProductsProvider =
    StreamProvider.family<List<Product>, int>((ref, threshold) {
  final db = ref.watch(databaseProvider);
  return db.watchLowStockProducts(threshold);
});

// ─── Movement providers ────────────────────────────────────────────
final allMovementsWithProductProvider =
    StreamProvider<List<MovementWithProduct>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllMovementsWithProduct();
});

final movementsForProductProvider =
    StreamProvider.family<List<Movement>, int>((ref, productId) {
  final db = ref.watch(databaseProvider);
  return db.watchMovementsForProduct(productId);
});

// ─── Dashboard stats ───────────────────────────────────────────────
class DashboardStats {
  final int totalProducts;
  final double totalStockValue;
  final double totalCostValue;
  final int todaySales;
  final int lowStockCount;

  DashboardStats({
    required this.totalProducts,
    required this.totalStockValue,
    required this.totalCostValue,
    required this.todaySales,
    required this.lowStockCount,
  });

  double get potentialProfit => totalStockValue - totalCostValue;
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final db = ref.watch(databaseProvider);
  final products = await db.getAllProducts();
  final totalProducts = products.length;
  final totalStockValue =
      products.fold<double>(0, (sum, p) => sum + (p.sellPrice * p.quantity));
  final totalCostValue =
      products.fold<double>(0, (sum, p) => sum + (p.buyPrice * p.quantity));
  final todaySales = await db.getTodaySalesCount();
  final lowStockCount = products.where((p) => p.quantity < 5).length;

  return DashboardStats(
    totalProducts: totalProducts,
    totalStockValue: totalStockValue,
    totalCostValue: totalCostValue,
    todaySales: todaySales,
    lowStockCount: lowStockCount,
  );
});

// ─── Low stock threshold ───────────────────────────────────────────
final lowStockThresholdProvider = StateProvider<int>((ref) => 5);
