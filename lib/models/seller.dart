import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum SellerStatus { active, suspended }

/// A live, approved seller account. Created only when a [SellerApplication]
/// is approved (see that model) — never created directly by a client, so
/// `sellers/{uid}` existing at all is itself proof of admin approval.
class Seller extends Equatable {
  final String id; // == the seller's Firebase Auth uid
  final String userId;
  final String businessName;
  final String? businessDescription;
  final String contactEmail;
  final String contactPhone;
  final SellerStatus status;
  final DateTime createdAt;
  final String approvedBy;
  final DateTime? suspendedAt;
  final String? suspensionReason;

  const Seller({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessDescription,
    required this.contactEmail,
    required this.contactPhone,
    this.status = SellerStatus.active,
    required this.createdAt,
    required this.approvedBy,
    this.suspendedAt,
    this.suspensionReason,
  });

  bool get isActive => status == SellerStatus.active;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedBy': approvedBy,
      'suspendedAt': suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'suspensionReason': suspensionReason,
    };
  }

  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      businessName: map['businessName'] ?? '',
      businessDescription: map['businessDescription'],
      contactEmail: map['contactEmail'] ?? '',
      contactPhone: map['contactPhone'] ?? '',
      status: SellerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SellerStatus.active,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      approvedBy: map['approvedBy'] ?? '',
      suspendedAt: map['suspendedAt'] != null ? (map['suspendedAt'] as Timestamp).toDate() : null,
      suspensionReason: map['suspensionReason'],
    );
  }

  factory Seller.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Seller.fromMap(data);
  }

  Seller copyWith({SellerStatus? status, DateTime? suspendedAt, String? suspensionReason}) {
    return Seller(
      id: id,
      userId: userId,
      businessName: businessName,
      businessDescription: businessDescription,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      status: status ?? this.status,
      createdAt: createdAt,
      approvedBy: approvedBy,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspensionReason: suspensionReason ?? this.suspensionReason,
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
    createdAt,
    approvedBy,
    suspendedAt,
    suspensionReason,
  ];
}
