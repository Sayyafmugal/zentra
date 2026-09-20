import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

/// Wraps all Firestore access for the `wishlist` collection.
class WishlistRepository {
  WishlistRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('wishlist');

  Future<void> addToWishlist(String userId, Product product) async {
    final id = _collection.doc().id;
    await _collection.doc(id).set({
      'id': id,
      'userId': userId,
      'productId': product.id,
      'product': product.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Product>> fetchWishlistItems(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final productData = doc.data()['product'] as Map<String, dynamic>;
      return Product.fromMap(productData).copyWith(isFavorite: true);
    }).toList();
  }

  Stream<List<Product>> watchWishlistItems(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final productData = doc.data()['product'] as Map<String, dynamic>;
            return Product.fromMap(productData).copyWith(isFavorite: true);
          }).toList(),
        );
  }

  Future<String?> getWishlistDocId(String userId, String productId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) return snapshot.docs.first.id;
    return null;
  }

  Future<void> removeByDocId(String docId) async {
    await _collection.doc(docId).delete();
  }

  Future<void> clearWishlist(String userId) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
