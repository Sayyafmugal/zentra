import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A real, admin-managed catalog category — replaces what used to be a
/// hardcoded constant list in add_product_screen.dart. [id] is a slug
/// derived from [name] (see [Category.slugify]) so it doubles as a stable
/// document id with no separate id-generation step.
class Category extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const Category({required this.id, required this.name, required this.createdAt});

  static String slugify(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'createdAt': Timestamp.fromDate(createdAt)};
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category.fromMap(data);
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
