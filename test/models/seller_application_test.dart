import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/seller_application.dart';

void main() {
  group('SellerApplication', () {
    final application = SellerApplication(
      id: 'app-1',
      userId: 'u1',
      businessName: 'Acme Shoes',
      businessDescription: 'Footwear for everyone',
      contactEmail: 'acme@example.com',
      contactPhone: '555-1234',
      submittedAt: DateTime(2026, 1, 1),
    );

    test('round-trips through toMap/fromMap', () {
      final restored = SellerApplication.fromMap(application.toMap());
      expect(restored, equals(application));
    });

    test('defaults to pending status on submission', () {
      expect(application.isPending, isTrue);
      expect(application.status, SellerApplicationStatus.pending);
    });

    test('copyWith records an approval decision without mutating the original', () {
      final approved = application.copyWith(
        status: SellerApplicationStatus.approved,
        reviewedAt: DateTime(2026, 1, 2),
        reviewedBy: 'admin-1',
      );
      expect(approved.isPending, isFalse);
      expect(approved.reviewedBy, 'admin-1');
      expect(application.isPending, isTrue, reason: 'original must be unchanged');
    });

    test('copyWith records a rejection with a reason', () {
      final rejected = application.copyWith(
        status: SellerApplicationStatus.rejected,
        reviewedBy: 'admin-1',
        rejectionReason: 'Incomplete business information',
      );
      expect(rejected.status, SellerApplicationStatus.rejected);
      expect(rejected.rejectionReason, 'Incomplete business information');
    });
  });
}
