// auth_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import 'user_profile_controller.dart';

class AuthController extends GetxController {
  AuthController({FirebaseAuth? auth, GetStorage? storage})
    : _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? GetStorage();

  static AuthController get instance => Get.find();

  final FirebaseAuth _auth;
  final GetStorage _storage;

  // Observable for current Firebase user
  Rxn<User> firebaseUser = Rxn<User>();

  final RxBool _isFirstTime = true.obs;
  final RxBool _isLoggedIn = false.obs;

  bool get isFirstTime => _isFirstTime.value;
  bool get isLoggedIn => _isLoggedIn.value;
  bool get isAdmin => Get.find<UserProfileController>().isAdmin;

  @override
  void onInit() {
    super.onInit();
    _loadLocalState();
    _bindFirebaseUserStream();
  }

  void _loadLocalState() {
    _isFirstTime.value = _storage.read('isFirstTime') ?? true;
  }

  void _bindFirebaseUserStream() {
    firebaseUser.bindStream(_auth.authStateChanges());

    ever(firebaseUser, (User? user) {
      if (user != null) {
        _isLoggedIn.value = true;
        _storage.write('isLoggedIn', true);
        Get.offAllNamed(AppRoutes.main);
      } else {
        _isLoggedIn.value = false;
        _storage.write('isLoggedIn', false);
      }
    });
  }

  void setFirstTimeDone() {
    _isFirstTime.value = false;
    _storage.write('isFirstTime', false);
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed(AppRoutes.signin);
  }

  // ==================== LOGIN ====================
  Future<String?> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Login failed. Please try again.';
    }
  }

  // ==================== REGISTER ====================
  Future<String?> registerUserAndStoreData({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;
      if (user == null) return 'Failed to create account.';

      // Delegate profile creation to the single owner of `users/{uid}` docs
      // instead of writing Firestore fields here too (previously duplicated).
      final profileError = await Get.find<UserProfileController>().createUserProfile(
        uid: user.uid,
        fullName: fullName.trim(),
        email: email.trim(),
        role: UserRole.user,
      );
      if (profileError != null) return profileError;

      await user.updateDisplayName(fullName.trim());
      await user.reload();

      setFirstTimeDone();

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      debugPrint('Registration error: $e');
      return 'Registration failed. Please try again.';
    }
  }

  // ==================== FORGOT PASSWORD ====================
  Future<String?> sendPasswordResetEmail({required String email}) async {
    try {
      final trimmedEmail = email.trim();

      if (trimmedEmail.isEmpty) {
        return 'Please enter your email address.';
      }

      if (!GetUtils.isEmail(trimmedEmail)) {
        return 'Please enter a valid email address.';
      }

      await _auth.sendPasswordResetEmail(email: trimmedEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      return 'Failed to send reset email. Check your connection.';
    }
  }

  // ==================== ERROR HANDLER ====================
  String _handleFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }
}
