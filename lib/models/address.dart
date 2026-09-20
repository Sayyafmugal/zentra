import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String userId;
  final String name; // e.g., "Home", "Office"
  final String fullName;
  final String address;
  final String city;
  final String? state;
  final String? zipCode;
  final String country;
  final String phone;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.fullName,
    required this.address,
    required this.city,
    this.state,
    this.zipCode,
    required this.country,
    required this.phone,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'fullName': fullName,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
      'phone': phone,
      'isDefault': isDefault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      fullName: map['fullName'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      state: map['state'],
      zipCode: map['zipCode'],
      country: map['country'] ?? 'USA',
      phone: map['phone'] ?? '',
      isDefault: map['isDefault'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory Address.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Address.fromMap(data);
  }

  Address copyWith({
    String? name,
    String? fullName,
    String? address,
    String? city,
    String? state,
    String? zipCode,
    String? country,
    String? phone,
    bool? isDefault,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id,
      userId: userId,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zipCode: zipCode ?? this.zipCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get fullAddress {
    final parts = [address, city];
    if (state != null) parts.add(state!);
    if (zipCode != null) parts.add(zipCode!);
    parts.add(country);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    name,
    fullName,
    address,
    city,
    state,
    zipCode,
    country,
    phone,
    isDefault,
    createdAt,
    updatedAt,
  ];
}
