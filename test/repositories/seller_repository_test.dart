import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/seller.dart';
import 'package:zentra_0/repositories/seller_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SellerRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = SellerRepository(firestore: firestore);
  });

  Seller buildSeller({String id = 'seller-1', SellerStatus status = SellerStatus.active}) {
    return Seller(
      id: id,
      userId: id,
      businessName: 'Acme Shoes',
      contactEmail: 'acme@example.com',
      contactPhone: '555-1234',
      status: status,
      createdAt: DateTime(2026, 1, 1),
      approvedBy: 'admin-1',
    );
  }

  test('createFromApproval then getSellerById returns the seller', () async {
    await repository.createFromApproval(buildSeller());

    final seller = await repository.getSellerById('seller-1');

    expect(seller, isNotNull);
    expect(seller!.businessName, 'Acme Shoes');
    expect(seller.isActive, isTrue);
  });

  test('getSellerById returns null for a seller that does not exist', () async {
    final seller = await repository.getSellerById('missing');
    expect(seller, isNull);
  });

  test('updateStatus suspends a seller and records the reason', () async {
    await repository.createFromApproval(buildSeller());

    await repository.updateStatus('seller-1', SellerStatus.suspended, reason: 'Policy violation');
    final seller = await repository.getSellerById('seller-1');

    expect(seller?.status, SellerStatus.suspended);
    expect(seller?.suspensionReason, 'Policy violation');
  });

  test('fetchAllSellers returns every seller', () async {
    await repository.createFromApproval(buildSeller(id: 'seller-1'));
    await repository.createFromApproval(buildSeller(id: 'seller-2'));

    final sellers = await repository.fetchAllSellers();

    expect(sellers, hasLength(2));
  });
}
