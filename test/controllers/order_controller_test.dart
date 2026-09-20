import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/order_controller.dart';
import 'package:zentra_0/repositories/order_repository.dart';

class MockOrderRepository extends Mock implements OrderRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

Order _buildOrder({String id = 'o1', OrderStatus status = OrderStatus.pendingPayment}) {
  return Order(
    id: id,
    userId: 'u1',
    items: const [],
    totalAmount: 50.0,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

Order _buildOrderWithSellers({
  String id = 'o1',
  OrderStatus status = OrderStatus.processing,
  required List<String> sellerIds,
}) {
  return Order(
    id: id,
    userId: 'customer-1',
    items: sellerIds
        .map(
          (sellerId) => OrderItem(
            productId: 'p-$sellerId',
            productName: 'Item for $sellerId',
            imagePath: 'assets/images/shoe.jpg',
            price: 10.0,
            quantity: 1,
            selectedSize: 'M',
            sellerId: sellerId,
          ),
        )
        .toList(),
    totalAmount: 10.0 * sellerIds.length,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockOrderRepository repository;
  late MockFirebaseAuth auth;
  late OrderController controller;

  setUpAll(() {
    registerFallbackValue(OrderStatus.pendingPayment);
  });

  setUp(() {
    repository = MockOrderRepository();
    auth = MockFirebaseAuth();
    when(() => auth.currentUser).thenReturn(MockUser());
    controller = OrderController(repository: repository, auth: auth);
  });

  group('OrderController.updateOrderStatus', () {
    test('rejects an invalid transition without touching the repository', () async {
      controller.orders.add(_buildOrder(status: OrderStatus.pendingPayment));

      final error = await controller.updateOrderStatus('o1', OrderStatus.delivered);

      expect(error, isNotNull);
      verifyNever(() => repository.updateOrderStatus(any(), any()));
    });

    test('rejects any transition out of a terminal state', () async {
      controller.orders.add(_buildOrder(status: OrderStatus.delivered));

      final error = await controller.updateOrderStatus('o1', OrderStatus.processing);

      expect(error, isNotNull);
      verifyNever(() => repository.updateOrderStatus(any(), any()));
    });

    test('returns an error when the order cannot be found', () async {
      when(() => repository.getOrderById('missing')).thenAnswer((_) async => null);

      final error = await controller.updateOrderStatus('missing', OrderStatus.paid);

      expect(error, 'Order not found');
    });

    testWidgets('applies a valid transition and updates local state', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      controller.orders.add(_buildOrder(status: OrderStatus.pendingPayment));
      when(() => repository.updateOrderStatus(any(), any())).thenAnswer((_) async {});

      final error = await controller.updateOrderStatus('o1', OrderStatus.paid);
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      expect(controller.orders.first.status, OrderStatus.paid);
      verify(() => repository.updateOrderStatus('o1', OrderStatus.paid)).called(1);
    });
  });

  group('OrderController.updateOrderStatusAsSeller', () {
    test('refuses to touch an order that includes another seller\'s items', () async {
      controller.sellerOrders.add(_buildOrderWithSellers(sellerIds: ['sellerA', 'sellerB']));

      final error = await controller.updateOrderStatusAsSeller('o1', OrderStatus.packed, 'sellerA');

      expect(error, contains('another seller'));
      verifyNever(() => repository.updateOrderStatus(any(), any()));
    });

    test('rejects a transition outside the seller-allowed fulfillment set', () async {
      controller.sellerOrders.add(
        _buildOrderWithSellers(sellerIds: ['sellerA'], status: OrderStatus.pendingPayment),
      );

      // Sellers can't touch payment states even on their own single-seller order.
      final error = await controller.updateOrderStatusAsSeller('o1', OrderStatus.paid, 'sellerA');

      expect(error, isNotNull);
      verifyNever(() => repository.updateOrderStatus(any(), any()));
    });

    testWidgets('applies a valid fulfillment transition on a single-seller order', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      controller.sellerOrders.add(
        _buildOrderWithSellers(sellerIds: ['sellerA'], status: OrderStatus.processing),
      );
      when(() => repository.updateOrderStatus(any(), any())).thenAnswer((_) async {});

      final error = await controller.updateOrderStatusAsSeller('o1', OrderStatus.packed, 'sellerA');
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      expect(controller.sellerOrders.first.status, OrderStatus.packed);
      verify(() => repository.updateOrderStatus('o1', OrderStatus.packed)).called(1);
    });
  });

  group('OrderController.fetchSellerOrders', () {
    test('populates sellerOrders from the repository', () async {
      when(() => repository.fetchOrdersForSeller('sellerA')).thenAnswer(
        (_) async => [
          _buildOrderWithSellers(sellerIds: ['sellerA']),
        ],
      );

      await controller.fetchSellerOrders('sellerA');

      expect(controller.sellerOrders, hasLength(1));
    });
  });
}
