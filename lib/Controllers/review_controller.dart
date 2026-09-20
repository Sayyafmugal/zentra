// review_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../repositories/order_repository.dart';
import '../repositories/review_repository.dart';

export '../models/review.dart';

/// Owns product reviews. Deliberately checks "is this a qualifying
/// purchase" here too (not just relying on firestore.rules) so a customer
/// gets a clear, specific error message instead of a bare permission-denied
/// — but the rules are what actually make this safe against a client that
/// skips the app entirely.
class ReviewController extends GetxController {
  ReviewController({
    ReviewRepository? reviewRepository,
    OrderRepository? orderRepository,
    FirebaseAuth? auth,
  }) : _reviewRepository = reviewRepository ?? ReviewRepository(),
       _orderRepository = orderRepository ?? OrderRepository(),
       _auth = auth ?? FirebaseAuth.instance;

  static ReviewController get instance => Get.find();

  final ReviewRepository _reviewRepository;
  final OrderRepository _orderRepository;
  final FirebaseAuth _auth;

  final RxList<Review> productReviews = <Review>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> fetchReviewsForProduct(String productId) async {
    try {
      isLoading.value = true;
      productReviews.value = await _reviewRepository.fetchReviewsForProduct(productId);
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  /// Whether the current user may review [productId] from [orderId] right
  /// now — used to decide whether to show a "Write a Review" button at all,
  /// separate from the actual submit-time validation.
  Future<bool> canReview({required String orderId, required String productId}) async {
    if (currentUserId == null) return false;

    final order = await _orderRepository.getOrderById(orderId);
    if (order == null) return false;
    if (order.userId != currentUserId) return false;
    if (order.status != OrderStatus.delivered) return false;
    if (!order.productIds.contains(productId)) return false;

    final existing = await _reviewRepository.getReview(orderId: orderId, productId: productId);
    return existing == null;
  }

  Future<String?> submitReview({
    required String orderId,
    required String productId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    if (currentUserId == null) return 'Please login to leave a review.';
    if (rating < 1 || rating > 5) return 'Rating must be between 1 and 5.';
    if (comment.trim().isEmpty) return 'Please write a comment.';

    try {
      isLoading.value = true;

      final order = await _orderRepository.getOrderById(orderId);
      if (order == null) {
        isLoading.value = false;
        return 'Order not found.';
      }
      if (order.userId != currentUserId) {
        isLoading.value = false;
        return 'This isn\'t your order.';
      }
      if (order.status != OrderStatus.delivered) {
        isLoading.value = false;
        return 'You can only review items from delivered orders.';
      }
      if (!order.productIds.contains(productId)) {
        isLoading.value = false;
        return 'This product wasn\'t part of that order.';
      }

      final review = Review(
        id: Review.idFor(orderId: orderId, productId: productId),
        productId: productId,
        userId: currentUserId!,
        userName: userName,
        orderId: orderId,
        rating: rating,
        comment: comment.trim(),
        createdAt: DateTime.now(),
      );

      await _reviewRepository.submitReview(review);
      productReviews.insert(0, review);
      isLoading.value = false;

      return null;
    } on ReviewValidationException catch (e) {
      isLoading.value = false;
      return e.message;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to submit review: $e';
    }
  }
}
