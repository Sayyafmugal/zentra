import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/user_profile_controller.dart';
import '../services/image_storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  final UserProfileController _profileController = UserProfileController.instance;
  final ImageStorageService _imageService = UnconfiguredImageStorageService();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profile = _profileController.currentProfile.value;
    if (profile != null) {
      _nameCtrl.text = profile.fullName;
      _emailCtrl.text = profile.email;
      _phoneCtrl.text = profile.phone ?? '';
    } else {
      _profileController.fetchUserProfile();
      Future.delayed(const Duration(milliseconds: 500), () {
        final loaded = _profileController.currentProfile.value;
        if (loaded != null && mounted) {
          setState(() {
            _nameCtrl.text = loaded.fullName;
            _emailCtrl.text = loaded.email;
            _phoneCtrl.text = loaded.phone ?? '';
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

  Future<void> _editAvatarUrl() async {
    final urlCtrl = TextEditingController(
      text: _profileController.currentProfile.value?.photoUrl ?? '',
    );
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Profile photo URL'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: urlCtrl,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Image URL',
              hintText: 'https://example.com/photo.jpg',
            ),
            validator: (v) => _imageService.validateImageUrl(v ?? '') == null
                ? 'Enter a valid http/https image URL'
                : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, _imageService.validateImageUrl(urlCtrl.text));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _profileController.updateProfilePhoto(result);
    }
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text('Edit Profile'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
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
                        border: Border.all(color: theme.colorScheme.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 56,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/avaatr1.png') as ImageProvider,
                      ),
                    ),
                    InkWell(
                      onTap: _editAvatarUrl,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your email';
                final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                return emailOk ? null : 'Enter a valid email';
              },
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter your phone number';
                return v.trim().length < 6 ? 'Enter a valid phone number' : null;
              },
            ),
            const SizedBox(height: 28),

            Obx(() {
              final isLoading = _profileController.isLoading.value;
              return SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : const Text('Save Changes'),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
