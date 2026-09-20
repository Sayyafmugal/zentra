import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String imagePath;
  final double price;
  final int quantity;
  final String selectedSize;

  // Snapshots added for the marketplace/production upgrade. Both default to
  // '' for order documents written before sellers/SKUs existed, so old
  // orders still decode — they just show as platform-admin-owned with no
  // SKU, which matches how they actually were sold.
  final String sellerId;
  final String sku;

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.imagePath,
    required this.price,
    required this.quantity,
    required this.selectedSize,
    this.sellerId = '',
    this.sku = '',
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imagePath': imagePath,
      'price': price,
      'quantity': quantity,
      'selectedSize': selectedSize,
      'sellerId': sellerId,
      'sku': sku,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      imagePath: map['imagePath'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      selectedSize: map['selectedSize'] ?? '',
      sellerId: map['sellerId'] ?? '',
      sku: map['sku'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    productId,
    productName,
    imagePath,
    price,
    quantity,
    selectedSize,
    sellerId,
    sku,
  ];
}

/// Fulfillment lifecycle of an order. `pendingPayment` replaces the old bare
/// `pending` (see [_legacyStatusMap] in [Order.fromMap] for the read-side
/// mapping so existing order documents keep decoding correctly);
/// `processing`, `shipped`, `delivered`, and `cancelled` are unchanged from
/// before. Valid transitions are enforced by whichever controller mutates
/// this, not by the enum itself.
enum OrderStatus {
  pendingPayment,
  paid,
  processing,
  packed,
  shipped,
  outForDelivery,
  delivered,
  cancelled,
  returnRequested,
  returned,
  refunded,
}

/// Distinct from [OrderStatus] — an order can be `processing` fulfillment
/// while its payment is still `pending` capture, for example. Kept separate
/// per production e-commerce convention rather than overloading one enum
/// for two different lifecycles.
enum PaymentStatus { pending, paid, failed, refunded }

/// Maps the enum names this app used before the status expansion onto their
/// closest new equivalent, so an order written with the old 5-value enum
/// still reads back with a sensible status instead of silently defaulting.
const Map<String, OrderStatus> _legacyStatusMap = {'pending': OrderStatus.pendingPayment};

class Order extends Equatable {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String? shippingAddress;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Production fields, additive and defaulted for backward compatibility.
  final PaymentStatus paymentStatus;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double shippingFee;
  final String? couponId;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
    this.paymentStatus = PaymentStatus.pending,
    double? subtotal,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.shippingFee = 0.0,
    this.couponId,
  }) : subtotal = subtotal ?? totalAmount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      // Denormalized purely so Firestore can query
      // `where('sellerIds', arrayContains: sellerId)` — a nested array of
      // maps (`items`) can't be queried by a field inside it directly.
      // Never read back on decode (see fromMap): `sellerIds` is always
      // recomputed live from `items`, so this stored copy can never drift
      // out of sync with what the order actually contains.
      'sellerIds': sellerIds.toList(),
      'productIds': productIds.toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'paymentStatus': paymentStatus.name,
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'shippingFee': shippingFee,
      'couponId': couponId,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    final totalAmount = (map['totalAmount'] ?? 0.0).toDouble();
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: totalAmount,
      status:
          _legacyStatusMap[map['status']] ??
          OrderStatus.values.firstWhere(
            (e) => e.name == map['status'],
            orElse: () => OrderStatus.pendingPayment,
          ),
      shippingAddress: map['shippingAddress'],
      paymentMethod: map['paymentMethod'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      subtotal: map['subtotal'] != null ? (map['subtotal'] as num).toDouble() : totalAmount,
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0.0).toDouble(),
      shippingFee: (map['shippingFee'] ?? 0.0).toDouble(),
      couponId: map['couponId'],
    );
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order.fromMap(data);
  }

  /// Every seller whose items appear in this order — used to split one
  /// customer order into per-seller fulfillment views without a separate
  /// `sellerOrders` collection until that's actually needed.
  Set<String> get sellerIds => items.map((i) => i.sellerId).toSet();

  /// Every product this order contains — denormalized onto the document the
  /// same way [sellerIds] is (see toMap), so firestore.rules can check "did
  /// this user actually buy this product" for the reviews collection
  /// without needing to inspect the nested `items` array field-by-field.
  Set<String> get productIds => items.map((i) => i.productId).toSet();

  List<OrderItem> itemsForSeller(String sellerId) =>
      items.where((i) => i.sellerId == sellerId).toList();

  Order copyWith({OrderStatus? status, DateTime? updatedAt, PaymentStatus? paymentStatus}) {
    return Order(
      id: id,
      userId: userId,
      items: items,
      totalAmount: totalAmount,
      status: status ?? this.status,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      shippingFee: shippingFee,
      couponId: couponId,
    );
  }

  String get statusString {
    switch (status) {
      case OrderStatus.pendingPayment:
        return 'Pending Payment';
      case OrderStatus.paid:
        return 'Paid';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.returnRequested:
        return 'Return Requested';
      case OrderStatus.returned:
        return 'Returned';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  Color get statusColor {
    switch (status) {
      case OrderStatus.pendingPayment:
        return Colors.orange;
      case OrderStatus.paid:
        return Colors.teal;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.packed:
        return Colors.indigo;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.deepPurple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.returnRequested:
        return Colors.amber;
      case OrderStatus.returned:
        return Colors.brown;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    items,
    totalAmount,
    status,
    shippingAddress,
    paymentMethod,
    createdAt,
    updatedAt,
    paymentStatus,
    subtotal,
    discountAmount,
    taxAmount,
    shippingFee,
    couponId,
  ];
}

/// Defines which fulfillment transitions are legal, so a controller/rule can
/// reject e.g. jumping straight from `pendingPayment` to `delivered`. Terminal
/// states (`delivered`, `cancelled`, `returned`, `refunded`) have no outgoing
/// transitions here.
const Map<OrderStatus, Set<OrderStatus>> kValidOrderStatusTransitions = {
  OrderStatus.pendingPayment: {OrderStatus.paid, OrderStatus.cancelled},
  OrderStatus.paid: {OrderStatus.processing, OrderStatus.cancelled, OrderStatus.refunded},
  OrderStatus.processing: {OrderStatus.packed, OrderStatus.cancelled},
  OrderStatus.packed: {OrderStatus.shipped},
  OrderStatus.shipped: {OrderStatus.outForDelivery, OrderStatus.delivered},
  OrderStatus.outForDelivery: {OrderStatus.delivered},
  OrderStatus.delivered: {OrderStatus.returnRequested},
  OrderStatus.returnRequested: {OrderStatus.returned},
  OrderStatus.returned: {OrderStatus.refunded},
  OrderStatus.cancelled: {},
  OrderStatus.refunded: {},
};

bool isValidOrderStatusTransition(OrderStatus from, OrderStatus to) =>
    kValidOrderStatusTransitions[from]?.contains(to) ?? false;

/// The subset of [kValidOrderStatusTransitions] a seller (not admin) may
/// trigger themselves — pure fulfillment steps only. Payment capture,
/// cancellation, and refund/return decisions stay admin-only: a seller
/// marking their own shipment "packed" is fine, but a seller unilaterally
/// cancelling or refunding an order is a financial action this app doesn't
/// hand to them. Also only ever applies to a single-seller order — see
/// isActiveSeller/order-update rule in firestore.rules for why a
/// multi-seller order's aggregate status can't be safely seller-writable
/// without a real per-seller sub-order split.
const Map<OrderStatus, Set<OrderStatus>> kSellerAllowedOrderTransitions = {
  OrderStatus.processing: {OrderStatus.packed},
  OrderStatus.packed: {OrderStatus.shipped},
  OrderStatus.shipped: {OrderStatus.outForDelivery, OrderStatus.delivered},
  OrderStatus.outForDelivery: {OrderStatus.delivered},
};

bool isValidSellerOrderTransition(OrderStatus from, OrderStatus to) =>
    kSellerAllowedOrderTransitions[from]?.contains(to) ?? false;
