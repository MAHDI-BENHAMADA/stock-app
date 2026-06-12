import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ────────────────────────────────────────────────────────

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wooId => integer().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get barcode => text().unique()();
  RealColumn get buyPrice => real().withDefault(const Constant(0.0))();
  RealColumn get sellPrice => real().withDefault(const Constant(0.0))();
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  TextColumn get category => text().nullable()();
  TextColumn get imageUrl => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Movements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get type => text()(); // sale | restock | adjustment
  IntColumn get quantity => integer()(); // signed: -n for sale, +n for restock
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// ─── Data class for joined queries ─────────────────────────────────

class MovementWithProduct {
  final Movement movement;
  final Product product;
  MovementWithProduct({required this.movement, required this.product});
}

// ─── Database ──────────────────────────────────────────────────────

@DriftDatabase(tables: [Products, Movements])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // For testing
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ── Product queries ──────────────────────────────────────────────

  Stream<List<Product>> watchAllProducts() => select(products).watch();

  Future<List<Product>> getAllProducts() => select(products).get();

  Future<Product?> getProductByBarcode(String code) =>
      (select(products)..where((p) => p.barcode.equals(code)))
          .getSingleOrNull();

  Future<Product?> getProductById(int pid) =>
      (select(products)..where((p) => p.id.equals(pid))).getSingleOrNull();

  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  Future<bool> updateProductRow(Product product) =>
      update(products).replace(product);

  Future<int> deleteProductById(int pid) =>
      (delete(products)..where((p) => p.id.equals(pid))).go();

  Stream<List<Product>> watchLowStockProducts(int threshold) =>
      (select(products)..where((p) => p.quantity.isSmallerThanValue(threshold)))
          .watch();

  // ── Movement queries ─────────────────────────────────────────────

  Future<int> insertMovement(MovementsCompanion entry) =>
      into(movements).insert(entry);

  Stream<List<Movement>> watchMovementsForProduct(int pid) =>
      (select(movements)
            ..where((m) => m.productId.equals(pid))
            ..orderBy([(m) => OrderingTerm.desc(m.createdAt)]))
          .watch();

  Stream<List<MovementWithProduct>> watchAllMovementsWithProduct() {
    final query = select(movements).join([
      innerJoin(products, products.id.equalsExp(movements.productId)),
    ])
      ..orderBy([OrderingTerm.desc(movements.createdAt)]);

    return query.watch().map((rows) => rows.map((row) {
          return MovementWithProduct(
            movement: row.readTable(movements),
            product: row.readTable(products),
          );
        }).toList());
  }

  // ── Transactional operations ─────────────────────────────────────

  Future<void> sellProduct(int productId, int qty, {String? note}) {
    return transaction(() async {
      final product = await getProductById(productId);
      if (product == null) throw Exception('Product not found');
      if (product.quantity < qty) {
        throw Exception('Only ${product.quantity} units in stock');
      }

      await (update(products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(quantity: Value(product.quantity - qty)));

      await insertMovement(MovementsCompanion(
        productId: Value(productId),
        type: const Value('sale'),
        quantity: Value(-qty),
        note: Value(note),
      ));
    });
  }

  Future<void> restockProduct(int productId, int qty, {String? note}) {
    return transaction(() async {
      final product = await getProductById(productId);
      if (product == null) throw Exception('Product not found');

      await (update(products)..where((p) => p.id.equals(productId)))
          .write(ProductsCompanion(quantity: Value(product.quantity + qty)));

      await insertMovement(MovementsCompanion(
        productId: Value(productId),
        type: const Value('restock'),
        quantity: Value(qty),
        note: Value(note),
      ));
    });
  }

  // ── Dashboard aggregates ─────────────────────────────────────────

  Future<int> getTotalProductCount() async {
    final count = countAll();
    final query = selectOnly(products)..addColumns([count]);
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  Future<double> getTotalStockValue() async {
    final value = products.sellPrice * products.quantity.cast<double>();
    final sum = value.sum();
    final query = selectOnly(products)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<double> getTotalCostValue() async {
    final value = products.buyPrice * products.quantity.cast<double>();
    final sum = value.sum();
    final query = selectOnly(products)..addColumns([sum]);
    final result = await query.getSingle();
    return result.read(sum) ?? 0.0;
  }

  Future<int> getTodaySalesCount() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final count = countAll();
    final query = selectOnly(movements)
      ..addColumns([count])
      ..where(movements.type.equals('sale') &
          movements.createdAt.isBiggerOrEqualValue(startOfDay));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}

// ─── Connection ────────────────────────────────────────────────────

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'stock_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
