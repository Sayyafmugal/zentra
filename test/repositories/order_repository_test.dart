import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/order.dart';
import 'package:zentra_0/repositories/order_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late OrderRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = OrderRepository(firestore: firestore);
  });

  Order buildOrder({
    String id = 'o1',
    String userId = 'u1',
    OrderStatus status = OrderStatus.pendingPayment,
  }) {
    return Order(
      id: id,
      userId: userId,
      items: const [
        OrderItem(
          productId: 'p1',
          productName: 'Air Runner',
          imagePath: 'assets/images/shoe.jpg',
          price: 50.0,
          quantity: 1,
          selectedSize: 'M',
        ),
      ],
      totalAmount: 50.0,
      status: status,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('createOrder then fetchOrders returns only that user\'s orders', () async {
    await repository.createOrder(buildOrder(id: 'o1', userId: 'u1'));
    await repository.createOrder(buildOrder(id: 'o2', userId: 'u2'));

    final ordersForU1 = await repository.fetchOrders('u1');

    expect(ordersForU1, hasLength(1));
    expect(ordersForU1.first.id, 'o1');
  });

  test('updateOrderStatus is reflected in a subsequent getOrderById', () async {
    await repository.createOrder(buildOrder());

    await repository.updateOrderStatus('o1', OrderStatus.shipped);
    final order = await repository.getOrderById('o1');

    expect(order?.status, OrderStatus.shipped);
  });

  test('deleteOrder removes the order from later fetches', () async {
    await repository.createOrder(buildOrder());
    await repository.deleteOrder('o1');

    final orders = await repository.fetchOrders('u1');
    expect(orders, isEmpty);
  });

  test('countAllOrders counts every order regardless of which user placed it', () async {
    await repository.createOrder(buildOrder(id: 'o1', userId: 'u1'));
    await repository.createOrder(buildOrder(id: 'o2', userId: 'u2'));
    await repository.createOrder(buildOrder(id: 'o3', userId: 'u1'));

    final count = await repository.countAllOrders();

    expect(count, 3);
  });

  test('getOrderById returns null when the order does not exist', () async {
    final result = await repository.getOrderById('missing');
    expect(result, isNull);
  });
}
