import 'package:get/get.dart';
import '../Controllers/auth_controller.dart';
import '../Controllers/theme_controller.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/cart_controller.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/user_profile_controller.dart';
import '../Controllers/address_controller.dart';
import '../Controllers/payment_method_controller.dart';
import '../Controllers/seller_controller.dart';
import '../Controllers/review_controller.dart';
import '../Controllers/coupon_controller.dart';
import '../Controllers/category_controller.dart';
import '../Controllers/audit_log_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../Controllers/role_preview_controller.dart';

/// Puts every controller the app needs up front. The screens here are
/// tightly interdependent (e.g. every tab of MainScreen needs cart,
/// wishlist, and profile state simultaneously), so per-route lazy binding
/// would just move "controller not found" failures around rather than
/// remove them — a single explicit initial binding is the more honest fit
/// for this app's shape.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController());
    Get.put(AuthController());
    Get.put(ProductController());
    Get.put(CartController());
    Get.put(OrderController());
    Get.put(WishlistController());
    Get.put(UserProfileController());
    Get.put(AddressController());
    Get.put(PaymentMethodController());
    Get.put(SellerController());
    Get.put(ReviewController());
    Get.put(CouponController());
    Get.put(CategoryController());
    Get.put(AuditLogController());
    Get.put(MainTabController());
    Get.put(RolePreviewController());
  }
}
