/// Central registry of every named route in the app. Never push a screen
/// with a raw widget instance (Navigator.push / bare Get.to) — always go
/// through one of these names so the app has one real route table instead
/// of ad-hoc widget pushes (this is what previously caused Flutter Web's
/// "Could not navigate to initial route" crash on refresh/deep-link).
abstract class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const signin = '/signin';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';

  static const main = '/main';

  static const productDetails = '/product-details';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orderConfirmation = '/order-confirmation';
  static const myOrders = '/my-orders';
  static const orderDetails = '/order-details';

  static const editProfile = '/edit-profile';
  static const settings = '/settings';
  static const privacyPolicy = '/privacy-policy';
  static const termsOfService = '/terms-of-service';
  static const shippingAddress = '/shipping-address';
  static const paymentMethod = '/payment-method';
  static const notifications = '/notifications';
  static const helpCenter = '/help-center';

  static const addProduct = '/add-product';
  static const editProduct = '/edit-product';
  static const adminDashboard = '/admin-dashboard';
  static const auditLog = '/audit-log';
  static const becomeSeller = '/become-seller';
  static const sellerDashboard = '/seller-dashboard';

  static const notFound = '/not-found';
}
