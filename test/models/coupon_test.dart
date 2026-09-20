import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/coupon.dart';

void main() {
  group('Coupon.normalize', () {
    test('trims and uppercases the code', () {
      expect(Coupon.normalize('  save20 '), 'SAVE20');
    });
  });

  group('Coupon.discountFor', () {
    test('percentage coupon computes a fraction of the subtotal', () {
      final coupon = Coupon(
        id: 'SAVE20',
        type: CouponType.percentage,
        value: 20,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.discountFor(100), 20);
    });

    test('fixed coupon discounts a flat amount regardless of subtotal', () {
      final coupon = Coupon(
        id: 'FLAT10',
        type: CouponType.fixed,
        value: 10,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.discountFor(100), 10);
    });

    test('percentage coupon is capped by maxDiscount', () {
      final coupon = Coupon(
        id: 'SAVE50',
        type: CouponType.percentage,
        value: 50,
        maxDiscount: 15,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.discountFor(100), 15);
    });

    test('returns 0 when the subtotal is below minOrderAmount', () {
      final coupon = Coupon(
        id: 'BIG',
        type: CouponType.fixed,
        value: 10,
        minOrderAmount: 50,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.discountFor(30), 0);
    });

    test('never discounts more than the subtotal itself (fixed coupon larger than order)', () {
      final coupon = Coupon(
        id: 'HUGE',
        type: CouponType.fixed,
        value: 1000,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.discountFor(30), 30);
    });
  });

  group('Coupon.isCurrentlyValid', () {
    test('false when isActive is false', () {
      final coupon = Coupon(
        id: 'OFF',
        type: CouponType.fixed,
        value: 5,
        isActive: false,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.isCurrentlyValid, isFalse);
    });

    test('false once past expiresAt', () {
      final coupon = Coupon(
        id: 'EXPIRED',
        type: CouponType.fixed,
        value: 5,
        expiresAt: DateTime(2000, 1, 1),
        createdAt: DateTime(1999, 1, 1),
      );

      expect(coupon.isCurrentlyValid, isFalse);
    });

    test('false once usedCount reaches usageLimit', () {
      final coupon = Coupon(
        id: 'LIMITED',
        type: CouponType.fixed,
        value: 5,
        usageLimit: 2,
        usedCount: 2,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.isCurrentlyValid, isFalse);
      expect(coupon.isExhausted, isTrue);
    });

    test('true for an active, unexpired, unexhausted coupon', () {
      final coupon = Coupon(
        id: 'GOOD',
        type: CouponType.percentage,
        value: 10,
        expiresAt: DateTime(2999, 1, 1),
        usageLimit: 100,
        usedCount: 1,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(coupon.isCurrentlyValid, isTrue);
    });
  });

  group('Coupon toMap/fromMap round-trip', () {
    test('preserves every field', () {
      final coupon = Coupon(
        id: 'SAVE20',
        type: CouponType.percentage,
        value: 20,
        minOrderAmount: 25,
        maxDiscount: 30,
        expiresAt: DateTime(2026, 12, 31),
        usageLimit: 100,
        usedCount: 3,
        isActive: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final roundTripped = Coupon.fromMap(coupon.toMap());

      expect(roundTripped, coupon);
    });
  });
}
