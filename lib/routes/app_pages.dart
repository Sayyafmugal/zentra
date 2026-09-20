import 'package:get/get.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../view/splash_screen.dart';
import '../view/onboarding_screen.dart';
import '../view/signin_screen.dart';
import '../view/sign_up_screen.dart';
import '../view/forgot_password_screen.dart';
import '../view/main_screen.dart';
import '../view/product_details_screen.dart';
import '../view/my_cart_screen.dart';
import '../view/checkout_screen.dart';
import '../view/order_confirmation_screen.dart';
import '../view/my_orders_screen.dart';
import '../view/order_details_screen.dart';
import '../view/edit_profile_screen.dart';
import '../view/settings_screen.dart';
import '../view/privacy_policy_screen.dart';
import '../view/terms_of_service_screen.dart';
import '../view/shipping_address_screen.dart';
import '../view/payment_method_screen.dart';
import '../view/notifications_screen.dart';
import '../view/help_center_screen.dart';
import '../view/add_product_screen.dart';
import '../view/admin_dashboard_screen.dart';
import '../view/audit_log_screen.dart';
import '../view/become_seller_screen.dart';
import '../view/edit_product_screen.dart';
import '../view/seller_dashboard_screen.dart';
import '../view/not_found_screen.dart';
import 'app_routes.dart';
import 'admin_middleware.dart';

/// Central [GetPage] table. Every screen the app can navigate to is
/// registered here so Get.toNamed()/offNamed()/offAllNamed() is the only
/// way screens get pushed — no bare Navigator.push or unregistered
/// Get.to() widget pushes, which is what previously left Flutter Web with
/// no route to resolve on refresh/deep-link.
abstract class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.signin, page: () => const SigninScreen()),
    GetPage(name: AppRoutes.signup, page: () => const SignupScreen()),
    GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordScreen()),
    GetPage(name: AppRoutes.main, page: () => const MainScreen()),
    GetPage(
      name: AppRoutes.productDetails,
      page: () => ProductDetailsScreen(product: Get.arguments as Product),
    ),
    GetPage(name: AppRoutes.cart, page: () => const MyCartScreen()),
    GetPage(
      name: AppRoutes.checkout,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return CheckoutScreen(
          totalAmount: args['totalAmount'] as double,
          itemCount: args['itemCount'] as int,
        );
      },
    ),
    GetPage(
      name: AppRoutes.orderConfirmation,
      page: () => OrderConfirmationScreen(totalAmount: Get.arguments as double),
    ),
    GetPage(name: AppRoutes.myOrders, page: () => const MyOrdersScreen()),
    GetPage(
      name: AppRoutes.orderDetails,
      page: () => OrderDetailsScreen(order: Get.arguments as Order),
    ),
    GetPage(name: AppRoutes.editProfile, page: () => const EditProfileScreen()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
    GetPage(name: AppRoutes.privacyPolicy, page: () => const PrivacyPolicyScreen()),
    GetPage(name: AppRoutes.termsOfService, page: () => const TermsOfServiceScreen()),
    GetPage(name: AppRoutes.shippingAddress, page: () => const ShippingAddressScreen()),
    GetPage(name: AppRoutes.paymentMethod, page: () => const PaymentMethodScreen()),
    GetPage(name: AppRoutes.notifications, page: () => const NotificationsScreen()),
    GetPage(name: AppRoutes.helpCenter, page: () => const HelpCenterScreen()),
    GetPage(
      name: AppRoutes.addProduct,
      page: () => const AddProductScreen(),
      middlewares: [SellerOrAdminMiddleware()],
    ),
    GetPage(
      name: AppRoutes.editProduct,
      page: () => EditProductScreen(product: Get.arguments as Product),
      middlewares: [SellerOrAdminMiddleware()],
    ),
    GetPage(
      name: AppRoutes.adminDashboard,
      page: () => const AdminDashboardScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(
      name: AppRoutes.auditLog,
      page: () => const AuditLogScreen(),
      middlewares: [AdminMiddleware()],
    ),
    GetPage(name: AppRoutes.becomeSeller, page: () => const BecomeSellerScreen()),
    GetPage(
      name: AppRoutes.sellerDashboard,
      page: () => const SellerDashboardScreen(),
      middlewares: [SellerOrAdminMiddleware()],
    ),
    GetPage(name: AppRoutes.notFound, page: () => const NotFoundScreen()),
  ];
}
