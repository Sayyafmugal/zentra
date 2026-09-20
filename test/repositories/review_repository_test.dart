import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/product.dart';
import 'package:zentra_0/models/review.dart';
import 'package:zentra_0/repositories/review_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReviewRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = ReviewRepository(firestore: firestore);
  });

  const product = Product(
    id: 'p1',
    imagePath: 'assets/images/shoe.jpg',
    name: 'Air Runner',
    category: 'Shoes',
    currentPrice: 50.0,
    availableSizes: ['M'],
    description: 'desc',
    rating: 4.0,
    reviewCount: 1,
  );

  Review buildReview({String orderId = 'o1', double rating = 5.0}) {
    return Review(
      id: Review.idFor(orderId: orderId, productId: 'p1'),
      productId: 'p1',
      userId: 'u1',
      userName: 'Jordan',
      orderId: orderId,
      rating: rating,
      comment: 'Great product!',
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('submitReview creates the review and recomputes the product\'s running average', () async {
    await firestore.collection('products').doc('p1').set(product.toMap());

    await repository.submitReview(buildReview(rating: 5.0));

    final updatedProduct = await firestore.collection('products').doc('p1').get();
    // Old: rating 4.0 over 1 review. New: (4.0*1 + 5.0) / 2 = 4.5.
    expect(updatedProduct.data()!['rating'], 4.5);
    expect(updatedProduct.data()!['reviewCount'], 2);

    final review = await firestore
        .collection('reviews')
        .doc(Review.idFor(orderId: 'o1', productId: 'p1'))
        .get();
    expect(review.exists, isTrue);
    expect(review.data()!['comment'], 'Great product!');
  });

  test('rejects a second review for the same order+product', () async {
    await firestore.collection('products').doc('p1').set(product.toMap());
    await repository.submitReview(buildReview());

    expect(() => repository.submitReview(buildReview()), throwsA(isA<ReviewValidationException>()));
  });

  test('rejects a review for a product that no longer exists', () async {
    expect(() => repository.submitReview(buildReview()), throwsA(isA<ReviewValidationException>()));
  });

  test('fetchReviewsForProduct only returns published reviews for that product', () async {
    await firestore.collection('products').doc('p1').set(product.toMap());
    await firestore.collection('products').doc('p2').set(product.copyWith(id: 'p2').toMap());

    await repository.submitReview(buildReview(orderId: 'o1'));
    await firestore
        .collection('reviews')
        .doc(Review.idFor(orderId: 'o2', productId: 'p1'))
        .set(buildReview(orderId: 'o2').copyWith(status: ReviewStatus.hidden).toMap());

    final visible = await repository.fetchReviewsForProduct('p1');

    expect(visible, hasLength(1));
    expect(visible.first.orderId, 'o1');
  });

  test('getReview finds an existing review by order and product', () async {
    await firestore.collection('products').doc('p1').set(product.toMap());
    await repository.submitReview(buildReview());

    final found = await repository.getReview(orderId: 'o1', productId: 'p1');

    expect(found, isNotNull);
    expect(found!.comment, 'Great product!');
  });

  test('getReview returns null when no review exists yet', () async {
    final found = await repository.getReview(orderId: 'o1', productId: 'p1');
    expect(found, isNull);
  });
}
