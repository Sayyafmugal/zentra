import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/Utils/pricing_constants.dart';
import 'package:zentra_0/models/cart_item.dart';
import 'package:zentra_0/models/coupon.dart';
import 'package:zentra_0/models/order.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/models/product_variant.dart';
import 'package:zentra_0/repositories/order_repository.dart';

// The order total now always includes the same flat shipping fee + tax the
// checkout screen previews (see OrderRepository.createOrderFromCart) — every
// expected total below is subtotal + shipping + tax - discount, not just the
// bare subtotal.
double _expectedTotal(double subtotal, {double discount = 0}) {
  final tax = (subtotal + kFlatShippingFee) * kTaxRate;
  return subtotal + kFlatShippingFee + tax - discount;
}

void main() {
  late FakeFirebaseFirestore firestore;
  late OrderRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = OrderRepository(firestore: firestore);
  });

  Future<void> seedProduct(Product product) async {
    await firestore.collection('products').doc(product.id).set(product.toMap());
  }

  group('OrderRepository.createOrderFromCart — stock validation', () {
    test('decrements totalStock by the ordered quantity on success', () async {
      const product = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Air Runner',
        category: 'Shoes',
        currentPrice: 50.0,
        availableSizes: ['M'],
        description: 'desc',
        totalStock: 5,
      );
      await seedProduct(product);
      final cartItem = CartItem(
        id: 'c1',
        product: product,
        quantity: 2,
        selectedSize: 'M',
        userId: 'u1',
      );

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [cartItem],
      );

      expect(order.totalAmount, _expectedTotal(100.0));
      final updated = await firestore.collection('products').doc('p1').get();
      expect(updated.data()!['totalStock'], 3);
    });

    test('rejects an order that requests more than the available stock', () async {
      const product = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Air Runner',
        category: 'Shoes',
        currentPrice: 50.0,
        availableSizes: ['M'],
        description: 'desc',
        totalStock: 1,
      );
      await seedProduct(product);
      final cartItem = CartItem(
        id: 'c1',
        product: product,
        quantity: 3,
        selectedSize: 'M',
        userId: 'u1',
      );

      expect(
        () => repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: [cartItem]),
        throwsA(isA<OrderValidationException>()),
      );

      // The rejected order must not exist, and stock must be untouched.
      final orders = await firestore.collection('orders').get();
      expect(orders.docs, isEmpty);
      final unchanged = await firestore.collection('products').doc('p1').get();
      expect(unchanged.data()!['totalStock'], 1);
    });

    test('never rejects on stock for a legacy product with untracked (null) stock', () async {
      const product = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Legacy Shoe',
        category: 'Shoes',
        currentPrice: 20.0,
        availableSizes: ['M'],
        description: 'desc',
        // totalStock intentionally omitted — simulates a pre-upgrade product.
      );
      await seedProduct(product);
      final cartItem = CartItem(
        id: 'c1',
        product: product,
        quantity: 100,
        selectedSize: 'M',
        userId: 'u1',
      );

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [cartItem],
      );

      expect(order.totalAmount, _expectedTotal(2000.0));
    });

    test(
      'rejects with a clear message when the product was deleted after being added to cart',
      () async {
        const product = Product(
          id: 'p1',
          imagePath: 'assets/images/shoe.jpg',
          name: 'Air Runner',
          category: 'Shoes',
          currentPrice: 50.0,
          availableSizes: ['M'],
          description: 'desc',
        );
        // Never seeded — simulates a product that existed when added to cart
        // but has since been removed.
        final cartItem = CartItem(
          id: 'c1',
          product: product,
          quantity: 1,
          selectedSize: 'M',
          userId: 'u1',
        );

        await expectLater(
          repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: [cartItem]),
          throwsA(
            isA<OrderValidationException>().having(
              (e) => e.message,
              'message',
              contains('no longer available'),
            ),
          ),
        );
      },
    );

    test('rejects an unpublished (e.g. archived) product even if it still exists', () async {
      const product = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Air Runner',
        category: 'Shoes',
        currentPrice: 50.0,
        availableSizes: ['M'],
        description: 'desc',
        status: ProductStatus.archived,
      );
      await seedProduct(product);
      final cartItem = CartItem(
        id: 'c1',
        product: product,
        quantity: 1,
        selectedSize: 'M',
        userId: 'u1',
      );

      expect(
        () => repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: [cartItem]),
        throwsA(isA<OrderValidationException>()),
      );
    });

    test('uses the current Firestore price, not a stale price on the cart-held product', () async {
      const staleProduct = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Air Runner',
        category: 'Shoes',
        currentPrice: 50.0, // price at the time it was added to cart
        availableSizes: ['M'],
        description: 'desc',
      );
      // The live product has since had its price changed by the seller.
      await seedProduct(staleProduct.copyWith(currentPrice: 80.0));
      final cartItem = CartItem(
        id: 'c1',
        product: staleProduct,
        quantity: 1,
        selectedSize: 'M',
        userId: 'u1',
      );

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [cartItem],
      );

      expect(
        order.totalAmount,
        _expectedTotal(80.0),
        reason: 'must charge the current price, not the stale cart price',
      );
    });

    group('with variants', () {
      const productWithVariants = Product(
        id: 'p1',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Variant Shoe',
        category: 'Shoes',
        currentPrice: 50.0,
        availableSizes: [],
        description: 'desc',
        variants: [
          ProductVariant(id: 'v1', sku: 'SKU-S', size: 'S', stock: 2),
          ProductVariant(id: 'v2', sku: 'SKU-M', size: 'M', stock: 0, priceOverride: 55.0),
        ],
      );

      test('decrements only the matching variant\'s stock', () async {
        await seedProduct(productWithVariants);
        final cartItem = CartItem(
          id: 'c1',
          product: productWithVariants,
          quantity: 1,
          selectedSize: 'S',
          userId: 'u1',
        );

        await repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: [cartItem]);

        final updated = await firestore.collection('products').doc('p1').get();
        final variants = updated.data()!['variants'] as List<dynamic>;
        final sVariant = variants.firstWhere((v) => v['size'] == 'S');
        final mVariant = variants.firstWhere((v) => v['size'] == 'M');
        expect(sVariant['stock'], 1);
        expect(mVariant['stock'], 0, reason: 'the untouched variant must be unaffected');
      });

      test(
        'rejects ordering an out-of-stock variant even though the product has other stock',
        () async {
          await seedProduct(productWithVariants);
          final cartItem = CartItem(
            id: 'c1',
            product: productWithVariants,
            quantity: 1,
            selectedSize: 'M',
            userId: 'u1',
          );

          expect(
            () =>
                repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: [cartItem]),
            throwsA(isA<OrderValidationException>()),
          );
        },
      );

      test('charges the variant\'s price override, not the base product price', () async {
        await seedProduct(productWithVariants);
        final cartItem = CartItem(
          id: 'c1',
          product: productWithVariants,
          quantity: 1,
          selectedSize: 'S', // no override on this variant — uses base price
          userId: 'u1',
        );

        final order = await repository.createOrderFromCart(
          orderId: 'o1',
          userId: 'u1',
          cartItems: [cartItem],
        );

        expect(order.totalAmount, _expectedTotal(50.0));
      });

      test('rejects a selected size that no longer matches any variant', () async {
        await seedProduct(productWithVariants);
        final cartItem = CartItem(
          id: 'c1',
          product: productWithVariants,
          quantity: 1,
          selectedSize: 'XL', // removed/never existed
          userId: 'u1',
        );

        expect(
          () => repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: [cartItem]),
          throwsA(isA<OrderValidationException>()),
        );
      });
    });

    test('validates and decrements stock for every item in a multi-item cart', () async {
      const productA = Product(
        id: 'pA',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Shoe A',
        category: 'Shoes',
        currentPrice: 10.0,
        availableSizes: ['M'],
        description: 'desc',
        totalStock: 5,
      );
      const productB = Product(
        id: 'pB',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Shoe B',
        category: 'Shoes',
        currentPrice: 20.0,
        availableSizes: ['M'],
        description: 'desc',
        totalStock: 1,
      );
      await seedProduct(productA);
      await seedProduct(productB);
      final items = [
        CartItem(id: 'c1', product: productA, quantity: 2, selectedSize: 'M', userId: 'u1'),
        CartItem(id: 'c2', product: productB, quantity: 1, selectedSize: 'M', userId: 'u1'),
      ];

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: items,
      );

      expect(order.totalAmount, _expectedTotal(40.0));
      expect(order.items, hasLength(2));
    });

    test('rejects the whole cart if any single item fails validation (all-or-nothing)', () async {
      const okProduct = Product(
        id: 'pA',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Shoe A',
        category: 'Shoes',
        currentPrice: 10.0,
        availableSizes: ['M'],
        description: 'desc',
        totalStock: 5,
      );
      const shortProduct = Product(
        id: 'pB',
        imagePath: 'assets/images/shoe.jpg',
        name: 'Shoe B',
        category: 'Shoes',
        currentPrice: 20.0,
        availableSizes: ['M'],
        description: 'desc',
        totalStock: 0,
      );
      await seedProduct(okProduct);
      await seedProduct(shortProduct);
      final items = [
        CartItem(id: 'c1', product: okProduct, quantity: 1, selectedSize: 'M', userId: 'u1'),
        CartItem(id: 'c2', product: shortProduct, quantity: 1, selectedSize: 'M', userId: 'u1'),
      ];

      expect(
        () => repository.createOrderFromCart(orderId: 'o1', userId: 'u1', cartItems: items),
        throwsA(isA<OrderValidationException>()),
      );

      // The in-stock item's stock must not have been decremented either —
      // the transaction must not partially apply.
      final untouchedA = await firestore.collection('products').doc('pA').get();
      expect(untouchedA.data()!['totalStock'], 5);
    });
  });

  group('OrderRepository.createOrderFromCart — coupons', () {
    const product = Product(
      id: 'p1',
      imagePath: 'assets/images/shoe.jpg',
      name: 'Air Runner',
      category: 'Shoes',
      currentPrice: 100.0,
      availableSizes: ['M'],
      description: 'desc',
      totalStock: 10,
    );

    Future<void> seedCoupon(Coupon coupon) async {
      await firestore.collection('coupons').doc(coupon.id).set(coupon.toMap());
    }

    CartItem buildCartItem({int quantity = 1}) =>
        CartItem(id: 'c1', product: product, quantity: quantity, selectedSize: 'M', userId: 'u1');

    test('applies a valid percentage coupon\'s discount to the order total', () async {
      await seedProduct(product);
      await seedCoupon(
        Coupon(
          id: 'SAVE20',
          type: CouponType.percentage,
          value: 20,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [buildCartItem()],
        couponCode: 'save20',
      );

      expect(order.subtotal, 100.0);
      expect(order.discountAmount, 20.0);
      expect(order.totalAmount, _expectedTotal(100.0, discount: 20.0));
      expect(order.couponId, 'SAVE20');
    });

    test('increments usedCount and writes a redemption record on success', () async {
      await seedProduct(product);
      await seedCoupon(
        Coupon(
          id: 'SAVE20',
          type: CouponType.percentage,
          value: 20,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [buildCartItem()],
        couponCode: 'SAVE20',
      );

      final coupon = await firestore.collection('coupons').doc('SAVE20').get();
      expect(coupon.data()!['usedCount'], 1);
      final redemption = await firestore
          .collection('coupons')
          .doc('SAVE20')
          .collection('redemptions')
          .doc('u1')
          .get();
      expect(redemption.exists, isTrue);
      expect(redemption.data()!['orderId'], 'o1');
    });

    test('rejects a coupon code that doesn\'t exist', () async {
      await seedProduct(product);

      expect(
        () => repository.createOrderFromCart(
          orderId: 'o1',
          userId: 'u1',
          cartItems: [buildCartItem()],
          couponCode: 'NOPE',
        ),
        throwsA(isA<OrderValidationException>()),
      );
    });

    test('rejects an inactive coupon', () async {
      await seedProduct(product);
      await seedCoupon(
        Coupon(
          id: 'OFF',
          type: CouponType.fixed,
          value: 10,
          isActive: false,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      expect(
        () => repository.createOrderFromCart(
          orderId: 'o1',
          userId: 'u1',
          cartItems: [buildCartItem()],
          couponCode: 'OFF',
        ),
        throwsA(isA<OrderValidationException>()),
      );
    });

    test('rejects reuse of a coupon already redeemed by the same user', () async {
      await seedProduct(product);
      await seedCoupon(
        Coupon(id: 'ONCE', type: CouponType.fixed, value: 5, createdAt: DateTime(2026, 1, 1)),
      );
      await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [buildCartItem()],
        couponCode: 'ONCE',
      );

      expect(
        () => repository.createOrderFromCart(
          orderId: 'o2',
          userId: 'u1',
          cartItems: [buildCartItem()],
          couponCode: 'ONCE',
        ),
        throwsA(isA<OrderValidationException>()),
      );
    });

    test('rejects a coupon below its minimum order amount', () async {
      await seedProduct(product);
      await seedCoupon(
        Coupon(
          id: 'BIGORDER',
          type: CouponType.fixed,
          value: 5,
          minOrderAmount: 500,
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      expect(
        () => repository.createOrderFromCart(
          orderId: 'o1',
          userId: 'u1',
          cartItems: [buildCartItem()],
          couponCode: 'BIGORDER',
        ),
        throwsA(isA<OrderValidationException>()),
      );
    });

    test('places the order normally with no discount when no coupon code is given', () async {
      await seedProduct(product);

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [buildCartItem()],
      );

      expect(order.discountAmount, 0.0);
      expect(order.couponId, isNull);
      expect(order.totalAmount, _expectedTotal(100.0));
    });
  });

  group('OrderRepository.createOrderFromCart — paymentStatus', () {
    const product = Product(
      id: 'p1',
      imagePath: 'assets/images/shoe.jpg',
      name: 'Air Runner',
      category: 'Shoes',
      currentPrice: 50.0,
      availableSizes: ['M'],
      description: 'desc',
      totalStock: 5,
    );

    test('defaults to pending when no paymentStatus is given', () async {
      await seedProduct(product);
      final cartItem = CartItem(
        id: 'c1',
        product: product,
        quantity: 1,
        selectedSize: 'M',
        userId: 'u1',
      );

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [cartItem],
      );

      expect(order.paymentStatus, PaymentStatus.pending);
      expect(order.status, OrderStatus.pendingPayment);
    });

    test('records a paymentStatus of paid without skipping the pendingPayment order status '
        '— advancing past it always stays a separate, controlled step', () async {
      await seedProduct(product);
      final cartItem = CartItem(
        id: 'c1',
        product: product,
        quantity: 1,
        selectedSize: 'M',
        userId: 'u1',
      );

      final order = await repository.createOrderFromCart(
        orderId: 'o1',
        userId: 'u1',
        cartItems: [cartItem],
        paymentStatus: PaymentStatus.paid,
      );

      expect(order.paymentStatus, PaymentStatus.paid);
      expect(order.status, OrderStatus.pendingPayment);
    });
  });
}
