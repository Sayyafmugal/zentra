import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/models/product_variant.dart';

void main() {
  group('Product', () {
    const product = Product(
      id: 'p1',
      imagePath: 'assets/images/shoe.jpg',
      name: 'Air Runner',
      category: 'Shoes',
      currentPrice: 89.99,
      oldPrice: 119.99,
      discount: '25% OFF',
      availableSizes: ['S', 'M', 'L'],
      description: 'A running shoe.',
      rating: 4.5,
      reviewCount: 10,
    );

    test('round-trips through toMap/fromMap', () {
      final restored = Product.fromMap(product.toMap());
      expect(restored, equals(product));
    });

    test('supports value equality via Equatable', () {
      final copy = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Air Runner',
        category: 'Shoes',
        currentPrice: 89.99,
        oldPrice: 119.99,
        discount: '25% OFF',
        availableSizes: ['S', 'M', 'L'],
        description: 'A running shoe.',
        rating: 4.5,
        reviewCount: 10,
      );
      expect(product, equals(copy));
    });

    test('copyWith overrides only the given fields', () {
      final updated = product.copyWith(currentPrice: 79.99, isFavorite: true);
      expect(updated.currentPrice, 79.99);
      expect(updated.isFavorite, isTrue);
      expect(updated.name, product.name);
    });

    test('fromMap fills in safe defaults for missing fields', () {
      final minimal = Product.fromMap({'id': 'p2'});
      expect(minimal.name, '');
      expect(minimal.currentPrice, 0.0);
      expect(minimal.availableSizes, isEmpty);
      expect(minimal.isFavorite, isFalse);
    });

    test(
      'a document written before the marketplace fields existed decodes as admin-owned and published',
      () {
        // Simulates a real pre-upgrade Firestore document: no sellerId,
        // status, sku, images, variants, or totalStock keys at all.
        final legacyMap = {
          'id': 'p3',
          'name': 'Old Product',
          'category': 'Shoes',
          'currentPrice': 40.0,
          'availableSizes': ['M'],
          'description': 'desc',
          'imagePath': 'assets/images/shoe.jpg',
        };
        final restored = Product.fromMap(legacyMap);

        expect(restored.sellerId, isEmpty);
        expect(restored.isOwnedByAdmin, isTrue);
        expect(restored.status, ProductStatus.published);
        expect(restored.isPublished, isTrue);
        expect(restored.hasVariants, isFalse);
        expect(
          restored.stockQuantity,
          isNull,
          reason: 'untracked stock must not read as 0/out-of-stock',
        );
        expect(restored.isInStock, isTrue);
      },
    );

    test('stockQuantity sums variant stock when variants exist, ignoring totalStock', () {
      const withVariants = Product(
        id: 'p4',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Variant Shoe',
        category: 'Shoes',
        currentPrice: 50.0,
        availableSizes: [],
        description: 'desc',
        totalStock: 999,
        variants: [
          ProductVariant(id: 'v1', sku: 'SKU-S', size: 'S', stock: 3),
          ProductVariant(id: 'v2', sku: 'SKU-M', size: 'M', stock: 0),
        ],
      );

      expect(withVariants.hasVariants, isTrue);
      expect(withVariants.stockQuantity, 3);
      expect(withVariants.isInStock, isTrue);
    });

    test('isInStock is false only when tracked stock is exactly zero', () {
      const outOfStock = Product(
        id: 'p5',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Sold Out',
        category: 'Shoes',
        currentPrice: 50.0,
        availableSizes: [],
        description: 'desc',
        totalStock: 0,
      );
      expect(outOfStock.isInStock, isFalse);
    });

    test('round-trips a seller-owned product with variants and status', () {
      const sellerProduct = Product(
        id: 'p6',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Seller Shoe',
        category: 'Shoes',
        currentPrice: 60.0,
        availableSizes: [],
        description: 'desc',
        sellerId: 'seller-1',
        status: ProductStatus.pendingApproval,
        sku: 'BASE-SKU',
        images: ['https://example.com/a.jpg'],
        variants: [
          ProductVariant(id: 'v1', sku: 'SKU-M', size: 'M', stock: 5, priceOverride: 65.0),
        ],
      );

      final restored = Product.fromMap(sellerProduct.toMap());

      expect(restored, equals(sellerProduct));
      expect(restored.isOwnedByAdmin, isFalse);
      expect(restored.variants.single.effectivePrice(restored.currentPrice), 65.0);
    });
  });
}
