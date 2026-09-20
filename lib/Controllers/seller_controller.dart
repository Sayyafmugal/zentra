// seller_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/audit_log_entry.dart';
import '../models/seller.dart';
import '../models/seller_application.dart';
import '../models/user_profile.dart';
import '../repositories/audit_log_repository.dart';
import '../repositories/seller_application_repository.dart';
import '../repositories/seller_repository.dart';
import 'user_profile_controller.dart';

export '../models/seller.dart';
export '../models/seller_application.dart';

/// Owns the "become a seller" workflow: submitting an application, an
/// admin reviewing the queue, and the resulting `sellers/{uid}` record.
/// Deliberately separate from [UserProfileController] — that controller
/// owns "who am I", this one owns "how does someone become a seller."
class SellerController extends GetxController {
  SellerController({
    SellerRepository? sellerRepository,
    SellerApplicationRepository? applicationRepository,
    AuditLogRepository? auditLogRepository,
    FirebaseAuth? auth,
  }) : _sellerRepository = sellerRepository ?? SellerRepository(),
       _applicationRepository = applicationRepository ?? SellerApplicationRepository(),
       _auditLog = auditLogRepository ?? AuditLogRepository(),
       _auth = auth ?? FirebaseAuth.instance;

  static SellerController get instance => Get.find();

  final SellerRepository _sellerRepository;
  final SellerApplicationRepository _applicationRepository;
  final AuditLogRepository _auditLog;
  final FirebaseAuth _auth;

  // Best-effort — see AuditLogEntry's doc comment. Never lets a logging
  // failure surface as an error for the real action that triggered it.
  Future<void> _logAudit({required String action, required String summary, String? targetId}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _auditLog.logAction(
        AuditLogEntry(
          id: _auditLog.newLogId(),
          actorId: user.uid,
          actorEmail: user.email ?? '',
          action: action,
          summary: summary,
          targetId: targetId,
          createdAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // Swallowed deliberately — see the doc comment above.
    }
  }

  final Rx<SellerApplication?> myPendingApplication = Rx<SellerApplication?>(null);
  final RxList<SellerApplication> pendingApplications = <SellerApplication>[].obs;
  final RxList<Seller> allSellers = <Seller>[].obs;
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

  // ==================== APPLY (any signed-in user) ====================

  Future<void> fetchMyPendingApplication() async {
    if (currentUserId == null) return;
    myPendingApplication.value = await _applicationRepository.getPendingApplicationForUser(
      currentUserId!,
    );
  }

  Future<String?> submitSellerApplication({
    required String businessName,
    required String businessDescription,
    required String contactEmail,
    required String contactPhone,
  }) async {
    if (currentUserId == null) return 'Please login to apply as a seller.';

    try {
      isLoading.value = true;

      final existing = await _applicationRepository.getPendingApplicationForUser(currentUserId!);
      if (existing != null) {
        isLoading.value = false;
        return 'You already have a pending seller application.';
      }

      final application = SellerApplication(
        id: _applicationRepository.newApplicationId(),
        userId: currentUserId!,
        businessName: businessName.trim(),
        businessDescription: businessDescription.trim(),
        contactEmail: contactEmail.trim(),
        contactPhone: contactPhone.trim(),
        submittedAt: DateTime.now(),
      );

      await _applicationRepository.submitApplication(application);
      myPendingApplication.value = application;
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to submit application: $e';
    }
  }

  // ==================== ADMIN REVIEW ====================

  Future<void> fetchPendingApplications() async {
    try {
      isLoading.value = true;
      pendingApplications.value = await _applicationRepository.fetchPendingApplications();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  /// Approves an application: promotes the applicant's role, creates their
  /// `sellers/{uid}` record, then marks the application reviewed — in that
  /// order, so a failure partway through never leaves someone able to write
  /// products without the role update having actually landed (see the
  /// ordering note in firestore.rules' isActiveSeller).
  Future<String?> approveApplication(SellerApplication application) async {
    if (currentUserId == null) return 'Please login as an admin.';

    try {
      isLoading.value = true;

      final roleError = await UserProfileController.instance.setUserRole(
        application.userId,
        UserRole.seller,
      );
      if (roleError != null) {
        isLoading.value = false;
        return roleError;
      }

      await _sellerRepository.createFromApproval(
        Seller(
          id: application.userId,
          userId: application.userId,
          businessName: application.businessName,
          businessDescription: application.businessDescription,
          contactEmail: application.contactEmail,
          contactPhone: application.contactPhone,
          createdAt: DateTime.now(),
          approvedBy: currentUserId!,
        ),
      );

      await _applicationRepository.reviewApplication(
        applicationId: application.id,
        status: SellerApplicationStatus.approved,
        reviewedBy: currentUserId!,
      );

      pendingApplications.removeWhere((a) => a.id == application.id);
      isLoading.value = false;

      await _logAudit(
        action: 'seller.approved',
        summary: '${application.businessName} approved as a seller.',
        targetId: application.userId,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to approve application: $e';
    }
  }

  Future<String?> rejectApplication(SellerApplication application, {String? reason}) async {
    if (currentUserId == null) return 'Please login as an admin.';

    try {
      isLoading.value = true;

      await _applicationRepository.reviewApplication(
        applicationId: application.id,
        status: SellerApplicationStatus.rejected,
        reviewedBy: currentUserId!,
        rejectionReason: reason,
      );

      pendingApplications.removeWhere((a) => a.id == application.id);
      isLoading.value = false;

      await _logAudit(
        action: 'seller.application_rejected',
        summary: reason == null || reason.isEmpty
            ? '${application.businessName} application rejected.'
            : '${application.businessName} application rejected: $reason',
        targetId: application.userId,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to reject application: $e';
    }
  }

  // ==================== SELLER MANAGEMENT (admin) ====================

  Future<void> fetchAllSellers() async {
    try {
      isLoading.value = true;
      allSellers.value = await _sellerRepository.fetchAllSellers();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Future<String?> suspendSeller(String sellerId, {String? reason}) async {
    try {
      await _sellerRepository.updateStatus(sellerId, SellerStatus.suspended, reason: reason);
      final index = allSellers.indexWhere((s) => s.id == sellerId);
      final businessName = index == -1 ? sellerId : allSellers[index].businessName;
      if (index != -1) {
        allSellers[index] = allSellers[index].copyWith(
          status: SellerStatus.suspended,
          suspensionReason: reason,
        );
      }

      await _logAudit(
        action: 'seller.suspended',
        summary: reason == null || reason.isEmpty
            ? '$businessName suspended.'
            : '$businessName suspended: $reason',
        targetId: sellerId,
      );

      return null;
    } catch (e) {
      return 'Failed to suspend seller: $e';
    }
  }

  Future<String?> reactivateSeller(String sellerId) async {
    try {
      await _sellerRepository.updateStatus(sellerId, SellerStatus.active);
      final index = allSellers.indexWhere((s) => s.id == sellerId);
      final businessName = index == -1 ? sellerId : allSellers[index].businessName;
      if (index != -1) {
        allSellers[index] = allSellers[index].copyWith(status: SellerStatus.active);
      }

      await _logAudit(
        action: 'seller.reactivated',
        summary: '$businessName reactivated.',
        targetId: sellerId,
      );

      return null;
    } catch (e) {
      return 'Failed to reactivate seller: $e';
    }
  }
}
