// user_profile_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data);
  }

  UserProfile copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class UserProfileController extends GetxController {
  static UserProfileController get instance => Get.find();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Rx<UserProfile?> currentProfile = Rx<UserProfile?>(null);
  final RxBool isLoading = false.obs;

  String? get currentUserId => _auth.currentUser?.uid;

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
  }) async {
    try {
      isLoading.value = true;

      final profile = UserProfile(
        uid: uid,
        fullName: fullName,
        email: email,
        phone: phone,
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(profile.toMap());

      currentProfile.value = profile;
      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Profile created successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

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

      final doc = await _firestore.collection('users').doc(currentUserId).get();

      if (doc.exists) {
        currentProfile.value = UserProfile.fromFirestore(doc);
      } else {
        // Create profile if it doesn't exist
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
      Get.snackbar(
        'Error',
        'Failed to fetch profile: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Stream user profile for real-time updates
  Stream<UserProfile?> getUserProfileStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
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

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (fullName != null) {
        updateData['fullName'] = fullName.trim();
        // Also update Firebase Auth display name
        await _auth.currentUser?.updateDisplayName(fullName.trim());
      }

      if (email != null) {
        updateData['email'] = email.trim();
        // Note: Updating email in Firebase Auth requires re-authentication
        // For security, we only update it in Firestore here
        // To update Firebase Auth email, use: verifyBeforeUpdateEmail() after re-authentication
      }

      if (phone != null) {
        updateData['phone'] = phone.trim();
      }

      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
      }

      await _firestore.collection('users').doc(currentUserId).update(updateData);

      // Reload current profile
      await fetchUserProfile();

      isLoading.value = false;

      Get.snackbar(
        'Success!',
        'Profile updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to update profile: $e';
    }
  }

  // Update profile photo
  Future<String?> updateProfilePhoto(String photoUrl) async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      await _firestore.collection('users').doc(currentUserId).update({
        'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _auth.currentUser?.updatePhotoURL(photoUrl);
      await fetchUserProfile();

      return null;
    } catch (e) {
      return 'Failed to update photo: $e';
    }
  }

  // ==================== DELETE ====================
  Future<String?> deleteUserProfile() async {
    try {
      if (currentUserId == null) {
        return 'User not logged in';
      }

      isLoading.value = true;

      await _firestore.collection('users').doc(currentUserId).delete();

      currentProfile.value = null;
      isLoading.value = false;

      Get.snackbar(
        'Deleted',
        'Profile deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to delete profile: $e';
    }
  }
}

