import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../Controllers/user_profile_controller.dart';
import 'app_routes.dart';

/// Redirects away from admin-only routes for non-admin users. This mirrors
/// the same `role == 'admin'` check enforced server-side in firestore.rules
/// — the UI gate alone is not the security boundary, just the UX for it.
class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final isAdmin = Get.find<UserProfileController>().isAdmin;
    if (!isAdmin) {
      return const RouteSettings(name: AppRoutes.main);
    }
    return null;
  }
}

/// Redirects away from product-management routes for accounts that are
/// neither a seller nor an admin. Firestore rules are the real enforcement
/// (a seller can only write their own products, checked server-side) — this
/// just keeps a plain customer from opening a form they have no permission
/// to submit.
class SellerOrAdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final canManage = Get.find<UserProfileController>().canManageProducts;
    if (!canManage) {
      return const RouteSettings(name: AppRoutes.main);
    }
    return null;
  }
}
