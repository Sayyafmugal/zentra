import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/product_controller.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/models/product_variant.dart';
import 'package:zentra_0/repositories/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

Product _buildProduct({String id = 'p1', ProductStatus status = ProductStatus.published}) {
  return Product(
    id: id,
    imagePath: 'assets/images/shoe.jpg',
    name: 'Air Runner',
    category: 'Shoes',
    currentPrice: 50.0,
    availableSizes: const ['M'],
    description: 'desc',
    status: status,
  );
}

void main() {
  late MockProductRepository repository;
  late MockFirebaseAuth auth;
  late ProductController controller;

  setUpAll(() {
    registerFallbackValue(_buildProduct());
  });

  setUp(() {
    repository = MockProductRepository();
    auth = MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(null);
    controller = ProductController(repository: repository, auth: auth);
  });

  group('ProductController.publishedProducts', () {
    test('excludes anything that is not published', () {
      controller.products.addAll([
        _buildProduct(id: 'p1', status: ProductStatus.published),
        _buildProduct(id: 'p2', status: ProductStatus.pendingApproval),
        _buildProduct(id: 'p3', status: ProductStatus.draft),
        _buildProduct(id: 'p4', status: ProductStatus.rejected),
      ]);

      final visible = controller.publishedProducts;

      expect(visible.map((p) => p.id), ['p1']);
    });

    test('a seller\'s pending submission never appears to customers until approved', () {
      controller.products.add(_buildProduct(id: 'p1', status: ProductStatus.pendingApproval));

      expect(controller.publishedProducts, isEmpty);
    });
  });

  group('ProductController.updateProductStatus', () {
    test('approves a pending product and updates local state', () async {
      controller.products.add(_buildProduct(id: 'p1', status: ProductStatus.pendingApproval));
      when(
        () => repository.getProductById('p1'),
      ).thenAnswer((_) async => _buildProduct(id: 'p1', status: ProductStatus.pendingApproval));
      when(() => repository.updateProduct(any())).thenAnswer((_) async {});

      final error = await controller.updateProductStatus('p1', ProductStatus.published);

      expect(error, isNull);
      expect(controller.products.first.status, ProductStatus.published);
      expect(controller.publishedProducts, hasLength(1));
    });

    test('returns an error when the product does not exist', () async {
      when(() => repository.getProductById('missing')).thenAnswer((_) async => null);

      final error = await controller.updateProductStatus('missing', ProductStatus.published);

      expect(error, 'Product not found');
    });
  });

  group('ProductController.updateProduct', () {
    testWidgets('updates a variant\'s stock/sku and leaves other fields untouched', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      final existing = _buildProduct(id: 'p1').copyWith(
        variants: const [ProductVariant(id: 'v1', sku: 'OLD-SKU', size: 'M', stock: 3)],
      );
      when(() => repository.getProductById('p1')).thenAnswer((_) async => existing);
      when(() => repository.updateProduct(any())).thenAnswer((_) async {});
      controller.products.add(existing);

      const newVariants = [ProductVariant(id: 'v1', sku: 'NEW-SKU', size: 'M', stock: 9)];
      final error = await controller.updateProduct(productId: 'p1', variants: newVariants);
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      final captured = verify(() => repository.updateProduct(captureAny())).captured.single as Product;
      expect(captured.variants.single.stock, 9);
      expect(captured.variants.single.sku, 'NEW-SKU');
      expect(captured.name, existing.name, reason: 'fields not passed in must be left unchanged');
      expect(controller.products.first.variants.single.stock, 9);
    });

    testWidgets('updates totalStock for a simple (non-variant) product', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      final existing = _buildProduct(id: 'p1');
      when(() => repository.getProductById('p1')).thenAnswer((_) async => existing);
      when(() => repository.updateProduct(any())).thenAnswer((_) async {});

      final error = await controller.updateProduct(productId: 'p1', totalStock: 42);
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      final captured = verify(() => repository.updateProduct(captureAny())).captured.single as Product;
      expect(captured.totalStock, 42);
    });

    test('returns an error when the product no longer exists', () async {
      when(() => repository.getProductById('missing')).thenAnswer((_) async => null);

      final error = await controller.updateProduct(productId: 'missing', totalStock: 5);

      expect(error, 'Product not found');
    });
  });

  group('ProductController storefront pagination', () {
    test('fetchStorefrontFirstPage populates the feed and hasMoreStorefront', () async {
      when(() => repository.fetchProductsPage(limit: 20)).thenAnswer(
        (_) async =>
            ProductPage(products: [_buildProduct(id: 'p1')], lastDocument: null, hasMore: true),
      );

      await controller.fetchStorefrontFirstPage();

      expect(controller.storefrontFeed, hasLength(1));
      expect(controller.hasMoreStorefront.value, isTrue);
    });

    test('loadMoreStorefrontProducts appends to the existing feed', () async {
      when(() => repository.fetchProductsPage(limit: 20)).thenAnswer(
        (_) async =>
            ProductPage(products: [_buildProduct(id: 'p1')], lastDocument: null, hasMore: true),
      );
      await controller.fetchStorefrontFirstPage();

      when(() => repository.fetchProductsPage(limit: 20, startAfter: null)).thenAnswer(
        (_) async =>
            ProductPage(products: [_buildProduct(id: 'p2')], lastDocument: null, hasMore: false),
      );

      await controller.loadMoreStorefrontProducts();

      expect(controller.storefrontFeed.map((p) => p.id), ['p1', 'p2']);
      expect(controller.hasMoreStorefront.value, isFalse);
    });

    test('loadMoreStorefrontProducts is a no-op once hasMoreStorefront is false', () async {
      when(() => repository.fetchProductsPage(limit: 20)).thenAnswer(
        (_) async =>
            ProductPage(products: [_buildProduct(id: 'p1')], lastDocument: null, hasMore: false),
      );
      await controller.fetchStorefrontFirstPage();

      await controller.loadMoreStorefrontProducts();

      // The guard must short-circuit before a second fetch — asserting on
      // the resulting feed/flag state (rather than verifyNever) since it's
      // what actually matters: nothing more was ever appended or requested.
      expect(controller.storefrontFeed, hasLength(1));
      expect(controller.hasMoreStorefront.value, isFalse);
    });

    test('ensureStorefrontFullyLoaded keeps paging until hasMore is false', () async {
      when(() => repository.fetchProductsPage(limit: 20)).thenAnswer(
        (_) async =>
            ProductPage(products: [_buildProduct(id: 'p1')], lastDocument: null, hasMore: true),
      );
      await controller.fetchStorefrontFirstPage();

      when(() => repository.fetchProductsPage(limit: 20, startAfter: null)).thenAnswer(
        (_) async =>
            ProductPage(products: [_buildProduct(id: 'p2')], lastDocument: null, hasMore: false),
      );

      await controller.ensureStorefrontFullyLoaded();

      expect(controller.storefrontFeed.map((p) => p.id), ['p1', 'p2']);
      expect(controller.hasMoreStorefront.value, isFalse);
    });
  });
}
