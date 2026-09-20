// cart_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../repositories/cart_repository.dart';

export '../models/cart_item.dart';

class CartController extends GetxController {
  CartController({CartRepository? repository, FirebaseAuth? auth})
    : _repository = repository ?? CartRepository(),
      _auth = auth ?? FirebaseAuth.instance;

  static CartController get instance => Get.find();

  final CartRepository _repository;
  final FirebaseAuth _auth;

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

      final existingItem = cartItems.firstWhereOrNull(
        (item) => item.product.id == product.id && item.selectedSize == selectedSize,
      );

      if (existingItem != null) {
        await updateCartItemQuantity(existingItem.id, existingItem.quantity + quantity);
        isLoading.value = false;
        return null;
      }

      final cartItem = CartItem(
        id: _repository.newCartItemId(),
        product: product,
        quantity: quantity,
        selectedSize: selectedSize,
        userId: currentUserId!,
      );

      await _repository.addCartItem(cartItem);

      cartItems.add(cartItem);
      isLoading.value = false;

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
      cartItems.value = await _repository.fetchCartItems(currentUserId!);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Stream<List<CartItem>> getCartItemsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _repository.watchCartItems(currentUserId!);
  }

  CartItem? getCartItemById(String cartItemId) {
    return cartItems.firstWhereOrNull((item) => item.id == cartItemId);
  }

  double get totalPrice => cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItems => cartItems.fold(0, (sum, item) => sum + item.quantity);

  // ==================== UPDATE ====================
  Future<String?> updateCartItemQuantity(String cartItemId, int newQuantity) async {
    try {
      if (newQuantity <= 0) {
        return await removeFromCart(cartItemId);
      }

      isLoading.value = true;
      await _repository.updateQuantity(cartItemId, newQuantity);

      final index = cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        cartItems[index] = cartItems[index].copyWith(quantity: newQuantity);
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
      await _repository.updateSize(cartItemId, newSize);

      final index = cartItems.indexWhere((item) => item.id == cartItemId);
      if (index != -1) {
        cartItems[index] = cartItems[index].copyWith(selectedSize: newSize);
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
      await _repository.removeCartItem(cartItemId);

      cartItems.removeWhere((item) => item.id == cartItemId);
      isLoading.value = false;

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
      await _repository.clearCart(cartItems.map((item) => item.id).toList());

      cartItems.clear();
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to clear cart: $e';
    }
  }
}
