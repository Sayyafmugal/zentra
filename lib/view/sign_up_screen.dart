import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zentra_0/Controllers/auth_controller.dart'; // Import your controller
import 'signin_screen.dart';
// Removed firebase_auth and cloud_firestore imports

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const Color primaryColor = Color(0xFFFF5200);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // Get the AuthController instance
  final AuthController _authController = Get.find<AuthController>();

  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final fullName = nameController.text.trim();

    // Basic Validation checks
    if (password != confirmPassword) {
      Get.snackbar(
          "Error",
          "Passwords do not match.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.withOpacity(0.8),
          colorText: Colors.white
      );
      return;
    }

    if (password.length < 6) {
      Get.snackbar("Error", "Password must be at least 6 characters.", snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red.withOpacity(0.8), colorText: Colors.white);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 🚀 DELEGATE LOGIC TO AUTH CONTROLLER 🚀
    String? error = await _authController.registerUserAndStoreData(
      email: email,
      password: password,
      fullName: fullName,
    );

    // After attempting registration, always unset loading state
    setState(() {
      _isLoading = false;
    });

    // Handle errors returned by the controller
    if (error != null) {
      Get.snackbar(
          "Registration Failed",
          error,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: primaryColor.withOpacity(0.8),
          colorText: Colors.white
      );
    } else {
      // Success: Show success message
      Get.snackbar(
          'Success',
          'Account created! Redirecting...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white
      );
      // If successful, the AuthController's stream listener automatically routes to HomeTab.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          // Use GetX to navigate back to the SigninScreen
          onPressed: () => Get.off(() => const SigninScreen()),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              const Text('Sign up to get started', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),

              // Full Name
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Email
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.mail_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Password
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 40),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),

              // Sign In Prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  TextButton(
                    // Use GetX navigation to SigninScreen
                    onPressed: () => Get.off(() => const SigninScreen()),
                    child: const Text('Sign In', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}