import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/user_profile_controller.dart';
import '../Controllers/auth_controller.dart';
import '../routes/app_routes.dart';

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = UserProfileController.instance;
    final authController = AuthController.instance;
    final theme = Theme.of(context);

    if (profileController.currentProfile.value == null && !profileController.isLoading.value) {
      profileController.fetchUserProfile();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Account'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.settings, size: 20),
            ),
            onPressed: () => Get.toNamed(AppRoutes.settings),
            tooltip: 'Settings',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final profile = profileController.currentProfile.value;
        final loading = profileController.isLoading.value;

        if (loading && profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final displayName = profile?.fullName ?? 'Guest User';
        final email = profile?.email ?? '';
        final photoUrl = profile?.photoUrl;
        final isAdmin = profileController.isAdmin;
        final isSeller = profileController.isSeller;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Profile card section
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/avaatr1.png') as ImageProvider,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () => Get.toNamed(AppRoutes.editProfile),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: const Text(
                          'Edit Profile',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Options list
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    _AccountOption(
                      icon: Icons.shopping_bag_outlined,
                      title: 'My Orders',
                      onTap: () => Get.toNamed(AppRoutes.myOrders),
                    ),
                    const Divider(height: 1),
                    if (isAdmin) ...[
                      _AccountOption(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Admin Dashboard',
                        onTap: () => Get.toNamed(AppRoutes.adminDashboard),
                      ),
                      const Divider(height: 1),
                    ] else if (isSeller) ...[
                      _AccountOption(
                        icon: Icons.storefront_outlined,
                        title: 'Seller Dashboard',
                        onTap: () => Get.toNamed(AppRoutes.sellerDashboard),
                      ),
                      const Divider(height: 1),
                    ] else ...[
                      _AccountOption(
                        icon: Icons.storefront_outlined,
                        title: 'Become a Seller',
                        onTap: () => Get.toNamed(AppRoutes.becomeSeller),
                      ),
                      const Divider(height: 1),
                    ],
                    _AccountOption(
                      icon: Icons.location_on_outlined,
                      title: 'Shipping Address',
                      onTap: () => Get.toNamed(AppRoutes.shippingAddress),
                    ),
                    const Divider(height: 1),
                    _AccountOption(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment Methods',
                      onTap: () => Get.toNamed(AppRoutes.paymentMethod),
                    ),
                    const Divider(height: 1),
                    _AccountOption(
                      icon: Icons.help_outline,
                      title: 'Help Center',
                      onTap: () => Get.toNamed(AppRoutes.helpCenter),
                    ),
                    const Divider(height: 1),
                    _AccountOption(
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => authController.logout(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}

class _AccountOption extends StatelessWidget {
  const _AccountOption({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: onTap,
    );
  }
}
