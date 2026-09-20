import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/cart_controller.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/repositories/cart_repository.dart';

class MockCartRepository extends Mock implements CartRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

const _product = Product(
  id: 'p1',
  imagePath: 'assets/images/shoe.jpg',
  name: 'Air Runner',
  category: 'Shoes',
  currentPrice: 20.0,
  availableSizes: ['M', 'L'],
  description: 'desc',
);

void main() {
  Get.testMode = true;

  late MockCartRepository repository;
  late MockFirebaseAuth auth;
  late MockUser user;
  late CartController controller;

  setUpAll(() {
    registerFallbackValue(
      const CartItem(
        id: 'fallback',
        product: _product,
        quantity: 1,
        selectedSize: 'M',
        userId: 'u1',
      ),
    );
  });

  setUp(() {
    repository = MockCartRepository();
    auth = MockFirebaseAuth();
    user = MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
    when(() => repository.newCartItemId()).thenReturn('c1');
    when(() => repository.fetchCartItems(any())).thenAnswer((_) async => []);

    controller = CartController(repository: repository, auth: auth);
  });

  group('CartController totals', () {
    test('totalPrice and totalItems are zero for an empty cart', () {
      expect(controller.totalPrice, 0.0);
      expect(controller.totalItems, 0);
    });

    test('totalPrice sums each line item price * quantity', () {
      controller.cartItems.addAll([
        const CartItem(id: 'c1', product: _product, quantity: 2, selectedSize: 'M', userId: 'u1'),
        const CartItem(id: 'c2', product: _product, quantity: 1, selectedSize: 'L', userId: 'u1'),
      ]);

      expect(controller.totalPrice, 60.0); // (20*2) + (20*1)
      expect(controller.totalItems, 3);
    });
  });

  // addToCart shows a Get.snackbar on success, which needs a real overlay to
  // attach to — so this group runs under testWidgets with a pumped
  // GetMaterialApp rather than a bare `test()`.
  group('CartController.addToCart', () {
    testWidgets('adds a new line item and calls the repository once', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      when(() => repository.addCartItem(any())).thenAnswer((_) async {});

      final error = await controller.addToCart(product: _product, selectedSize: 'M');
      // Let the snackbar's entrance animation and auto-dismiss timer both
      // run to completion so no pending Timer trips the test teardown check.
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      expect(controller.cartItems, hasLength(1));
      expect(controller.cartItems.first.quantity, 1);
      verify(() => repository.addCartItem(any())).called(1);
    });

    testWidgets('increments quantity instead of duplicating when size+product already in cart', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      when(() => repository.addCartItem(any())).thenAnswer((_) async {});
      when(() => repository.updateQuantity(any(), any())).thenAnswer((_) async {});

      await controller.addToCart(product: _product, selectedSize: 'M');
      await controller.addToCart(product: _product, selectedSize: 'M');
      // Let the snackbar's entrance animation and auto-dismiss timer both
      // run to completion so no pending Timer trips the test teardown check.
      await tester.pump(const Duration(seconds: 5));

      expect(controller.cartItems, hasLength(1));
      expect(controller.cartItems.first.quantity, 2);
      verify(() => repository.addCartItem(any())).called(1);
      verify(() => repository.updateQuantity(any(), 2)).called(1);
    });
  });

  group('CartController.updateCartItemQuantity', () {
    testWidgets('removes the item instead when the new quantity is zero or less', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      controller.cartItems.add(
        const CartItem(id: 'c1', product: _product, quantity: 1, selectedSize: 'M', userId: 'u1'),
      );
      when(() => repository.removeCartItem(any())).thenAnswer((_) async {});

      await controller.updateCartItemQuantity('c1', 0);
      await tester.pump(const Duration(seconds: 5));

      expect(controller.cartItems, isEmpty);
      verify(() => repository.removeCartItem('c1')).called(1);
    });
  });
}
