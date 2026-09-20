import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';

/// Wraps all Firestore access for the `coupons` collection. The actual
/// redeem-at-checkout logic lives in OrderRepository.createOrderFromCart
/// (inside the same transaction that validates stock and prices) rather
/// than here — this repository is for admin CRUD and the lightweight,
/// non-authoritative "does this code look valid" preview check a checkout
/// screen can show before the customer even places the order.
class CouponRepository {
  CouponRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('coupons');

  Future<void> createCoupon(Coupon coupon) async {
    await _collection.doc(coupon.id).set(coupon.toMap());
  }

  Future<Coupon?> getCouponByCode(String code) async {
    final doc = await _collection.doc(Coupon.normalize(code)).get();
    if (doc.exists) return Coupon.fromFirestore(doc);
    return null;
  }

  Future<List<Coupon>> fetchAllCoupons() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList();
  }

  Future<void> setActive(String code, bool isActive) async {
    await _collection.doc(Coupon.normalize(code)).update({'isActive': isActive});
  }

  Future<void> deleteCoupon(String code) async {
    await _collection.doc(Coupon.normalize(code)).delete();
  }
}
