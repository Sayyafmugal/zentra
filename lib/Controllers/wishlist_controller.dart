// wishlist_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../view/product_model.dart';

class WishlistController extends GetxController {
  static WishlistController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

      // Check if already in wishlist
      if (isInWishlist(product.id)) {
        return 'Product already in wishlist';
      }

      isLoading.value = true;

      final wishlistId = _firestore.collection('wishlist').doc().id;

      await _firestore.collection('wishlist').doc(wishlistId).set({
        'id': wishlistId,
        'userId': currentUserId,
        'productId': product.id,
        'product': product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      wishlistItems.add(product.copyWith(isFavorite: true));
      isLoading.value = false;

      Get.snackbar(
        'Added to Wishlist',
        '${product.name} added to wishlist',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

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

      final snapshot = await _firestore
          .collection('wishlist')
          .where('userId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      wishlistItems.value = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final productData = data['product'] as Map<String, dynamic>;
            return Product.fromMap(productData).copyWith(isFavorite: true);
          })
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch wishlist items: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream wishlist items for real-time updates
  Stream<List<Product>> getWishlistItemsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('wishlist')
        .where('userId', isEqualTo: currentUserId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              final data = doc.data();
              final productData = data['product'] as Map<String, dynamic>;
              return Product.fromMap(productData).copyWith(isFavorite: true);
            })
            .toList());
  }

  // Check if product is in wishlist
  bool isInWishlist(String productId) {
    return wishlistItems.any((product) => product.id == productId);
  }

  // Get wishlist item document ID by product ID
  Future<String?> getWishlistItemDocId(String productId) async {
    try {
      if (currentUserId == null) return null;

      final snapshot = await _firestore
          .collection('wishlist')
          .where('userId', isEqualTo: currentUserId)
          .where('productId', isEqualTo: productId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== UPDATE ====================
  // Note: Usually wishlist items don't need updates, but you can update the product reference
  Future<String?> updateWishlistItem(String productId, Product updatedProduct) async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      isLoading.value = true;

      final docId = await getWishlistItemDocId(productId);
      if (docId == null) {
        isLoading.value = false;
        return 'Wishlist item not found';
      }

      await _firestore.collection('wishlist').doc(docId).update({
        'product': updatedProduct.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final index = wishlistItems.indexWhere((p) => p.id == productId);
      if (index != -1) {
        wishlistItems[index] = updatedProduct.copyWith(isFavorite: true);
        wishlistItems.refresh();
      }

      isLoading.value = false;
      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update wishlist item: $e';
    }
  }

  // ==================== DELETE ====================
  Future<String?> removeFromWishlist(String productId) async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      isLoading.value = true;

      final docId = await getWishlistItemDocId(productId);
      if (docId == null) {
        isLoading.value = false;
        return 'Wishlist item not found';
      }

      await _firestore.collection('wishlist').doc(docId).delete();

      wishlistItems.removeWhere((product) => product.id == productId);
      isLoading.value = false;

      Get.snackbar(
        'Removed',
        'Item removed from wishlist',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to remove from wishlist: $e';
    }
  }

  // Toggle wishlist (add if not exists, remove if exists)
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

      final snapshot = await _firestore
          .collection('wishlist')
          .where('userId', isEqualTo: currentUserId)
          .get();

      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      wishlistItems.clear();
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to clear wishlist: $e';
    }
  }
}


