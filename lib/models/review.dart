import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum ReviewStatus { published, hidden }

/// A customer's review of a product from one specific delivered order.
///
/// [id] is always `'${orderId}_${productId}'` — a deterministic composite
/// key rather than an auto-generated one. That's what makes "at most one
/// review per purchased item" enforceable with a plain document existence
/// check (both client-side and in firestore.rules) instead of a query,
/// which also means it works safely inside a Firestore transaction.
class Review extends Equatable {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String orderId;
  final double rating;
  final String comment;
  final ReviewStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.orderId,
    required this.rating,
    required this.comment,
    this.status = ReviewStatus.published,
    required this.createdAt,
    this.updatedAt,
  });

  static String idFor({required String orderId, required String productId}) =>
      '${orderId}_$productId';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'orderId': orderId,
      'rating': rating,
      'comment': comment,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      orderId: map['orderId'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      comment: map['comment'] ?? '',
      status: ReviewStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ReviewStatus.published,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review.fromMap(data);
  }

  Review copyWith({String? comment, double? rating, ReviewStatus? status, DateTime? updatedAt}) {
    return Review(
      id: id,
      productId: productId,
      userId: userId,
      userName: userName,
      orderId: orderId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    productId,
    userId,
    userName,
    orderId,
    rating,
    comment,
    status,
    createdAt,
    updatedAt,
  ];
}
