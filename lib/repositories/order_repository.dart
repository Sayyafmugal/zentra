import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../Utils/pricing_constants.dart';
import '../models/cart_item.dart';
import '../models/coupon.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

/// Thrown by [OrderRepository.createOrderFromCart] when an item in the cart
/// can no longer be ordered as requested (deleted, unpublished, or short on
/// stock) — carries a message safe to show the customer directly.
class OrderValidationException implements Exception {
  OrderValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Wraps all Firestore access for the `orders` collection.
class OrderRepository {
  OrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _couponsCollection =>
      _firestore.collection('coupons');

  String newOrderId() => _collection.doc().id;

  Future<void> createOrder(Order order) async {
    await _collection.doc(order.id).set(order.toMap());
  }

  /// Creates an order from the given cart items with the product data,
  /// prices, stock, and (if provided) coupon eligibility all re-checked
  /// *inside a Firestore transaction* rather than trusted from the client —
  /// this is what actually prevents overselling when two customers check
  /// out the same limited item at once (whichever transaction commits first
  /// wins; the other re-reads the now-lower stock and fails with
  /// [OrderValidationException] instead of both succeeding), and what
  /// prevents a coupon being redeemed past its usage limit or twice by the
  /// same user under the same race condition.
  ///
  /// Every price in the resulting order comes from the product document
  /// read inside the transaction, never from [cartItems] — a stale or
  /// tampered cart price cannot make it into the order total.
  Future<Order> createOrderFromCart({
    required String orderId,
    required String userId,
    required List<CartItem> cartItems,
    String? shippingAddress,
    String? paymentMethod,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    String? couponCode,
  }) {
    return _firestore.runTransaction<Order>((transaction) async {
      // Firestore transactions require every read before any write, so the
      // product/coupon lookups all happen first, then validation, then the
      // stock decrements + coupon redemption + order creation writes.
      final freshProducts = <String, Product>{};
      for (final item in cartItems) {
        final snapshot = await transaction.get(_productsCollection.doc(item.product.id));
        if (!snapshot.exists) {
          throw OrderValidationException('${item.product.name} is no longer available.');
        }
        freshProducts[item.product.id] = Product.fromFirestore(snapshot);
      }

      Coupon? coupon;
      DocumentReference<Map<String, dynamic>>? redemptionRef;
      if (couponCode != null && couponCode.trim().isNotEmpty) {
        final normalized = Coupon.normalize(couponCode);
        final couponSnapshot = await transaction.get(_couponsCollection.doc(normalized));
        if (!couponSnapshot.exists) {
          throw OrderValidationException('Coupon "$normalized" doesn\'t exist.');
        }
        coupon = Coupon.fromFirestore(couponSnapshot);
        if (!coupon.isCurrentlyValid) {
          throw OrderValidationException('Coupon "$normalized" is no longer valid.');
        }
        redemptionRef = _couponsCollection.doc(normalized).collection('redemptions').doc(userId);
        final redemptionSnapshot = await transaction.get(redemptionRef);
        if (redemptionSnapshot.exists) {
          throw OrderValidationException('You\'ve already used coupon "$normalized".');
        }
      }

      final orderItems = <OrderItem>[];
      var subtotal = 0.0;

      for (final item in cartItems) {
        final product = freshProducts[item.product.id]!;

        if (!product.isPublished) {
          throw OrderValidationException('${product.name} is no longer available.');
        }

        ProductVariant? variant;
        int? availableStock;
        if (product.hasVariants) {
          variant = _findVariant(product, item.selectedSize);
          if (variant == null) {
            throw OrderValidationException(
              '${product.name} (${item.selectedSize}) is no longer available.',
            );
          }
          availableStock = variant.stock;
        } else {
          availableStock = product.totalStock;
        }

        if (availableStock != null && availableStock < item.quantity) {
          throw OrderValidationException(
            availableStock == 0
                ? '${product.name} (${item.selectedSize}) is out of stock.'
                : 'Only $availableStock of ${product.name} (${item.selectedSize}) left '
                      '— you requested ${item.quantity}.',
          );
        }

        final unitPrice = variant?.effectivePrice(product.currentPrice) ?? product.currentPrice;

        orderItems.add(
          OrderItem(
            productId: product.id,
            productName: product.name,
            imagePath: product.imagePath,
            price: unitPrice,
            quantity: item.quantity,
            selectedSize: item.selectedSize,
            sellerId: product.sellerId,
            sku: variant?.sku ?? product.sku ?? '',
          ),
        );
        subtotal += unitPrice * item.quantity;
      }

      var discountAmount = 0.0;
      if (coupon != null) {
        if (subtotal < coupon.minOrderAmount) {
          throw OrderValidationException(
            'Coupon "${coupon.id}" requires a minimum order of '
            '\$${coupon.minOrderAmount.toStringAsFixed(2)}.',
          );
        }
        discountAmount = coupon.discountFor(subtotal);
      }
      // Same flat-rate shipping/tax the checkout screen previews and
      // actually charges via PaymentService — computed here too (not just
      // trusted from the client) so the persisted order total always
      // matches what was really paid.
      final shippingFee = kFlatShippingFee;
      final taxAmount = (subtotal + shippingFee) * kTaxRate;
      final total = subtotal + shippingFee + taxAmount - discountAmount;

      // Every item passed validation — now decrement stock, redeem the
      // coupon (if any), and place the order as part of the same atomic
      // transaction.
      for (final item in cartItems) {
        final product = freshProducts[item.product.id]!;
        if (product.hasVariants) {
          final updatedVariants = product.variants.map((v) {
            if (v.size == item.selectedSize) return v.copyWith(stock: v.stock - item.quantity);
            return v;
          }).toList();
          transaction.update(_productsCollection.doc(product.id), {
            'variants': updatedVariants.map((v) => v.toMap()).toList(),
          });
        } else if (product.totalStock != null) {
          transaction.update(_productsCollection.doc(product.id), {
            'totalStock': product.totalStock! - item.quantity,
          });
        }
      }

      if (coupon != null && redemptionRef != null) {
        transaction.update(_couponsCollection.doc(coupon.id), {'usedCount': coupon.usedCount + 1});
        transaction.set(redemptionRef, {
          'userId': userId,
          'orderId': orderId,
          'redeemedAt': FieldValue.serverTimestamp(),
        });
      }

      final order = Order(
        id: orderId,
        userId: userId,
        items: orderItems,
        totalAmount: total,
        // Every order starts at pendingPayment regardless of paymentStatus —
        // firestore.rules requires it, and rightly so: with no real payment
        // gateway (and no Cloud Functions to verify one server-side), a
        // client claiming its own payment already succeeded is not proof of
        // anything. Advancing the order past pendingPayment stays an
        // explicit admin action either way (see isValidOrderTransition).
        // paymentStatus is informational only — it tells an admin what the
        // (demo) payment step reported without granting it any authority.
        status: OrderStatus.pendingPayment,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        createdAt: DateTime.now(),
        subtotal: subtotal,
        discountAmount: discountAmount,
        taxAmount: taxAmount,
        shippingFee: shippingFee,
        couponId: coupon?.id,
      );
      transaction.set(_collection.doc(orderId), order.toMap());
      return order;
    });
  }

  ProductVariant? _findVariant(Product product, String size) {
    for (final variant in product.variants) {
      if (variant.size == size) return variant;
    }
    return null;
  }

  /// Total order count across every customer — for admin-facing stats. Uses
  /// a server-side count aggregation rather than downloading every document,
  /// so it stays cheap regardless of how large the orders collection grows.
  Future<int> countAllOrders() async {
    final snapshot = await _collection.count().get();
    return snapshot.count ?? 0;
  }

  /// Every order across every customer — admin-only in practice, same as
  /// [countAllOrders] (firestore.rules only lets an unfiltered read of
  /// every order through for isAdmin()).
  Future<List<Order>> fetchAllOrders() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
  }

  Future<List<Order>> fetchOrders(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
  }

  Stream<List<Order>> watchOrders(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList());
  }

  /// Every order that contains at least one of this seller's items,
  /// regardless of who else's items are also in it — the seller-facing
  /// order list shows the whole order but a seller only ever sees their own
  /// line items within it (see [Order.itemsForSeller]).
  Future<List<Order>> fetchOrdersForSeller(String sellerId) async {
    final snapshot = await _collection
        .where('sellerIds', arrayContains: sellerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
  }

  Future<Order?> getOrderById(String orderId) async {
    final doc = await _collection.doc(orderId).get();
    if (doc.exists) return Order.fromFirestore(doc);
    return null;
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _collection.doc(orderId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOrder(String orderId) async {
    await _collection.doc(orderId).delete();
  }
}
