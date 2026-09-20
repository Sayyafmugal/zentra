import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

/// One page of a cursor-paginated product fetch. [lastDocument] is what the
/// next call's `startAfter` should be — an opaque cursor, not just an id, so
/// pagination works with any `orderBy` field without re-deriving a sort key.
class ProductPage {
  const ProductPage({required this.products, required this.lastDocument, required this.hasMore});

  final List<Product> products;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

/// Wraps all Firestore access for the `products` collection.
class ProductRepository {
  ProductRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Highest Unicode code point; appending it to a prefix search string gives
  // an upper bound that matches every string starting with that prefix.
  static final String _highUnicodeSuffix = String.fromCharCode(0xf8ff);

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('products');

  Future<void> createProduct(Product product) async {
    await _collection.doc(product.id).set({
      ...product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String newProductId() => _collection.doc().id;

  Future<List<Product>> fetchProducts() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  /// Fetches one page of products ordered newest-first, for the customer
  /// storefront — the thing that must never load "every product at once" on
  /// cold start. [startAfter] is the previous page's [ProductPage.lastDocument];
  /// omit it for the first page.
  Future<ProductPage> fetchProductsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    // startAfterDocument must be chained before limit: it searches for the
    // cursor within the *unbounded* ordered result set and returns
    // everything after it, so limiting first would search (and then cut)
    // the wrong window — the cursor could fall outside an already-truncated
    // page and silently return nothing.
    Query<Map<String, dynamic>> query = _collection.orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);
    final snapshot = await query.get();
    return ProductPage(
      products: snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList(),
      lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
      hasMore: snapshot.docs.length == limit,
    );
  }

  Stream<List<Product>> watchProducts() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProductById(String productId) async {
    final doc = await _collection.doc(productId).get();
    if (doc.exists) return Product.fromFirestore(doc);
    return null;
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final snapshot = await _collection.where('category', isEqualTo: category).get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  /// Products owned by one seller (empty string == platform-admin-owned).
  Future<List<Product>> fetchProductsBySeller(String sellerId) async {
    final snapshot = await _collection
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  /// NOTE: not yet used by the default storefront fetch. Every product
  /// created before the `status` field existed has no such field stored in
  /// Firestore, so a `where('status', isEqualTo: ...)` query would silently
  /// exclude all of them (Firestore equality queries don't match missing
  /// fields) — wiring this into the customer-facing fetch path requires a
  /// migration pass that first backfills `status: 'published'` onto every
  /// existing product document.
  Future<List<Product>> fetchProductsByStatus(ProductStatus status) async {
    final snapshot = await _collection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<void> backfillMissingStatusField() async {
    final snapshot = await _collection.get();
    final batch = _firestore.batch();
    var pending = 0;
    for (final doc in snapshot.docs) {
      if (!doc.data().containsKey('status')) {
        batch.update(doc.reference, {'status': ProductStatus.published.name});
        pending++;
      }
    }
    if (pending > 0) await batch.commit();
  }

  Future<List<Product>> searchProducts(String query) async {
    final snapshot = await _collection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + _highUnicodeSuffix)
        .get();
    return snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList();
  }

  Future<void> updateProduct(Product product) async {
    await _collection.doc(product.id).update({
      ...product.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    await _collection.doc(productId).delete();
  }

  /// Seeds demo catalog data. Intended for an explicit admin action only —
  /// never called implicitly at app startup.
  Future<void> seedProducts(List<Product> seedProducts) async {
    final batch = _firestore.batch();
    for (final product in seedProducts) {
      batch.set(_collection.doc(product.id), {
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
