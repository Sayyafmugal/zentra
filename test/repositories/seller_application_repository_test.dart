import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zentra_0/models/seller_application.dart';
import 'package:zentra_0/repositories/seller_application_repository.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late SellerApplicationRepository repository;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = SellerApplicationRepository(firestore: firestore);
  });

  SellerApplication buildApplication({
    String id = 'app-1',
    String userId = 'u1',
    SellerApplicationStatus status = SellerApplicationStatus.pending,
  }) {
    return SellerApplication(
      id: id,
      userId: userId,
      businessName: 'Acme Shoes',
      businessDescription: 'Footwear for everyone',
      contactEmail: 'acme@example.com',
      contactPhone: '555-1234',
      status: status,
      submittedAt: DateTime(2026, 1, 1),
    );
  }

  test('submitApplication then getApplicationById returns it', () async {
    await repository.submitApplication(buildApplication());

    final application = await repository.getApplicationById('app-1');

    expect(application, isNotNull);
    expect(application!.businessName, 'Acme Shoes');
    expect(application.isPending, isTrue);
  });

  test('getPendingApplicationForUser finds only that user\'s pending application', () async {
    await repository.submitApplication(buildApplication(id: 'app-1', userId: 'u1'));
    await repository.submitApplication(buildApplication(id: 'app-2', userId: 'u2'));

    final pending = await repository.getPendingApplicationForUser('u1');

    expect(pending?.id, 'app-1');
  });

  test('getPendingApplicationForUser ignores already-reviewed applications', () async {
    await repository.submitApplication(
      buildApplication(id: 'app-1', userId: 'u1', status: SellerApplicationStatus.approved),
    );

    final pending = await repository.getPendingApplicationForUser('u1');

    expect(pending, isNull);
  });

  test('reviewApplication approves and records who reviewed it', () async {
    await repository.submitApplication(buildApplication());

    await repository.reviewApplication(
      applicationId: 'app-1',
      status: SellerApplicationStatus.approved,
      reviewedBy: 'admin-1',
    );
    final application = await repository.getApplicationById('app-1');

    expect(application?.status, SellerApplicationStatus.approved);
    expect(application?.reviewedBy, 'admin-1');
  });

  test('fetchPendingApplications only returns pending ones', () async {
    await repository.submitApplication(buildApplication(id: 'app-1'));
    await repository.submitApplication(
      buildApplication(id: 'app-2', status: SellerApplicationStatus.rejected),
    );

    final pending = await repository.fetchPendingApplications();

    expect(pending, hasLength(1));
    expect(pending.first.id, 'app-1');
  });
}
