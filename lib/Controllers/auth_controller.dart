// auth_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  static AuthController get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GetStorage _storage = GetStorage();

  // Observable for current Firebase user
  Rxn<User> firebaseUser = Rxn<User>();

  // Local state
  final RxBool _isFirstTime = true.obs;
  final RxBool _isLoggedIn = false.obs;

  bool get isFirstTime => _isFirstTime.value;
  bool get isLoggedIn => _isLoggedIn.value;

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
        Get.offAllNamed('/home');
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
    Get.offAllNamed('/signin');
  }

  // ==================== LOGIN ====================
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      Get.snackbar(
        'Welcome Back!',
        'You are now logged in.',
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
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

      // Save user data to Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'photoUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
        'isFirstTime': true,
      });

      await user.updateDisplayName(fullName.trim());
      await user.reload();

      setFirstTimeDone();

      Get.snackbar(
        'Welcome!',
        'Account created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _handleFirebaseError(e);
    } catch (e) {
      print('Registration error: $e');
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

      Get.snackbar(
        'Email Sent!',
        'Password reset link sent to $trimmedEmail',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.9),
        colorText: Colors.white,
        duration: const Duration(seconds: 6),
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );

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
        return 'Incorrect password.';
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