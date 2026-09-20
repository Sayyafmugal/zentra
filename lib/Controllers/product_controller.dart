// product_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/product.dart';
import '../models/product_variant.dart';
import '../repositories/product_repository.dart';
import '../data/product_seed_data.dart';

export '../models/product.dart';

class ProductController extends GetxController {
  ProductController({ProductRepository? repository, FirebaseAuth? auth})
    : _repository = repository ?? ProductRepository(),
      _auth = auth ?? FirebaseAuth.instance;

  static ProductController get instance => Get.find();

  final ProductRepository _repository;
  final FirebaseAuth _auth;

  // Observable list of every product this account is allowed to fetch (for
  // an admin reviewing the catalog, that's everything). Customer-facing
  // screens must use [publishedProducts] instead, or a seller's
  // draft/pendingApproval submission would show up in the storefront before
  // an admin ever approves it.
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  /// What a customer should ever see: only [ProductStatus.published]
  /// listings. Filtered in memory rather than at the Firestore query level
  /// — see ProductRepository.fetchProductsByStatus for why a server-side
  /// equality filter on `status` would incorrectly hide every product
  /// created before that field existed.
  List<Product> get publishedProducts => products.where((p) => p.isPublished).toList();

  // ==================== STOREFRONT PAGINATION ====================
  // The customer-facing home/shopping screens page through the catalog in
  // small batches instead of loading everything on cold start (see
  // ProductRepository.fetchProductsPage) — [products] above is still what
  // admin/seller screens use for their own full-catalog views, since those
  // are reached only by an authenticated seller/admin who explicitly needs
  // to see everything they own.
  static const int _storefrontPageSize = 20;

  final RxList<Product> storefrontFeed = <Product>[].obs;
  final RxBool hasMoreStorefront = true.obs;
  final RxBool isLoadingMoreStorefront = false.obs;
  DocumentSnapshot<Map<String, dynamic>>? _storefrontCursor;

  List<Product> get publishedStorefrontProducts =>
      storefrontFeed.where((p) => p.isPublished).toList();

  Future<void> fetchStorefrontFirstPage() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final page = await _repository.fetchProductsPage(limit: _storefrontPageSize);
      storefrontFeed.value = page.products;
      _storefrontCursor = page.lastDocument;
      hasMoreStorefront.value = page.hasMore;

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'Failed to load products. Pull to refresh to try again.';
    }
  }

  Future<void> loadMoreStorefrontProducts() async {
    if (!hasMoreStorefront.value || isLoadingMoreStorefront.value) return;
    try {
      isLoadingMoreStorefront.value = true;
      final page = await _repository.fetchProductsPage(
        limit: _storefrontPageSize,
        startAfter: _storefrontCursor,
      );
      storefrontFeed.addAll(page.products);
      _storefrontCursor = page.lastDocument;
      hasMoreStorefront.value = page.hasMore;
      isLoadingMoreStorefront.value = false;
    } catch (e) {
      isLoadingMoreStorefront.value = false;
    }
  }

  /// Pages in every remaining product so client-side search/category
  /// filtering (see home/shopping screens) covers the whole catalog rather
  /// than only what's been paged in so far. Only ever triggered by an
  /// explicit search/filter action from the user — never automatically —
  /// which is what keeps the *default* browsing experience bounded.
  Future<void> ensureStorefrontFullyLoaded() async {
    while (hasMoreStorefront.value) {
      await loadMoreStorefrontProducts();
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  void onInit() {
    super.onInit();
    // Products are public read data, so we can fetch them regardless of auth
    // state — but we never write/seed anything implicitly here. That used to
    // cause an unauthenticated Firestore write attempt (and the resulting
    // permission-denied error) on every cold start. Loading the FULL catalog
    // here too would defeat the point of storefront pagination, so this only
    // primes the small first page; admin/seller screens that need the whole
    // catalog call fetchProducts() themselves.
    fetchStorefrontFirstPage();
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
    // Marketplace fields. Callers that don't pass these (admin's existing
    // "Add Product" flow) get the pre-existing behavior exactly: admin-owned
    // (empty sellerId), immediately published, no per-size stock tracking.
    String sellerId = '',
    ProductStatus status = ProductStatus.published,
    String? sku,
    List<ProductVariant> variants = const [],
    int? totalStock,
  }) async {
    try {
      isLoading.value = true;

      final product = Product(
        id: _repository.newProductId(),
        imagePath: imagePath,
        name: name,
        category: category,
        currentPrice: currentPrice,
        oldPrice: oldPrice,
        discount: discount,
        availableSizes: availableSizes,
        description: description,
        sellerId: sellerId,
        status: status,
        sku: sku,
        variants: variants,
        totalStock: totalStock,
      );

      await _repository.createProduct(product);

      products.add(product);
      isLoading.value = false;

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
      errorMessage.value = '';

      products.value = await _repository.fetchProducts();

      isLoading.value = false;
    } catch (e) {
      // ignore: avoid_print
      print('fetchProducts error: $e');
      isLoading.value = false;
      errorMessage.value = 'Failed to load products. Pull to refresh to try again.';
    }
  }

  // Stream products for real-time updates
  Stream<List<Product>> getProductsStream() => _repository.watchProducts();

  // Get product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      return await _repository.getProductById(productId);
    } catch (e) {
      return null;
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    try {
      return await _repository.getProductsByCategory(category);
    } catch (e) {
      return [];
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      return await _repository.searchProducts(query);
    } catch (e) {
      return [];
    }
  }

  // ==================== UPDATE ====================
  /// Approves, rejects, or otherwise moves a listing's review status. This
  /// is the admin action a seller's `pendingApproval` submission is waiting
  /// on — Firestore rules independently enforce that only an admin account
  /// can actually set `published`/`rejected`, so this call fails safely for
  /// anyone else even if the UI somehow let them reach it.
  Future<String?> updateProductStatus(String productId, ProductStatus status) async {
    try {
      final current = await _repository.getProductById(productId);
      if (current == null) return 'Product not found';

      final updated = current.copyWith(status: status);
      await _repository.updateProduct(updated);

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) products[index] = updated;

      return null;
    } catch (e) {
      return 'Failed to update product status: $e';
    }
  }

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
    String? sku,
    List<ProductVariant>? variants,
    int? totalStock,
  }) async {
    try {
      isLoading.value = true;

      final currentProduct = await _repository.getProductById(productId);
      if (currentProduct == null) {
        isLoading.value = false;
        return 'Product not found';
      }

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
        sku: sku,
        variants: variants,
        totalStock: totalStock,
      );

      await _repository.updateProduct(updatedProduct);

      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        products[index] = updatedProduct;
      }

      isLoading.value = false;

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

      await _repository.deleteProduct(productId);

      products.removeWhere((product) => product.id == productId);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete product: $e';
    }
  }

  // ==================== ADMIN: SEED DEMO DATA ====================
  /// Explicit, admin-triggered action only. Never called from onInit/startup.
  Future<String?> seedDemoCatalog() async {
    try {
      isLoading.value = true;
      await _repository.seedProducts(kProductSeedData);
      await fetchProducts();
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to seed catalog: $e';
    }
  }
}
