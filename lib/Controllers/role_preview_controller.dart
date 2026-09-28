import 'package:get/get.dart';

/// The mockup's "Role Preview" selector on Account — a purely cosmetic,
/// local-only badge/banner toggle (User/Seller/Admin), exactly like the
/// static HTML mockup it's matching. This intentionally does NOT grant any
/// real permission: actual admin/seller access is still gated by the real
/// Firestore-backed role on UserProfile and enforced by firestore.rules +
/// AdminMiddleware/SellerOrAdminMiddleware. Flipping this only changes what
/// the header badge and Account banner display, same as the mockup itself
/// (which has no real backend and no admin/seller screens to gate at all).
class RolePreviewController extends GetxController {
  static RolePreviewController get instance => Get.find();

  final RxString previewRole = 'User'.obs;

  void setRole(String role) => previewRole.value = role;
}
