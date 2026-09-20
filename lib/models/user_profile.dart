import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { user, seller, admin }

class UserProfile extends Equatable {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.role = UserRole.user,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isSeller => role == UserRole.seller;
  // Admins can do everything a seller can (manage the catalog), so screens
  // gating on "can manage products" should check this rather than isSeller
  // alone.
  bool get canManageProducts => isSeller || isAdmin;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,
      'role': role.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      photoUrl: map['photoUrl'],
      role: UserRole.values.firstWhere((e) => e.name == map['role'], orElse: () => UserRole.user),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromMap(data);
  }

  UserProfile copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? photoUrl,
    UserRole? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [uid, fullName, email, phone, photoUrl, role, createdAt, updatedAt];
}
