import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PaymentType { visa, mastercard, amex, discover, paypal, other }

class PaymentMethod extends Equatable {
  final String id;
  final String userId;
  final PaymentType type;
  final String cardNumber; // Last 4 digits only for security
  final String expiryDate; // MM/YY format
  final String? cardholderName;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.cardNumber,
    required this.expiryDate,
    this.cardholderName,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'cardNumber': cardNumber,
      'expiryDate': expiryDate,
      'cardholderName': cardholderName,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory PaymentMethod.fromMap(Map<String, dynamic> map) {
    return PaymentMethod(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: PaymentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PaymentType.other,
      ),
      cardNumber: map['cardNumber'] ?? '',
      expiryDate: map['expiryDate'] ?? '',
      cardholderName: map['cardholderName'],
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory PaymentMethod.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentMethod.fromMap(data);
  }

  PaymentMethod copyWith({
    PaymentType? type,
    String? expiryDate,
    String? cardholderName,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id,
      userId: userId,
      type: type ?? this.type,
      cardNumber: cardNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      cardholderName: cardholderName ?? this.cardholderName,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get maskedCardNumber {
    if (cardNumber.length <= 4) return '**** **** **** $cardNumber';
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  String get displayName {
    switch (type) {
      case PaymentType.visa:
        return 'Visa';
      case PaymentType.mastercard:
        return 'Mastercard';
      case PaymentType.amex:
        return 'American Express';
      case PaymentType.discover:
        return 'Discover';
      case PaymentType.paypal:
        return 'PayPal';
      case PaymentType.other:
        return 'Other';
    }
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    cardNumber,
    expiryDate,
    cardholderName,
    isDefault,
    createdAt,
    updatedAt,
  ];
}
