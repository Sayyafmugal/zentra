// order_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../view/product_model.dart';
import 'cart_controller.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String imagePath;
  final double price;
  final int quantity;
  final String selectedSize;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.imagePath,
    required this.price,
    required this.quantity,
    required this.selectedSize,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imagePath': imagePath,
      'price': price,
      'quantity': quantity,
      'selectedSize': selectedSize,
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
    );
  }
}

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

class Order {
  final String id;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus status;
  final String? shippingAddress;
  final String? paymentMethod;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.shippingAddress,
    this.paymentMethod,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'shippingAddress': shippingAddress,
      'paymentMethod': paymentMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map) {
    return Order(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => OrderStatus.pending,
      ),
      shippingAddress: map['shippingAddress'],
      paymentMethod: map['paymentMethod'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order.fromMap(data);
  }

  String get statusString {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get statusColor {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

class OrderController extends GetxController {
  static OrderController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      fetchOrders();
    }
  }

  // ==================== CREATE ====================
  Future<String?> createOrder({
    required List<OrderItem> items,
    required double totalAmount,
    String? shippingAddress,
    String? paymentMethod,
  }) async {
    try {
      if (currentUserId == null) {
        return 'Please login to create an order';
      }

      isLoading.value = true;

      final orderId = _firestore.collection('orders').doc().id;
      final order = Order(
        id: orderId,
        userId: currentUserId!,
        items: items,
        totalAmount: totalAmount,
        status: OrderStatus.pending,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('orders').doc(orderId).set(order.toMap());

      orders.insert(0, order);
      isLoading.value = false;

      // Clear cart after order creation
      await CartController.instance.clearCart();

      Get.snackbar(
        'Order Placed!',
        'Your order has been placed successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to create order: $e';
    }
  }

  // Create order from cart
  Future<String?> createOrderFromCart({
    String? shippingAddress,
    String? paymentMethod,
  }) async {
    try {
      final cartController = CartController.instance;
      if (cartController.cartItems.isEmpty) {
        return 'Cart is empty';
      }

      final orderItems = cartController.cartItems.map((cartItem) {
        return OrderItem(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          imagePath: cartItem.product.imagePath,
          price: cartItem.product.currentPrice,
          quantity: cartItem.quantity,
          selectedSize: cartItem.selectedSize,
        );
      }).toList();

      return await createOrder(
        items: orderItems,
        totalAmount: cartController.totalPrice,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
      );
    } catch (e) {
      return 'Failed to create order from cart: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchOrders() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;

      final snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      orders.value = snapshot.docs
          .map((doc) => Order.fromFirestore(doc))
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch orders: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream orders for real-time updates
  Stream<List<Order>> getOrdersStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Order.fromFirestore(doc))
            .toList());
  }

  // Get order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return Order.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== UPDATE ====================
  Future<String?> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      isLoading.value = true;

      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        final order = orders[index];
        orders[index] = Order(
          id: order.id,
          userId: order.userId,
          items: order.items,
          totalAmount: order.totalAmount,
          status: newStatus,
          shippingAddress: order.shippingAddress,
          paymentMethod: order.paymentMethod,
          createdAt: order.createdAt,
          updatedAt: DateTime.now(),
        );
        orders.refresh();
      }

      isLoading.value = false;

      Get.snackbar(
        'Updated',
        'Order status updated to ${newStatus.name}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update order: $e';
    }
  }

  // Cancel order
  Future<String?> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  // ==================== DELETE ====================
  Future<String?> deleteOrder(String orderId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('orders').doc(orderId).delete();

      orders.removeWhere((order) => order.id == orderId);
      isLoading.value = false;

      Get.snackbar(
        'Deleted',
        'Order deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete order: $e';
    }
  }
}


