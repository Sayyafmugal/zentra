import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/order.dart';

void main() {
  group('Order seller split', () {
    final multiSellerOrder = Order(
      id: 'o1',
      userId: 'u1',
      items: const [
        OrderItem(
          productId: 'p1',
          productName: 'Shoe A',
          imagePath: 'assets/images/shoe.jpg',
          price: 10.0,
          quantity: 1,
          selectedSize: 'M',
          sellerId: 'sellerA',
        ),
        OrderItem(
          productId: 'p2',
          productName: 'Shoe B',
          imagePath: 'assets/images/shoe.jpg',
          price: 20.0,
          quantity: 1,
          selectedSize: 'M',
          sellerId: 'sellerB',
        ),
      ],
      totalAmount: 30.0,
      status: OrderStatus.processing,
      createdAt: DateTime(2026, 1, 1),
    );

    test('toMap stores a denormalized sellerIds array derived from items', () {
      final map = multiSellerOrder.toMap();
      expect(map['sellerIds'], containsAll(['sellerA', 'sellerB']));
      expect((map['sellerIds'] as List).length, 2);
    });

    test('sellerIds is always recomputed from items on decode, ignoring a stale stored value', () {
      final map = multiSellerOrder.toMap();
      // Simulate a document where the denormalized field somehow drifted —
      // decoding must not trust it.
      map['sellerIds'] = ['someone-else'];

      final restored = Order.fromMap(map);
      expect(restored.sellerIds, {'sellerA', 'sellerB'});
    });

    test('itemsForSeller returns only that seller\'s line items', () {
      final aItems = multiSellerOrder.itemsForSeller('sellerA');
      expect(aItems, hasLength(1));
      expect(aItems.first.productName, 'Shoe A');
    });

    test('a single-seller order has exactly one entry in sellerIds', () {
      final singleSellerOrder = multiSellerOrder.copyWith();
      final onlyA = Order(
        id: 'o2',
        userId: 'u1',
        items: multiSellerOrder.items.where((i) => i.sellerId == 'sellerA').toList(),
        totalAmount: 10.0,
        status: OrderStatus.processing,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(onlyA.sellerIds, {'sellerA'});
      expect(singleSellerOrder.sellerIds.length, 2);
    });
  });

  group('isValidSellerOrderTransition', () {
    test('allows the fulfillment-only happy path', () {
      expect(isValidSellerOrderTransition(OrderStatus.processing, OrderStatus.packed), isTrue);
      expect(isValidSellerOrderTransition(OrderStatus.packed, OrderStatus.shipped), isTrue);
      expect(isValidSellerOrderTransition(OrderStatus.shipped, OrderStatus.delivered), isTrue);
    });

    test('rejects financial transitions even though they are valid for admin', () {
      expect(isValidOrderStatusTransition(OrderStatus.pendingPayment, OrderStatus.paid), isTrue);
      expect(isValidSellerOrderTransition(OrderStatus.pendingPayment, OrderStatus.paid), isFalse);

      expect(isValidOrderStatusTransition(OrderStatus.paid, OrderStatus.refunded), isTrue);
      expect(isValidSellerOrderTransition(OrderStatus.paid, OrderStatus.refunded), isFalse);
    });

    test('rejects a seller cancelling an order', () {
      expect(isValidSellerOrderTransition(OrderStatus.processing, OrderStatus.cancelled), isFalse);
    });
  });
}
