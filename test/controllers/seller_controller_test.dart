import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zentra_0/Controllers/seller_controller.dart';
import 'package:zentra_0/Controllers/user_profile_controller.dart';
import 'package:zentra_0/models/audit_log_entry.dart';
import 'package:zentra_0/models/seller.dart';
import 'package:zentra_0/models/seller_application.dart';
import 'package:zentra_0/repositories/audit_log_repository.dart';
import 'package:zentra_0/repositories/seller_application_repository.dart';
import 'package:zentra_0/repositories/seller_repository.dart';
import 'package:zentra_0/repositories/user_profile_repository.dart';

class MockSellerRepository extends Mock implements SellerRepository {}

class MockSellerApplicationRepository extends Mock implements SellerApplicationRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockAuditLogRepository extends Mock implements AuditLogRepository {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

SellerApplication _buildApplication({
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

void main() {
  late MockSellerRepository sellerRepo;
  late MockSellerApplicationRepository applicationRepo;
  late MockUserProfileRepository profileRepo;
  late MockFirebaseAuth sellerAuth;
  late MockFirebaseAuth profileAuth;
  late SellerController controller;

  setUpAll(() {
    registerFallbackValue(
      Seller(
        id: 'x',
        userId: 'x',
        businessName: 'x',
        contactEmail: 'x',
        contactPhone: 'x',
        createdAt: DateTime(2026, 1, 1),
        approvedBy: 'x',
      ),
    );
    registerFallbackValue(SellerApplicationStatus.pending);
    registerFallbackValue(_buildApplication());
    registerFallbackValue(
      AuditLogEntry(
        id: 'x',
        actorId: 'x',
        actorEmail: 'x',
        action: 'x',
        summary: 'x',
        createdAt: DateTime(2026, 1, 1),
      ),
    );
  });

  setUp(() {
    sellerRepo = MockSellerRepository();
    applicationRepo = MockSellerApplicationRepository();
    profileRepo = MockUserProfileRepository();

    final auditLogRepo = MockAuditLogRepository();
    when(() => auditLogRepo.newLogId()).thenReturn('log-1');
    when(() => auditLogRepo.logAction(any())).thenAnswer((_) async {});

    sellerAuth = MockFirebaseAuth();
    final adminUser = MockUser();
    when(() => adminUser.uid).thenReturn('admin-1');
    when(() => adminUser.email).thenReturn('admin@example.com');
    when(() => sellerAuth.currentUser).thenReturn(adminUser);

    profileAuth = MockFirebaseAuth();
    when(() => profileAuth.currentUser).thenReturn(null);

    // UserProfileController.setUserRole is called internally by
    // SellerController.approveApplication via Get.find(), so it must be
    // registered too.
    Get.put<UserProfileController>(
      UserProfileController(repository: profileRepo, auth: profileAuth, auditLogRepository: auditLogRepo),
    );

    controller = SellerController(
      sellerRepository: sellerRepo,
      applicationRepository: applicationRepo,
      auth: sellerAuth,
      auditLogRepository: auditLogRepo,
    );
  });

  tearDown(Get.reset);

  group('SellerController.submitSellerApplication', () {
    testWidgets('submits a new application when none is pending', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
      when(() => applicationRepo.getPendingApplicationForUser(any())).thenAnswer((_) async => null);
      when(() => applicationRepo.newApplicationId()).thenReturn('app-1');
      when(() => applicationRepo.submitApplication(any())).thenAnswer((_) async {});

      final auth = sellerAuth;
      final user = MockUser();
      when(() => user.uid).thenReturn('u1');
      when(() => auth.currentUser).thenReturn(user);

      final error = await controller.submitSellerApplication(
        businessName: 'Acme Shoes',
        businessDescription: 'Footwear',
        contactEmail: 'acme@example.com',
        contactPhone: '555-1234',
      );
      await tester.pump(const Duration(seconds: 5));

      expect(error, isNull);
      expect(controller.myPendingApplication.value?.businessName, 'Acme Shoes');
      verify(() => applicationRepo.submitApplication(any())).called(1);
    });

    test('refuses to submit a second application while one is already pending', () async {
      final user = MockUser();
      when(() => user.uid).thenReturn('u1');
      when(() => sellerAuth.currentUser).thenReturn(user);
      when(
        () => applicationRepo.getPendingApplicationForUser('u1'),
      ).thenAnswer((_) async => _buildApplication());

      final error = await controller.submitSellerApplication(
        businessName: 'Acme Shoes',
        businessDescription: 'Footwear',
        contactEmail: 'acme@example.com',
        contactPhone: '555-1234',
      );

      expect(error, contains('already have a pending'));
      verifyNever(() => applicationRepo.submitApplication(any()));
    });
  });

  group('SellerController.approveApplication', () {
    testWidgets(
      'promotes the role, creates the seller record, then marks the application reviewed',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
        when(() => profileRepo.updateProfile('u1', {'role': 'seller'})).thenAnswer((_) async {});
        when(() => sellerRepo.createFromApproval(any())).thenAnswer((_) async {});
        when(
          () => applicationRepo.reviewApplication(
            applicationId: any(named: 'applicationId'),
            status: any(named: 'status'),
            reviewedBy: any(named: 'reviewedBy'),
            rejectionReason: any(named: 'rejectionReason'),
          ),
        ).thenAnswer((_) async {});

        final application = _buildApplication();
        final error = await controller.approveApplication(application);
        await tester.pump(const Duration(seconds: 5));

        expect(error, isNull);
        verify(() => profileRepo.updateProfile('u1', {'role': 'seller'})).called(1);
        verify(() => sellerRepo.createFromApproval(any())).called(1);
        verify(
          () => applicationRepo.reviewApplication(
            applicationId: 'app-1',
            status: SellerApplicationStatus.approved,
            reviewedBy: 'admin-1',
            rejectionReason: null,
          ),
        ).called(1);
      },
    );

    test('never creates the seller record if the role update fails', () async {
      when(() => profileRepo.updateProfile(any(), any())).thenThrow(Exception('permission-denied'));

      final application = _buildApplication();
      final error = await controller.approveApplication(application);

      expect(error, isNotNull);
      verifyNever(() => sellerRepo.createFromApproval(any()));
      verifyNever(
        () => applicationRepo.reviewApplication(
          applicationId: any(named: 'applicationId'),
          status: any(named: 'status'),
          reviewedBy: any(named: 'reviewedBy'),
        ),
      );
    });
  });

  group('SellerController.rejectApplication', () {
    test(
      'marks the application rejected with a reason and removes it from the pending list',
      () async {
        when(
          () => applicationRepo.reviewApplication(
            applicationId: any(named: 'applicationId'),
            status: any(named: 'status'),
            reviewedBy: any(named: 'reviewedBy'),
            rejectionReason: any(named: 'rejectionReason'),
          ),
        ).thenAnswer((_) async {});

        final application = _buildApplication();
        controller.pendingApplications.add(application);

        final error = await controller.rejectApplication(application, reason: 'Incomplete info');

        expect(error, isNull);
        expect(controller.pendingApplications, isEmpty);
        verify(
          () => applicationRepo.reviewApplication(
            applicationId: 'app-1',
            status: SellerApplicationStatus.rejected,
            reviewedBy: 'admin-1',
            rejectionReason: 'Incomplete info',
          ),
        ).called(1);
      },
    );
  });
}
