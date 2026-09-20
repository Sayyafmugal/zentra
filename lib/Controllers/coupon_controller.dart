// coupon_controller.dart
import 'package:get/get.dart';
import '../models/coupon.dart';
import '../repositories/coupon_repository.dart';

export '../models/coupon.dart';

/// Owns coupon lookup for the checkout "have a code?" field and admin CRUD.
///
/// [previewCoupon] is intentionally non-authoritative — it tells the
/// checkout screen what discount a code *would* apply so the customer can
/// see it before placing the order, but the actual redemption (existence,
/// validity, per-user reuse, minimum order) is re-checked from scratch
/// inside OrderRepository.createOrderFromCart's transaction. A client that
/// skipped this preview entirely would still be validated correctly at
/// checkout — this only exists for UX.
class CouponController extends GetxController {
  CouponController({CouponRepository? repository}) : _repository = repository ?? CouponRepository();

  static CouponController get instance => Get.find();

  final CouponRepository _repository;

  final RxList<Coupon> coupons = <Coupon>[].obs;
  final RxBool isLoading = false.obs;

  /// Looks up [code] and returns it only if it currently looks redeemable
  /// against [subtotal] — returns null (with no error surfaced) for any
  /// invalid/missing/expired/exhausted/below-minimum code, since the
  /// checkout UI just needs a yes/no plus the discount amount.
  Future<Coupon?> previewCoupon(String code, double subtotal) async {
    if (code.trim().isEmpty) return null;
    try {
      final coupon = await _repository.getCouponByCode(code);
      if (coupon == null) return null;
      if (!coupon.isCurrentlyValid) return null;
      if (subtotal < coupon.minOrderAmount) return null;
      return coupon;
    } catch (_) {
      return null;
    }
  }

  Future<void> fetchAllCoupons() async {
    try {
      isLoading.value = true;
      coupons.value = await _repository.fetchAllCoupons();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Future<String?> createCoupon(Coupon coupon) async {
    try {
      isLoading.value = true;
      await _repository.createCoupon(coupon);
      coupons.insert(0, coupon);
      isLoading.value = false;

      return null;
    } catch (e) {
      isLoading.value = false;
      return 'Failed to create coupon: $e';
    }
  }

  Future<String?> setActive(String code, bool isActive) async {
    try {
      await _repository.setActive(code, isActive);
      final index = coupons.indexWhere((c) => c.id == Coupon.normalize(code));
      if (index != -1) {
        // Coupon has no copyWith in the model yet — rebuild via fromMap-safe
        // fields directly since all are already known here.
        final current = coupons[index];
        coupons[index] = Coupon(
          id: current.id,
          type: current.type,
          value: current.value,
          minOrderAmount: current.minOrderAmount,
          maxDiscount: current.maxDiscount,
          expiresAt: current.expiresAt,
          usageLimit: current.usageLimit,
          usedCount: current.usedCount,
          isActive: isActive,
          createdAt: current.createdAt,
        );
      }
      return null;
    } catch (e) {
      return 'Failed to update coupon: $e';
    }
  }

  Future<String?> deleteCoupon(String code) async {
    try {
      await _repository.deleteCoupon(code);
      coupons.removeWhere((c) => c.id == Coupon.normalize(code));
      return null;
    } catch (e) {
      return 'Failed to delete coupon: $e';
    }
  }
}
