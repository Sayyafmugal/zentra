import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/order.dart';

void main() {
  group('Order', () {
    final createdAt = DateTime(2026, 1, 15, 10, 30);
    final order = Order(
      id: 'o1',
      userId: 'u1',
      items: const [
        OrderItem(
          productId: 'p1',
          productName: 'Air Runner',
          imagePath: 'assets/images/shoe.jpg',
          price: 89.99,
          quantity: 2,
          selectedSize: 'M',
        ),
      ],
      totalAmount: 179.98,
      status: OrderStatus.pendingPayment,
      shippingAddress: '123 Main St',
      paymentMethod: 'Visa (**** 4242)',
      createdAt: createdAt,
    );

    test('round-trips through toMap/fromMap preserving items and timestamps', () {
      // toMap() produces a Firestore Timestamp for createdAt, so fromMap must
      // accept that shape directly (as Firestore itself would return it).
      final map = order.toMap();
      expect(map['createdAt'], isA<Timestamp>());

      final restored = Order.fromMap(map);
      expect(restored.id, order.id);
      expect(restored.items.length, 1);
      expect(restored.items.first.productName, 'Air Runner');
      expect(restored.totalAmount, order.totalAmount);
      expect(restored.status, OrderStatus.pendingPayment);
      expect(restored.createdAt, createdAt);
    });

    test('statusString and statusColor are consistent per status', () {
      expect(order.statusString, 'Pending Payment');
      final shipped = order.copyWith(status: OrderStatus.shipped);
      expect(shipped.statusString, 'Shipped');
    });

    test('copyWith updates status and updatedAt without mutating original', () {
      final now = DateTime.now();
      final updated = order.copyWith(status: OrderStatus.delivered, updatedAt: now);
      expect(updated.status, OrderStatus.delivered);
      expect(updated.updatedAt, now);
      expect(order.status, OrderStatus.pendingPayment, reason: 'original should be unchanged');
    });

    test('fromMap defaults to pendingPayment for an unrecognized status string', () {
      final map = order.toMap();
      map['status'] = 'not-a-real-status';
      final restored = Order.fromMap(map);
      expect(restored.status, OrderStatus.pendingPayment);
    });

    test('fromMap maps the old pre-upgrade "pending" status onto pendingPayment', () {
      // Orders placed before the status enum was expanded were written with
      // the bare string 'pending' — those documents must keep decoding to a
      // sensible status rather than silently falling back to a default.
      final map = order.toMap();
      map['status'] = 'pending';
      final restored = Order.fromMap(map);
      expect(restored.status, OrderStatus.pendingPayment);
    });

    test('defaults paymentStatus to pending and subtotal to totalAmount when absent', () {
      final map = order.toMap();
      map.remove('paymentStatus');
      map.remove('subtotal');
      final restored = Order.fromMap(map);
      expect(restored.paymentStatus, PaymentStatus.pending);
      expect(restored.subtotal, order.totalAmount);
    });
  });

  group('order status transitions', () {
    test('allows the documented happy path', () {
      expect(isValidOrderStatusTransition(OrderStatus.pendingPayment, OrderStatus.paid), isTrue);
      expect(isValidOrderStatusTransition(OrderStatus.paid, OrderStatus.processing), isTrue);
      expect(isValidOrderStatusTransition(OrderStatus.shipped, OrderStatus.delivered), isTrue);
    });

    test('rejects skipping straight to a terminal state', () {
      expect(
        isValidOrderStatusTransition(OrderStatus.pendingPayment, OrderStatus.delivered),
        isFalse,
      );
    });

    test('rejects any transition out of a terminal state', () {
      expect(isValidOrderStatusTransition(OrderStatus.delivered, OrderStatus.processing), isFalse);
      expect(isValidOrderStatusTransition(OrderStatus.cancelled, OrderStatus.paid), isFalse);
    });
  });
}
