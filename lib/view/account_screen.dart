import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/user_profile_controller.dart';
import '../Controllers/auth_controller.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/role_preview_controller.dart';
import '../Utils/app_colors.dart';
import '../models/order.dart';
import '../routes/app_routes.dart';
import '../widgets/product_image.dart';
import '../widgets/app_toast.dart';

const _kForwardStates = [
  OrderStatus.pendingPayment,
  OrderStatus.paid,
  OrderStatus.processing,
  OrderStatus.packed,
  OrderStatus.shipped,
  OrderStatus.outForDelivery,
  OrderStatus.delivered,
];

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = UserProfileController.instance;
    final authController = AuthController.instance;
    final orderController = OrderController.instance;
    final rolePreview = RolePreviewController.instance;
    final theme = Theme.of(context);

    if (profileController.currentProfile.value == null && !profileController.isLoading.value) {
      profileController.fetchUserProfile();
    }
    if (orderController.orders.isEmpty && !orderController.isLoading.value) {
      orderController.fetchOrders();
    }

    return Obx(() {
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
      final orders = orderController.orders;
      final previewRole = rolePreview.previewRole.value;

      return SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : const AssetImage('assets/images/avaatr1.png') as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(color: theme.cardColor, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'VERIFIED CUSTOMER',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ROLE PREVIEW',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 8,
                          color: theme.hintColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: previewRole,
                          isDense: true,
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                          onChanged: (v) => rolePreview.setRole(v ?? 'User'),
                          items: const ['User', 'Seller', 'Admin']
                              .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (previewRole != 'User') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade800),
                        const SizedBox(width: 6),
                        Text(
                          '$previewRole Privileges',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      previewRole == 'Seller'
                          ? 'Sellers manage their items and advance order fulfillment steps.'
                          : 'Admins manage sellers, products, categories, coupons, and audit logs.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACTIVE ORDERS TRACKING',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${orders.length} Order${orders.length == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (orders.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No orders yet',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...orders.map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderTrackerCard(order: order),
                  )),

            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                children: [
                  _AccountOption(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    onTap: () => Get.toNamed(AppRoutes.editProfile),
                  ),
                  const Divider(height: 1),
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
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => Get.toNamed(AppRoutes.settings),
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
    });
  }
}

/// Matches the mockup's order card: id/date, total/status badge, item
/// thumbnails, and a linear progress bar across the 7-state fulfillment
/// path — with a real "Advance" action wired to OrderController, not a
/// local-only mock. Unlike the mockup, this can genuinely fail (e.g. a
/// plain customer account isn't authorized to advance fulfillment — only
/// a seller/admin is, per firestore.rules): that's shown as a real error,
/// not silently allowed. The mockup's per-order transition history isn't
/// reproduced here since the real Order model doesn't store one.
class _OrderTrackerCard extends StatelessWidget {
  const _OrderTrackerCard({required this.order});

  final Order order;

  String _price(double v) => '\$${v.toStringAsFixed(2)}';
  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final forwardIndex = _kForwardStates.indexOf(order.status);
    final onForwardPath = forwardIndex != -1;
    final canAdvance = onForwardPath && forwardIndex < _kForwardStates.length - 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.id.length > 10 ? order.id.substring(0, 10).toUpperCase() : order.id,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _date(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _price(order.totalAmount),
                    style: TextStyle(fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: order.statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.statusString,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: order.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductImage(path: order.items[index].imagePath, width: 40, height: 40),
              ),
            ),
          ),
          if (onForwardPath) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (forwardIndex + 1) / _kForwardStates.length,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (canAdvance)
                TextButton.icon(
                  onPressed: () async {
                    final next = _kForwardStates[forwardIndex + 1];
                    final error = await OrderController.instance.updateOrderStatus(order.id, next);
                    if (error != null) {
                      AppToast.show(error);
                    } else {
                      AppToast.show('Order status advanced: ${next.name}');
                    }
                  },
                  icon: const Icon(Icons.fast_forward, size: 14),
                  label: const Text('Advance', style: TextStyle(fontSize: 12)),
                )
              else if (order.status == OrderStatus.delivered)
                Text(
                  'Delivered',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
      onTap: onTap,
    );
  }
}
