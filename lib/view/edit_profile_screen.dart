import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/user_profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  final UserProfileController _profileController = UserProfileController.instance;

  @override
  void initState() {
    super.initState();
    // Load profile data
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile = _profileController.currentProfile.value;
    if (profile != null) {
      _nameCtrl.text = profile.fullName;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone ?? '';
    } else {
      // Fetch profile if not loaded
      _profileController.fetchUserProfile();
      // Wait a bit and try again
      Future.delayed(const Duration(milliseconds: 500), () {
        final profile = _profileController.currentProfile.value;
        if (profile != null) {
          setState(() {
            _nameCtrl.text = profile.fullName;
            _emailCtrl.text = profile.email;
            _phoneCtrl.text = profile.phone ?? '';
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    // Placeholder for image picker. Hook up image_picker or similar later.
    Get.snackbar('Info', 'Image picker feature coming soon');
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final error = await _profileController.updateUserProfile(
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );

    if (error == null) {
      Get.back();
    } else {
      Get.snackbar('Error', error, backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: EditProfileScreen.primaryColor, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // Avatar with camera button
            Obx(() {
              final profile = _profileController.currentProfile.value;
              final photoUrl = profile?.photoUrl;
              
              return Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: EditProfileScreen.primaryColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/avaatr1.png') as ImageProvider,
                      ),
                    ),
                    InkWell(
                      onTap: _pickAvatar,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: EditProfileScreen.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Full Name
            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(label: 'Full Name', icon: Icons.person_outline),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),

            // Email
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: _inputDecoration(label: 'Email', icon: Icons.mail_outline),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return emailOk ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 14),

            // Phone
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: _inputDecoration(label: 'Phone Number', icon: Icons.phone_outlined),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
                return v.trim().length < 6 ? 'Enter a valid phone number' : null;
              },
            ),
            const SizedBox(height: 28),

            // Save button
            Obx(() {
              final isLoading = _profileController.isLoading.value;
              
              return SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EditProfileScreen.primaryColor,
                    disabledBackgroundColor: EditProfileScreen.primaryColor.withOpacity(0.6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.onPrimary),
                      strokeWidth: 2.4,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}