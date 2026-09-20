import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum CouponType { percentage, fixed }

/// A discount code. [id] is always the normalized (uppercased) code itself
/// — there's no separate auto-generated id — which is what makes "does this
/// code exist" a plain document lookup rather than a query, and (like
/// [Review.idFor]) lets Firestore transactions check it directly.
class Coupon extends Equatable {
  final String id; // normalized code, e.g. 'SAVE20'
  final CouponType type;
  final double value; // percentage points (0-100) or a fixed currency amount
  final double minOrderAmount;
  final double? maxDiscount; // caps a percentage coupon's payout; ignored for fixed
  final DateTime? expiresAt;
  final int? usageLimit; // null = unlimited total redemptions
  final int usedCount;
  final bool isActive;
  final DateTime createdAt;

  const Coupon({
    required this.id,
    required this.type,
    required this.value,
    this.minOrderAmount = 0,
    this.maxDiscount,
    this.expiresAt,
    this.usageLimit,
    this.usedCount = 0,
    this.isActive = true,
    required this.createdAt,
  });

  static String normalize(String code) => code.trim().toUpperCase();

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  bool get isExhausted => usageLimit != null && usedCount >= usageLimit!;

  /// Whether this coupon could apply to *some* order right now, ignoring
  /// any specific order's subtotal or a specific user's redemption history
  /// (those are checked separately — see CouponRepository.redeemForOrder).
  bool get isCurrentlyValid => isActive && !isExpired && !isExhausted;

  double discountFor(double subtotal) {
    if (subtotal < minOrderAmount) return 0;
    final raw = type == CouponType.percentage ? subtotal * (value / 100) : value;
    final capped = maxDiscount != null ? raw.clamp(0, maxDiscount!) : raw;
    return capped.clamp(0, subtotal).toDouble();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'minOrderAmount': minOrderAmount,
      'maxDiscount': maxDiscount,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'usageLimit': usageLimit,
      'usedCount': usedCount,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Coupon.fromMap(Map<String, dynamic> map) {
    return Coupon(
      id: map['id'] ?? '',
      type: CouponType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CouponType.fixed,
      ),
      value: (map['value'] ?? 0.0).toDouble(),
      minOrderAmount: (map['minOrderAmount'] ?? 0.0).toDouble(),
      maxDiscount: map['maxDiscount'] != null ? (map['maxDiscount'] as num).toDouble() : null,
      expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
      usageLimit: map['usageLimit'] as int?,
      usedCount: map['usedCount'] ?? 0,
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Coupon.fromMap(data);
  }

  @override
  List<Object?> get props => [
    id,
    type,
    value,
    minOrderAmount,
    maxDiscount,
    expiresAt,
    usageLimit,
    usedCount,
    isActive,
    createdAt,
  ];
}
