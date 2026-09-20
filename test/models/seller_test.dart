import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/seller.dart';

void main() {
  group('Seller', () {
    final seller = Seller(
      id: 'seller-1',
      userId: 'seller-1',
      businessName: 'Acme Shoes',
      businessDescription: 'Footwear for everyone',
      contactEmail: 'acme@example.com',
      contactPhone: '555-1234',
      createdAt: DateTime(2026, 1, 1),
      approvedBy: 'admin-1',
    );

    test('round-trips through toMap/fromMap', () {
      final restored = Seller.fromMap(seller.toMap());
      expect(restored, equals(seller));
    });

    test('defaults to active status', () {
      expect(seller.isActive, isTrue);
    });

    test('copyWith can suspend a seller with a reason', () {
      final suspended = seller.copyWith(
        status: SellerStatus.suspended,
        suspendedAt: DateTime(2026, 2, 1),
        suspensionReason: 'Policy violation',
      );
      expect(suspended.isActive, isFalse);
      expect(suspended.suspensionReason, 'Policy violation');
      expect(seller.isActive, isTrue, reason: 'original must be unchanged');
    });

    test('fromMap defaults an unrecognized status to active', () {
      final map = seller.toMap();
      map['status'] = 'not-a-real-status';
      final restored = Seller.fromMap(map);
      expect(restored.status, SellerStatus.active);
    });
  });
}
