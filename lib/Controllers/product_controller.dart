// product_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../view/product_model.dart';

class ProductController extends GetxController {
  static ProductController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Observable list of products
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  // ==================== CREATE ====================
  Future<String?> createProduct({
    required String imagePath,
    required String name,
    required String category,
    required double currentPrice,
    double? oldPrice,
    String? discount,
    required List<String> availableSizes,
    required String description,
  }) async {
    try {
      isLoading.value = true;

      final productId = _firestore.collection('products').doc().id;
      
      final product = Product(
        id: productId,
        imagePath: imagePath,
        name: name,
        category: category,
        currentPrice: currentPrice,
        oldPrice: oldPrice,
        discount: discount,
        availableSizes: availableSizes,
        description: description,
      );

      await _firestore.collection('products').doc(productId).set({
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      products.add(product);
      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Product created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to create product: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchProducts() async {
    try {
      isLoading.value = true;

      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      products.value = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch products: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream products for real-time updates
  Stream<List<Product>> getProductsStream() {
    return _firestore
        .collection('products')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Product.fromFirestore(doc))
            .toList());
  }

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return Product.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== UPDATE ====================
  Future<String?> updateProduct({
    required String productId,
    String? imagePath,
    String? name,
    String? category,
    double? currentPrice,
    double? oldPrice,
    String? discount,
    List<String>? availableSizes,
    String? description,
    bool? isFavorite,
  }) async {
    try {
      isLoading.value = true;

      final productDoc = _firestore.collection('products').doc(productId);
      final currentData = await productDoc.get();

      if (!currentData.exists) {
        isLoading.value = false;
        return 'Product not found';
      }

      final currentProduct = Product.fromFirestore(currentData);
      final updatedProduct = currentProduct.copyWith(
        imagePath: imagePath,
        name: name,
        category: category,
        currentPrice: currentPrice,
        oldPrice: oldPrice,
        discount: discount,
        availableSizes: availableSizes,
        description: description,
        isFavorite: isFavorite,
      );

      await productDoc.update({
        ...updatedProduct.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update local list
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = updatedProduct;
      }

      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Product updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update product: $e';
    }
  }

  // ==================== DELETE ====================
  Future<String?> deleteProduct(String productId) async {
    try {
      isLoading.value = true;

      await _firestore.collection('products').doc(productId).delete();

      products.removeWhere((product) => product.id == productId);
      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Product deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete product: $e';
    }
  }
}


