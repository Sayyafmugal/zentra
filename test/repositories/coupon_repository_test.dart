import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/coupon.dart';
import 'package:zentra_0/repositories/coupon_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late CouponRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = CouponRepository(firestore: firestore);
  });

  Coupon buildCoupon({String id = 'SAVE20'}) {
    return Coupon(id: id, type: CouponType.percentage, value: 20, createdAt: DateTime(2026, 1, 1));
  }

  test('createCoupon writes the coupon at its normalized code as the doc id', () async {
    await repository.createCoupon(buildCoupon());

    final doc = await firestore.collection('coupons').doc('SAVE20').get();
    expect(doc.exists, isTrue);
  });

  test('getCouponByCode normalizes the lookup code', () async {
    await repository.createCoupon(buildCoupon());

    final found = await repository.getCouponByCode('  save20 ');

    expect(found, isNotNull);
    expect(found!.id, 'SAVE20');
  });

  test('getCouponByCode returns null for a code that doesn\'t exist', () async {
    final found = await repository.getCouponByCode('NOPE');
    expect(found, isNull);
  });

  test('fetchAllCoupons returns every coupon, newest first', () async {
    await repository.createCoupon(buildCoupon(id: 'OLD'));
    await repository.createCoupon(
      Coupon(id: 'NEW', type: CouponType.fixed, value: 5, createdAt: DateTime(2026, 6, 1)),
    );

    final all = await repository.fetchAllCoupons();

    expect(all, hasLength(2));
    expect(all.first.id, 'NEW');
  });

  test('setActive flips the isActive flag', () async {
    await repository.createCoupon(buildCoupon());

    await repository.setActive('SAVE20', false);

    final updated = await firestore.collection('coupons').doc('SAVE20').get();
    expect(updated.data()!['isActive'], isFalse);
  });

  test('deleteCoupon removes the document', () async {
    await repository.createCoupon(buildCoupon());

    await repository.deleteCoupon('SAVE20');

    final doc = await firestore.collection('coupons').doc('SAVE20').get();
    expect(doc.exists, isFalse);
  });
}
