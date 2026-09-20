// user_profile_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/audit_log_entry.dart';
import '../models/user_profile.dart';
import '../repositories/audit_log_repository.dart';
import '../repositories/user_profile_repository.dart';

export '../models/user_profile.dart';

class UserProfileController extends GetxController {
  UserProfileController({
    UserProfileRepository? repository,
    FirebaseAuth? auth,
    AuditLogRepository? auditLogRepository,
  }) : _repository = repository ?? UserProfileRepository(),
       _auth = auth ?? FirebaseAuth.instance,
       _auditLog = auditLogRepository ?? AuditLogRepository();

  static UserProfileController get instance => Get.find();

  final UserProfileRepository _repository;
  final FirebaseAuth _auth;
  final AuditLogRepository _auditLog;

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

  final Rx<UserProfile?> currentProfile = Rx<UserProfile?>(null);
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;
  bool get isAdmin => currentProfile.value?.isAdmin ?? false;
  bool get isSeller => currentProfile.value?.isSeller ?? false;
  bool get canManageProducts => currentProfile.value?.canManageProducts ?? false;

  @override
  void onInit() {
    super.onInit();
    if (currentUserId != null) {
      fetchUserProfile();
    }
  }

  // ==================== CREATE ====================
  Future<String?> createUserProfile({
    required String uid,
    required String fullName,
    required String email,
    String? phone,
    String? photoUrl,
    UserRole role = UserRole.user,
  }) async {
    try {
      isLoading.value = true;

      final profile = UserProfile(
        uid: uid,
        fullName: fullName,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
        role: role,
        createdAt: DateTime.now(),
      );

      await _repository.createProfile(profile);

      currentProfile.value = profile;
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to create profile: $e';
    }
  }

  // ==================== READ ====================
  Future<void> fetchUserProfile() async {
    try {
      if (currentUserId == null) return;

      isLoading.value = true;
      final profile = await _repository.fetchProfile(currentUserId!);

      if (profile != null) {
        currentProfile.value = profile;
      } else {
        final user = _auth.currentUser;
        if (user != null) {
          await createUserProfile(
            uid: user.uid,
            fullName: user.displayName ?? 'User',
            email: user.email ?? '',
            photoUrl: user.photoURL,
          );
        }
      }

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Stream<UserProfile?> getUserProfileStream() {
    if (currentUserId == null) return Stream.value(null);
    return _repository.watchProfile(currentUserId!);
  }

  // ==================== UPDATE ====================
  Future<String?> updateUserProfile({
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      isLoading.value = true;

      final updateData = <String, dynamic>{};

      if (fullName != null) {
        updateData['fullName'] = fullName.trim();
        await _auth.currentUser?.updateDisplayName(fullName.trim());
      }
      if (email != null) {
        updateData['email'] = email.trim();
      }
      if (phone != null) {
        updateData['phone'] = phone.trim();
      }
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      await _repository.updateProfile(currentUserId!, updateData);
      await fetchUserProfile();

      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update profile: $e';
    }
  }

  Future<String?> updateProfilePhoto(String photoUrl) async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      await _repository.updateProfile(currentUserId!, {'photoUrl': photoUrl});
      await _auth.currentUser?.updatePhotoURL(photoUrl);
      await fetchUserProfile();

      return null;
    } catch (e) {
      return 'Failed to update photo: $e';
    }
  }

  /// Admin-only: changes another user's role (e.g. approving them as a
  /// seller). Firestore rules independently require the caller to already
  /// be an admin to write `role` on any profile but their own — this method
  /// doesn't check that itself, it just fails at the database if the caller
  /// isn't actually one.
  Future<String?> setUserRole(String uid, UserRole role) async {
    try {
      await _repository.updateProfile(uid, {'role': role.name});
      await _logAudit(action: 'user.role_changed', summary: 'Role changed to ${role.name}.', targetId: uid);
      return null;
    } catch (e) {
      return 'Failed to update role: $e';
    }
  }

  // ==================== DELETE ====================
  Future<String?> deleteUserProfile() async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      isLoading.value = true;
      await _repository.deleteProfile(currentUserId!);

      currentProfile.value = null;
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete profile: $e';
    }
  }
}
