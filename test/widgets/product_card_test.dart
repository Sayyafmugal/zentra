import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/widgets/product_card.dart';

void main() {
  const product = Product(
    id: 'p1',
    imagePath: 'assets/images/shoe.jpg',
    name: 'Air Runner Classic',
    category: 'Shoes',
    currentPrice: 89.99,
    oldPrice: 119.99,
    discount: '25% OFF',
    availableSizes: ['M'],
    description: 'desc',
    rating: 4.5,
  );

  // Real usage always constrains ProductCard to a grid cell (~180x260,
  // matching the app's crossAxisCount/childAspectRatio grids) — rendering it
  // at the full test-viewport width would make the image alone taller than
  // the test screen, which is a test-harness artifact, not a real overflow.
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: 180, height: 260, child: child),
      ),
    ),
  );

  testWidgets('renders product name, price, and discount badge', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProductCard(product: product, onTap: () {}, onToggleWishlist: () {}, isWishlisted: false),
      ),
    );

    expect(find.text('Air Runner Classic'), findsOneWidget);
    expect(find.text('\$89.99'), findsOneWidget);
    expect(find.text('25% OFF'), findsOneWidget);
  });

  testWidgets('tapping the card invokes onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(
        ProductCard(
          product: product,
          onTap: () => tapped = true,
          onToggleWishlist: () {},
          isWishlisted: false,
        ),
      ),
    );

    await tester.tap(find.text('Air Runner Classic'));
    expect(tapped, isTrue);
  });

  testWidgets('shows a filled heart when wishlisted, outline otherwise', (tester) async {
    await tester.pumpWidget(
      wrap(
        ProductCard(product: product, onTap: () {}, onToggleWishlist: () {}, isWishlisted: true),
      ),
    );
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    await tester.pumpWidget(
      wrap(
        ProductCard(product: product, onTap: () {}, onToggleWishlist: () {}, isWishlisted: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
  });

  testWidgets('tapping the wishlist icon invokes onToggleWishlist without triggering onTap', (
    tester,
  ) async {
    var wishlistToggled = false;
    var cardTapped = false;
    await tester.pumpWidget(
      wrap(
        ProductCard(
          product: product,
          onTap: () => cardTapped = true,
          onToggleWishlist: () => wishlistToggled = true,
          isWishlisted: false,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.favorite_border));

    expect(wishlistToggled, isTrue);
    expect(cardTapped, isFalse);
  });
}
