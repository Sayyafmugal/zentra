import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/review_controller.dart';
import 'package:zentra_0/models/order.dart';
import 'package:zentra_0/models/review.dart';
import 'package:zentra_0/repositories/order_repository.dart';
import 'package:zentra_0/repositories/review_repository.dart';

class MockReviewRepository extends Mock implements ReviewRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

Order _buildOrder({
  String id = 'o1',
  String userId = 'u1',
  OrderStatus status = OrderStatus.delivered,
  List<String> productIds = const ['p1'],
}) {
  return Order(
    id: id,
    userId: userId,
    items: productIds
        .map(
          (productId) => OrderItem(
            productId: productId,
            productName: 'Item $productId',
            imagePath: 'assets/images/shoe.jpg',
            price: 10.0,
            quantity: 1,
            selectedSize: 'M',
          ),
        )
        .toList(),
    totalAmount: 10.0,
    status: status,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Review(
        id: 'x',
        productId: 'x',
        userId: 'x',
        userName: 'x',
        orderId: 'x',
        rating: 5,
        comment: 'x',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  late MockReviewRepository reviewRepo;
  late MockOrderRepository orderRepo;
  late MockFirebaseAuth auth;
  late ReviewController controller;

  setUp(() {
    reviewRepo = MockReviewRepository();
    orderRepo = MockOrderRepository();
    auth = MockFirebaseAuth();
    final user = MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => auth.currentUser).thenReturn(user);

    controller = ReviewController(
      reviewRepository: reviewRepo,
      orderRepository: orderRepo,
      auth: auth,
    );
  });

  group('ReviewController.canReview', () {
    test('true for a delivered order containing the product with no existing review', () async {
      when(() => orderRepo.getOrderById('o1')).thenAnswer((_) async => _buildOrder());
      when(
        () => reviewRepo.getReview(orderId: 'o1', productId: 'p1'),
      ).thenAnswer((_) async => null);

      expect(await controller.canReview(orderId: 'o1', productId: 'p1'), isTrue);
    });

    test('false when the order isn\'t delivered yet', () async {
      when(
        () => orderRepo.getOrderById('o1'),
      ).thenAnswer((_) async => _buildOrder(status: OrderStatus.shipped));

      expect(await controller.canReview(orderId: 'o1', productId: 'p1'), isFalse);
    });

    test('false when the order belongs to someone else', () async {
      when(
        () => orderRepo.getOrderById('o1'),
      ).thenAnswer((_) async => _buildOrder(userId: 'someone-else'));

      expect(await controller.canReview(orderId: 'o1', productId: 'p1'), isFalse);
    });

    test('false when the product wasn\'t part of the order', () async {
      when(
        () => orderRepo.getOrderById('o1'),
      ).thenAnswer((_) async => _buildOrder(productIds: ['other']));

      expect(await controller.canReview(orderId: 'o1', productId: 'p1'), isFalse);
    });

    test('false when a review already exists for this order+product', () async {
      when(() => orderRepo.getOrderById('o1')).thenAnswer((_) async => _buildOrder());
      when(() => reviewRepo.getReview(orderId: 'o1', productId: 'p1')).thenAnswer(
        (_) async => Review(
          id: Review.idFor(orderId: 'o1', productId: 'p1'),
          productId: 'p1',
          userId: 'u1',
          userName: 'Jordan',
          orderId: 'o1',
          rating: 5,
          comment: 'Already reviewed',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      expect(await controller.canReview(orderId: 'o1', productId: 'p1'), isFalse);
    });
  });

  group('ReviewController.submitReview validation', () {
    test('rejects a rating outside 1-5 without touching the repository', () async {
      final error = await controller.submitReview(
        orderId: 'o1',
        productId: 'p1',
        userName: 'Jordan',
        rating: 0,
        comment: 'test',
      );

      expect(error, isNotNull);
      verifyNever(() => reviewRepo.submitReview(any()));
    });

    test('rejects an empty comment', () async {
      final error = await controller.submitReview(
        orderId: 'o1',
        productId: 'p1',
        userName: 'Jordan',
        rating: 5,
        comment: '   ',
      );

      expect(error, isNotNull);
      verifyNever(() => reviewRepo.submitReview(any()));
    });

    test('rejects reviewing an order that isn\'t delivered', () async {
      when(
        () => orderRepo.getOrderById('o1'),
      ).thenAnswer((_) async => _buildOrder(status: OrderStatus.processing));

      final error = await controller.submitReview(
        orderId: 'o1',
        productId: 'p1',
        userName: 'Jordan',
        rating: 5,
        comment: 'Great!',
      );

      expect(error, contains('delivered'));
      verifyNever(() => reviewRepo.submitReview(any()));
    });

    test('rejects reviewing a product that wasn\'t in the order', () async {
      when(
        () => orderRepo.getOrderById('o1'),
      ).thenAnswer((_) async => _buildOrder(productIds: ['other']));

      final error = await controller.submitReview(
        orderId: 'o1',
        productId: 'p1',
        userName: 'Jordan',
        rating: 5,
        comment: 'Great!',
      );

      expect(error, contains('wasn\'t part'));
      verifyNever(() => reviewRepo.submitReview(any()));
    });

    testWidgets('submits successfully for a valid delivered purchase', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      when(() => orderRepo.getOrderById('o1')).thenAnswer((_) async => _buildOrder());
      when(() => reviewRepo.submitReview(any())).thenAnswer((_) async {});

      final error = await controller.submitReview(
        orderId: 'o1',
        productId: 'p1',
        userName: 'Jordan',
        rating: 5,
        comment: 'Great!',
      );
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      expect(controller.productReviews, hasLength(1));
      verify(() => reviewRepo.submitReview(any())).called(1);
    });
  });
}
