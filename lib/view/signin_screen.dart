import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/auth_controller.dart';
import '../Controllers/user_profile_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/app_text_field.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();

  bool _isLoading = false;
  bool _isAdminLoading = false;
  String? _errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    final error = await _authController.loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    if (!mounted) return;

    // On success the AuthController's auth-state listener redirects to
    // AppRoutes.main automatically — nothing to do here but surface errors.
    setState(() {
      _isLoading = false;
      _errorText = error;
    });
  }

  Future<void> _adminSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAdminLoading = true;
      _errorText = null;
    });

    final error = await _authController.loginUser(
      email: emailController.text,
      password: passwordController.text,
    );

    if (error != null) {
      if (!mounted) return;
      setState(() {
        _isAdminLoading = false;
        _errorText = error;
      });
      return;
    }

    // AuthController's auth-state listener has already fired
    // Get.offAllNamed(AppRoutes.main) by this point (it reacts as soon as
    // Firebase's auth state updates), so this screen may already be
    // disposed — the redirect below must not be gated on `mounted`.
    final profileController = Get.find<UserProfileController>();
    await profileController.fetchUserProfile();

    if (!profileController.isAdmin) {
      await _authController.logout();
      if (mounted) {
        setState(() {
          _isAdminLoading = false;
          _errorText = 'This account does not have admin access.';
        });
      }
      return;
    }

    Get.offAllNamed(AppRoutes.adminDashboard);
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!GetUtils.isEmail(email)) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue shopping',
                  style: theme.textTheme.bodyLarge?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 48),

                AppTextField(
                  key: const Key('signin_email_field'),
                  controller: emailController,
                  label: 'Email',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  key: const Key('signin_password_field'),
                  controller: passwordController,
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorText != null) ...[
                  Text(
                    _errorText!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  const SizedBox(height: 16),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isLoading || _isAdminLoading) ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Sign In'),
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    key: const Key('admin_login_button'),
                    onPressed: (_isLoading || _isAdminLoading) ? null : _adminSignIn,
                    icon: _isAdminLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Icon(Icons.admin_panel_settings_outlined),
                    label: const Text('Login as Admin'),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Don't have an account?", style: theme.textTheme.bodyLarge),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.signup),
                      child: const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
