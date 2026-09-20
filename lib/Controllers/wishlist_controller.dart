// wishlist_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../repositories/wishlist_repository.dart';

class WishlistController extends GetxController {
  WishlistController({WishlistRepository? repository, FirebaseAuth? auth})
    : _repository = repository ?? WishlistRepository(),
      _auth = auth ?? FirebaseAuth.instance;

  static WishlistController get instance => Get.find();

  final WishlistRepository _repository;
  final FirebaseAuth _auth;

  final RxList<Product> wishlistItems = <Product>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      fetchWishlistItems();
    }
  }

  // ==================== CREATE ====================
  Future<String?> addToWishlist(Product product) async {
    try {
      if (currentUserId == null) {
        return 'Please login to add items to wishlist';
      }

      if (isInWishlist(product.id)) {
        return 'Product already in wishlist';
      }

      isLoading.value = true;
      await _repository.addToWishlist(currentUserId!, product);

      wishlistItems.add(product.copyWith(isFavorite: true));
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to add to wishlist: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchWishlistItems() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;
      wishlistItems.value = await _repository.fetchWishlistItems(currentUserId!);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Stream<List<Product>> getWishlistItemsStream() {
    if (currentUserId == null) return Stream.value([]);
    return _repository.watchWishlistItems(currentUserId!);
  }

  bool isInWishlist(String productId) {
    return wishlistItems.any((product) => product.id == productId);
  }

  // ==================== DELETE ====================
  Future<String?> removeFromWishlist(String productId) async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      isLoading.value = true;

      final docId = await _repository.getWishlistDocId(currentUserId!, productId);
      if (docId == null) {
        isLoading.value = false;
        return 'Wishlist item not found';
      }

      await _repository.removeByDocId(docId);

      wishlistItems.removeWhere((product) => product.id == productId);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to remove from wishlist: $e';
    }
  }

  Future<String?> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      return await removeFromWishlist(product.id);
    } else {
      return await addToWishlist(product);
    }
  }

  Future<String?> clearWishlist() async {
    try {
      if (currentUserId == null) return 'User not logged in';

      isLoading.value = true;
      await _repository.clearWishlist(currentUserId!);

      wishlistItems.clear();
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to clear wishlist: $e';
    }
  }
}
