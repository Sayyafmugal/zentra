import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/review.dart';

/// Thrown when a review can't be submitted — duplicate, or (defense in
/// depth; firestore.rules is the real gate) not a qualifying purchase.
class ReviewValidationException implements Exception {
  ReviewValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Wraps all Firestore access for the `reviews` collection.
class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('reviews');

  CollectionReference<Map<String, dynamic>> get _productsCollection =>
      _firestore.collection('products');

  /// Creates the review and updates the product's running average `rating`
  /// and `reviewCount` in one transaction, so the two can never drift out
  /// of sync (e.g. a review existing but never counted, or vice versa).
  /// [review.id] must already be [Review.idFor] — its existence check here
  /// is what makes "one review per purchased item" atomic and race-free.
  Future<void> submitReview(Review review) {
    return _firestore.runTransaction((transaction) async {
      final reviewRef = _collection.doc(review.id);
      final productRef = _productsCollection.doc(review.productId);

      final existingReview = await transaction.get(reviewRef);
      if (existingReview.exists) {
        throw ReviewValidationException('You have already reviewed this item.');
      }

      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) {
        throw ReviewValidationException('This product no longer exists.');
      }
      final product = Product.fromFirestore(productSnapshot);

      final newCount = product.reviewCount + 1;
      final newRating = ((product.rating * product.reviewCount) + review.rating) / newCount;

      transaction.set(reviewRef, review.toMap());
      transaction.update(productRef, {'rating': newRating, 'reviewCount': newCount});
    });
  }

  Future<List<Review>> fetchReviewsForProduct(String productId) async {
    final snapshot = await _collection
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: ReviewStatus.published.name)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList();
  }

  Future<Review?> getReview({required String orderId, required String productId}) async {
    final doc = await _collection.doc(Review.idFor(orderId: orderId, productId: productId)).get();
    if (doc.exists) return Review.fromFirestore(doc);
    return null;
  }

  Future<void> hideReview(String reviewId) async {
    await _collection.doc(reviewId).update({'status': ReviewStatus.hidden.name});
  }
}
