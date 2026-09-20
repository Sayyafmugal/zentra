import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/repositories/product_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ProductRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ProductRepository(firestore: firestore);
  });

  const product = Product(
    id: 'p1',
    imagePath: 'assets/images/shoe.jpg',
    name: 'Air Runner',
    category: 'Shoes',
    currentPrice: 89.99,
    availableSizes: ['M'],
    description: 'desc',
  );

  test('createProduct then fetchProducts returns the created product', () async {
    await repository.createProduct(product);

    final products = await repository.fetchProducts();

    expect(products, hasLength(1));
    expect(products.first.id, 'p1');
    expect(products.first.name, 'Air Runner');
  });

  test('getProductById returns null for a missing product', () async {
    final result = await repository.getProductById('does-not-exist');
    expect(result, isNull);
  });

  test('updateProduct persists changes visible to a later fetch', () async {
    await repository.createProduct(product);
    final updated = product.copyWith(currentPrice: 59.99);

    await repository.updateProduct(updated);
    final fetched = await repository.getProductById('p1');

    expect(fetched?.currentPrice, 59.99);
  });

  test('deleteProduct removes the product from subsequent fetches', () async {
    await repository.createProduct(product);
    await repository.deleteProduct('p1');

    final products = await repository.fetchProducts();
    expect(products, isEmpty);
  });

  test('getProductsByCategory only returns matching products', () async {
    await repository.createProduct(product);
    await repository.createProduct(product.copyWith(id: 'p2', category: 'Watches'));

    final shoes = await repository.getProductsByCategory('Shoes');
    expect(shoes, hasLength(1));
    expect(shoes.first.id, 'p1');
  });

  test('seedProducts writes every product in the batch', () async {
    final seeds = [product, product.copyWith(id: 'p2', name: 'Second Product')];
    await repository.seedProducts(seeds);

    final products = await repository.fetchProducts();
    expect(products, hasLength(2));
  });

  test('fetchProductsBySeller only returns that seller\'s products', () async {
    await repository.createProduct(product.copyWith(id: 'p1', sellerId: 'seller-1'));
    await repository.createProduct(product.copyWith(id: 'p2', sellerId: 'seller-2'));

    final sellerProducts = await repository.fetchProductsBySeller('seller-1');

    expect(sellerProducts, hasLength(1));
    expect(sellerProducts.first.id, 'p1');
  });

  test('fetchProductsByStatus only returns products with a matching stored status', () async {
    await repository.createProduct(product.copyWith(id: 'p1', status: ProductStatus.draft));
    await repository.createProduct(product.copyWith(id: 'p2', status: ProductStatus.published));

    final drafts = await repository.fetchProductsByStatus(ProductStatus.draft);

    expect(drafts, hasLength(1));
    expect(drafts.first.id, 'p1');
  });

  test(
    'backfillMissingStatusField sets status on legacy documents without touching modern ones',
    () async {
      // Simulate a pre-upgrade document with no `status` key at all, written
      // directly (not through createProduct, which always writes one now).
      await firestore.collection('products').doc('legacy').set({
        ...product.toMap()..remove('status'),
        'id': 'legacy',
      });
      await repository.createProduct(product.copyWith(id: 'modern', status: ProductStatus.draft));

      await repository.backfillMissingStatusField();

      final legacy = await repository.getProductById('legacy');
      final modern = await repository.getProductById('modern');
      expect(legacy?.status, ProductStatus.published);
      expect(
        modern?.status,
        ProductStatus.draft,
        reason: 'backfill must not overwrite an explicit status',
      );
    },
  );
}
