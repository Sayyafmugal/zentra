import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SellerApplicationStatus { pending, approved, rejected }

/// A user's request to become a seller. Submitting one does NOT grant seller
/// privileges — `role` on the user's profile only changes to `seller` when
/// an admin approves this (see `users/{uid}.role` escalation protection in
/// firestore.rules). This model exists so "Become a Seller" has somewhere
/// real to write to instead of a fake instant-approval flow.
class SellerApplication extends Equatable {
  final String id;
  final String userId;
  final String businessName;
  final String businessDescription;
  final String contactEmail;
  final String contactPhone;
  final SellerApplicationStatus status;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const SellerApplication({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.businessDescription,
    required this.contactEmail,
    required this.contactPhone,
    this.status = SellerApplicationStatus.pending,
    required this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  bool get isPending => status == SellerApplicationStatus.pending;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'status': status.name,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  factory SellerApplication.fromMap(Map<String, dynamic> map) {
    return SellerApplication(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      businessDescription: map['businessDescription'] ?? '',
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      status: SellerApplicationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SellerApplicationStatus.pending,
      ),
      submittedAt: (map['submittedAt'] as Timestamp).toDate(),
      reviewedAt: map['reviewedAt'] != null ? (map['reviewedAt'] as Timestamp).toDate() : null,
      reviewedBy: map['reviewedBy'],
      rejectionReason: map['rejectionReason'],
    );
  }

  factory SellerApplication.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SellerApplication.fromMap(data);
  }

  SellerApplication copyWith({
    SellerApplicationStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return SellerApplication(
      id: id,
      userId: userId,
      businessName: businessName,
      businessDescription: businessDescription,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    businessName,
    businessDescription,
    contactEmail,
    contactPhone,
    status,
    submittedAt,
    reviewedAt,
    reviewedBy,
    rejectionReason,
  ];
}
