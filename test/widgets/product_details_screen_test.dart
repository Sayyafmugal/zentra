import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/cart_controller.dart';
import 'package:zentra_0/Controllers/review_controller.dart';
import 'package:zentra_0/Controllers/wishlist_controller.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/models/product_variant.dart';
import 'package:zentra_0/repositories/cart_repository.dart';
import 'package:zentra_0/repositories/order_repository.dart';
import 'package:zentra_0/repositories/review_repository.dart';
import 'package:zentra_0/repositories/wishlist_repository.dart';
import 'package:zentra_0/view/product_details_screen.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockWishlistRepository extends Mock implements WishlistRepository {}

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

void main() {
  setUp(() {
    final auth = MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(null); // signed out — skips onInit fetches

    final reviewRepository = MockReviewRepository();
    when(() => reviewRepository.fetchReviewsForProduct(any())).thenAnswer((_) async => []);

    Get.put<CartController>(CartController(repository: MockCartRepository(), auth: auth));
    Get.put<WishlistController>(
      WishlistController(repository: MockWishlistRepository(), auth: auth),
    );
    Get.put<ReviewController>(
      ReviewController(
        reviewRepository: reviewRepository,
        orderRepository: MockOrderRepository(),
        auth: auth,
      ),
    );
  });

  tearDown(Get.reset);

  const productWithVariants = Product(
    id: 'p1',
    imagePath: 'assets/images/shoe.jpg',
    name: 'Variant Shoe',
    category: 'Shoes',
    currentPrice: 50.0,
    availableSizes: [],
    description: 'A shoe with tracked variants.',
    variants: [
      ProductVariant(id: 'v1', sku: 'SKU-S', size: 'S', stock: 0),
      ProductVariant(id: 'v2', sku: 'SKU-M', size: 'M', stock: 3, priceOverride: 65.0),
    ],
  );

  Widget wrap(Product product) => GetMaterialApp(home: ProductDetailsScreen(product: product));

  testWidgets('defaults to the first in-stock size, skipping a sold-out one', (tester) async {
    await tester.pumpWidget(wrap(productWithVariants));
    await tester.pump();

    // Size M (in stock) should be selected by default, not S (sold out).
    expect(find.text('Only 3 left in stock'), findsOneWidget);
  });

  testWidgets('shows the variant price override, not the base price', (tester) async {
    await tester.pumpWidget(wrap(productWithVariants));
    await tester.pump();

    expect(find.text('\$65.00'), findsOneWidget);
  });

  testWidgets('disables Add To Cart and Buy Now when every variant is sold out', (tester) async {
    const soldOut = Product(
      id: 'p2',
      imagePath: 'assets/images/shoe.jpg',
      name: 'Sold Out Shoe',
      category: 'Shoes',
      currentPrice: 30.0,
      availableSizes: [],
      description: 'desc',
      variants: [ProductVariant(id: 'v1', sku: 'SKU-S', size: 'S', stock: 0)],
    );

    await tester.pumpWidget(wrap(soldOut));
    await tester.pump();

    expect(find.text('Out of stock'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Out of Stock'), findsOneWidget);

    final addToCartButton = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    expect(addToCartButton.onPressed, isNull);
  });

  testWidgets('a simple product with only availableSizes (no variants) shows no stock indicator', (
    tester,
  ) async {
    const simpleProduct = Product(
      id: 'p3',
      imagePath: 'assets/images/shoe.jpg',
      name: 'Classic Shoe',
      category: 'Shoes',
      currentPrice: 40.0,
      availableSizes: ['S', 'M', 'L'],
      description: 'desc',
    );

    await tester.pumpWidget(wrap(simpleProduct));
    await tester.pump();

    expect(find.text('In stock'), findsNothing);
    expect(find.text('Out of stock'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Buy Now'), findsOneWidget);
  });
}
