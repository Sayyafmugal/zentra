import 'package:cloud_firestore/cloud_firestore.dart';
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

  Product buildProduct(String id) {
    return Product(
      id: id,
      imagePath: 'assets/images/shoe.jpg',
      name: 'Product $id',
      category: 'Shoes',
      currentPrice: 10.0,
      availableSizes: const ['M'],
      description: 'desc',
    );
  }

  Future<void> seedOrdered(int count) async {
    // fake_cloud_firestore orders createdAt ties by insertion when the
    // timestamps are identical, so seed with explicit, increasing timestamps
    // rather than relying on FieldValue.serverTimestamp() (unsupported by
    // fake_cloud_firestore in a way that preserves ordering here).
    for (var i = 0; i < count; i++) {
      await firestore.collection('products').doc('p$i').set({
        ...buildProduct('p$i').toMap(),
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1).add(Duration(minutes: i))),
      });
    }
  }

  test('fetchProductsPage returns only the requested page size, newest first', () async {
    await seedOrdered(5);

    final page = await repository.fetchProductsPage(limit: 2);

    expect(page.products, hasLength(2));
    expect(page.products.map((p) => p.id), ['p4', 'p3']);
    expect(page.hasMore, isTrue);
  });

  test('hasMore is false once every product has been returned', () async {
    await seedOrdered(3);

    final page = await repository.fetchProductsPage(limit: 10);

    expect(page.products, hasLength(3));
    expect(page.hasMore, isFalse);
  });

  test('startAfter continues from the previous page without repeating or skipping', () async {
    await seedOrdered(5);

    final firstPage = await repository.fetchProductsPage(limit: 2);
    final secondPage = await repository.fetchProductsPage(
      limit: 2,
      startAfter: firstPage.lastDocument,
    );
    final thirdPage = await repository.fetchProductsPage(
      limit: 2,
      startAfter: secondPage.lastDocument,
    );

    expect(firstPage.products.map((p) => p.id), ['p4', 'p3']);
    expect(secondPage.products.map((p) => p.id), ['p2', 'p1']);
    expect(secondPage.hasMore, isTrue);
    expect(thirdPage.products.map((p) => p.id), ['p0']);
    expect(thirdPage.hasMore, isFalse);
  });

  test('an empty collection yields an empty, exhausted first page', () async {
    final page = await repository.fetchProductsPage(limit: 20);

    expect(page.products, isEmpty);
    expect(page.hasMore, isFalse);
  });
}
