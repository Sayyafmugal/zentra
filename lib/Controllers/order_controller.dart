// order_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import 'cart_controller.dart';

export '../models/order.dart';

class OrderController extends GetxController {
  OrderController({OrderRepository? repository, FirebaseAuth? auth})
    : _repository = repository ?? OrderRepository(),
      _auth = auth ?? FirebaseAuth.instance;

  static OrderController get instance => Get.find();

  final OrderRepository _repository;
  final FirebaseAuth _auth;

  final RxList<Order> orders = <Order>[].obs;
  final RxList<Order> sellerOrders = <Order>[].obs;
  // Platform-wide order list, for the admin order management screen —
  // distinct from [orders] above, same reasoning as [platformOrderCount].
  final RxList<Order> allOrders = <Order>[].obs;
  final RxBool isLoading = false.obs;
  // Platform-wide total, for the admin dashboard stat card — distinct from
  // [orders] above, which is always scoped to the current signed-in user
  // (an admin's own personal order history, not the whole platform's).
  final RxInt platformOrderCount = 0.obs;

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

      final order = Order(
        id: _repository.newOrderId(),
        userId: currentUserId!,
        items: items,
        totalAmount: totalAmount,
        status: OrderStatus.pendingPayment,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
      );

      await _repository.createOrder(order);

      orders.insert(0, order);
      isLoading.value = false;

      await CartController.instance.clearCart();

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to create order: $e';
    }
  }

  // Create order from cart
  // Prices, product availability, and stock are all re-checked against
  // Firestore inside a transaction (see OrderRepository.createOrderFromCart)
  // rather than trusted from the client-held cart — this is the actual
  // "never trust the client" boundary for checkout, not just a UI nicety.
  Future<String?> createOrderFromCart({
    String? shippingAddress,
    String? paymentMethod,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    String? couponCode,
  }) async {
    final cartController = CartController.instance;
    if (cartController.cartItems.isEmpty) {
      return 'Cart is empty';
    }

    return _placeOrder(
      items: cartController.cartItems,
      clearCartAfter: true,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      couponCode: couponCode,
    );
  }

  /// "Buy Now": places an order for exactly [items] — typically a single
  /// synthetic [CartItem] built from one product/variant/quantity selection
  /// on the product details screen — through the same secure transactional
  /// pipeline as a normal cart checkout (see
  /// OrderRepository.createOrderFromCart: prices/stock/coupon are all
  /// re-validated server-side regardless of which path was used). The
  /// user's real cart is never read and never modified by this path.
  Future<String?> createOrderFromItems({
    required List<CartItem> items,
    String? shippingAddress,
    String? paymentMethod,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    String? couponCode,
  }) {
    if (items.isEmpty) {
      return Future.value('Nothing to order');
    }

    return _placeOrder(
      items: items,
      clearCartAfter: false,
      shippingAddress: shippingAddress,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      couponCode: couponCode,
    );
  }

  /// Shared by [createOrderFromCart] and [createOrderFromItems] so both
  /// paths go through identical validation/creation logic — the only
  /// difference between "cart checkout" and "Buy Now" is which items list
  /// is passed in and whether the real cart gets cleared afterward.
  Future<String?> _placeOrder({
    required List<CartItem> items,
    required bool clearCartAfter,
    String? shippingAddress,
    String? paymentMethod,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    String? couponCode,
  }) async {
    if (currentUserId == null) {
      return 'Please login to create an order';
    }

    try {
      isLoading.value = true;

      final order = await _repository.createOrderFromCart(
        orderId: _repository.newOrderId(),
        userId: currentUserId!,
        cartItems: items,
        shippingAddress: shippingAddress,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        couponCode: couponCode,
      );

      orders.insert(0, order);
      isLoading.value = false;

      if (clearCartAfter) {
        await CartController.instance.clearCart();
      }

      return null;
    } on OrderValidationException catch (e) {
      isLoading.value = false;
      return e.message;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to create order: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchOrders() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;
      orders.value = await _repository.fetchOrders(currentUserId!);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  /// Orders containing at least one of this seller's items. The full order
  /// (possibly with other sellers' items too) is returned — a seller-facing
  /// screen should display only `order.itemsForSeller(sellerId)`, never the
  /// raw `items` list, so one seller never sees another's line items.
  Future<void> fetchSellerOrders(String sellerId) async {
    try {
      isLoading.value = true;
      sellerOrders.value = await _repository.fetchOrdersForSeller(sellerId);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  /// Admin-only in practice — see OrderRepository.fetchAllOrders.
  Future<void> fetchAllOrders() async {
    try {
      isLoading.value = true;
      allOrders.value = await _repository.fetchAllOrders();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  /// Admin-only in practice: firestore.rules only lets an unfiltered read of
  /// every order through for isAdmin() — anyone else's count aggregation
  /// query would be rejected the same way a raw fetch-all would be.
  Future<void> fetchPlatformOrderCount() async {
    try {
      platformOrderCount.value = await _repository.countAllOrders();
    } catch (e) {
      // Leave the previous value in place; the stat card just won't update.
    }
  }

  Stream<List<Order>> getOrdersStream() {
    if (currentUserId == null) return Stream.value([]);
    return _repository.watchOrders(currentUserId!);
  }

  Future<Order?> getOrderById(String orderId) async {
    try {
      return await _repository.getOrderById(orderId);
    } catch (e) {
      return null;
    }
  }

  // ==================== UPDATE ====================
  Future<String?> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final current =
          orders.firstWhereOrNull((o) => o.id == orderId) ??
          await _repository.getOrderById(orderId);
      if (current == null) return 'Order not found';
      if (!isValidOrderStatusTransition(current.status, newStatus)) {
        return 'Cannot move an order from ${current.statusString} to a ${newStatus.name} state';
      }

      isLoading.value = true;
      await _repository.updateOrderStatus(orderId, newStatus);

      final index = orders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        orders[index] = orders[index].copyWith(status: newStatus, updatedAt: DateTime.now());
      }
      final allIndex = allOrders.indexWhere((order) => order.id == orderId);
      if (allIndex != -1) {
        allOrders[allIndex] = allOrders[allIndex].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update order: $e';
    }
  }

  Future<String?> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, OrderStatus.cancelled);
  }

  /// A seller advancing fulfillment on their own order (processing → packed
  /// → shipped → delivered). Restricted to orders containing only that
  /// seller's items and to [isValidSellerOrderTransition] — enforced again
  /// in firestore.rules, this check is the UX-side mirror of it, not the
  /// security boundary.
  Future<String?> updateOrderStatusAsSeller(
    String orderId,
    OrderStatus newStatus,
    String sellerId,
  ) async {
    try {
      final current =
          sellerOrders.firstWhereOrNull((o) => o.id == orderId) ??
          await _repository.getOrderById(orderId);
      if (current == null) return 'Order not found';

      if (current.sellerIds.length != 1 || !current.sellerIds.contains(sellerId)) {
        return 'This order includes another seller\'s items — only an admin can update it.';
      }
      if (!isValidSellerOrderTransition(current.status, newStatus)) {
        return 'Cannot move an order from ${current.statusString} to a ${newStatus.name} state';
      }

      isLoading.value = true;
      await _repository.updateOrderStatus(orderId, newStatus);

      final index = sellerOrders.indexWhere((order) => order.id == orderId);
      if (index != -1) {
        sellerOrders[index] = sellerOrders[index].copyWith(
          status: newStatus,
          updatedAt: DateTime.now(),
        );
      }

      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update order: $e';
    }
  }

  // ==================== DELETE ====================
  Future<String?> deleteOrder(String orderId) async {
    try {
      isLoading.value = true;
      await _repository.deleteOrder(orderId);

      orders.removeWhere((order) => order.id == orderId);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete order: $e';
    }
  }
}
