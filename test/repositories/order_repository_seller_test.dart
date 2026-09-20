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

  Future<void> seedOrder(String id, List<String> sellerIds) async {
    final order = Order(
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
      status: OrderStatus.processing,
      createdAt: DateTime(2026, 1, 1),
    );
    await firestore.collection('orders').doc(id).set(order.toMap());
  }

  test('fetchOrdersForSeller returns only orders containing that seller\'s items', () async {
    await seedOrder('o1', ['sellerA']);
    await seedOrder('o2', ['sellerB']);
    await seedOrder('o3', ['sellerA', 'sellerB']); // multi-seller order

    final sellerAOrders = await repository.fetchOrdersForSeller('sellerA');

    expect(sellerAOrders.map((o) => o.id).toSet(), {'o1', 'o3'});
  });

  test('returns an empty list for a seller with no orders', () async {
    await seedOrder('o1', ['sellerA']);

    final result = await repository.fetchOrdersForSeller('sellerC');

    expect(result, isEmpty);
  });
}
