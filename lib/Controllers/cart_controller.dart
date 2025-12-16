// cart_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../view/product_model.dart';

class CartItem {
  final String id;
  final Product product;
  int quantity;
  final String selectedSize;
  final String userId;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.selectedSize,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': product.id,
      'product': product.toMap(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'userId': userId,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      id: map['id'] ?? '',
      product: product,
      quantity: map['quantity'] ?? 1,
      selectedSize: map['selectedSize'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final product = Product.fromMap(data['product'] as Map<String, dynamic>);
    return CartItem.fromMap(data, product);
  }

  double get totalPrice => product.currentPrice * quantity;
}

class CartController extends GetxController {
  static CartController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      fetchCartItems();
    }
  }

  // ==================== CREATE ====================
  Future<String?> addToCart({
    required Product product,
    required String selectedSize,
    int quantity = 1,
  }) async {
    try {
      if (currentUserId == null) {
        return 'Please login to add items to cart';
      }

      isLoading.value = true;

      // Check if item already exists in cart
      final existingItem = cartItems.firstWhereOrNull(
        (item) => item.product.id == product.id && item.selectedSize == selectedSize,
      );

      if (existingItem != null) {
        // Update quantity
        await updateCartItemQuantity(existingItem.id, existingItem.quantity + quantity);
        isLoading.value = false;
        return null;
      }

      // Create new cart item
      final cartItemId = _firestore.collection('cart').doc().id;
      final cartItem = CartItem(
        id: cartItemId,
        product: product,
        quantity: quantity,
        selectedSize: selectedSize,
        userId: currentUserId!,
      );

      await _firestore.collection('cart').doc(cartItemId).set({
        ...cartItem.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      cartItems.add(cartItem);
      isLoading.value = false;

      Get.snackbar(
        'Added to Cart',
        '${product.name} added to cart',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to add to cart: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchCartItems() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;

      final snapshot = await _firestore
          .collection('cart')
          .where('userId', isEqualTo: currentUserId)
          .get();

      cartItems.value = snapshot.docs
          .map((doc) => CartItem.fromFirestore(doc))
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch cart items: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream cart items for real-time updates
  Stream<List<CartItem>> getCartItemsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('cart')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItem.fromFirestore(doc))
            .toList());
  }

  // Get cart item by ID
  CartItem? getCartItemById(String cartItemId) {
    try {
      return cartItems.firstWhereOrNull((item) => item.id == cartItemId);
    } catch (e) {
      return null;
    }
  }

  // Get total price
  double get totalPrice {
    return cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Get total items count
  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  // ==================== UPDATE ====================
  Future<String?> updateCartItemQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        return await removeFromCart(cartItemId);
      }

      isLoading.value = true;

      await _firestore.collection('cart').doc(cartItemId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        cartItems[index].quantity = newQuantity;
        cartItems.refresh();
      }

      isLoading.value = false;
      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update cart item: $e';
    }
  }

  Future<String?> updateCartItemSize(String cartItemId, String newSize) async {
    try {
      isLoading.value = true;

      await _firestore.collection('cart').doc(cartItemId).update({
        'selectedSize': newSize,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        final item = cartItems[index];
        cartItems[index] = CartItem(
          id: item.id,
          product: item.product,
          quantity: item.quantity,
          selectedSize: newSize,
          userId: item.userId,
        );
        cartItems.refresh();
      }

      isLoading.value = false;
      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update cart item size: $e';
    }
  }

  // ==================== DELETE ====================
  Future<String?> removeFromCart(String cartItemId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('cart').doc(cartItemId).delete();

      cartItems.removeWhere((item) => item.id == cartItemId);
      isLoading.value = false;

      Get.snackbar(
        'Removed',
        'Item removed from cart',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to remove from cart: $e';
    }
  }

  Future<String?> clearCart() async {
    try {
      if (currentUserId == null) return 'User not logged in';

      isLoading.value = true;

      final batch = _firestore.batch();
      for (var item in cartItems) {
        batch.delete(_firestore.collection('cart').doc(item.id));
      }
      await batch.commit();

      cartItems.clear();
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to clear cart: $e';
    }
  }
}


