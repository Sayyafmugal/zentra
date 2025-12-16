import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String imagePath;
  final String name;
  final String category;
  final double currentPrice;
  final double? oldPrice;
  final String? discount;
  final List<String> availableSizes;
  final String description;
  final bool isFavorite;

  const Product({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.category,
    required this.currentPrice,
    this.oldPrice,
    this.discount,
    required this.availableSizes,
    required this.description,
    this.isFavorite = false,
  });

  // Convert Product to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imagePath': imagePath,
      'name': name,
      'category': category,
      'currentPrice': currentPrice,
      'oldPrice': oldPrice,
      'discount': discount,
      'availableSizes': availableSizes,
      'description': description,
      'isFavorite': isFavorite,
    };
  }

  // Create Product from Firestore document
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      imagePath: map['imagePath'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      currentPrice: (map['currentPrice'] ?? 0.0).toDouble(),
      oldPrice: map['oldPrice'] != null ? (map['oldPrice'] as num).toDouble() : null,
      discount: map['discount'],
      availableSizes: List<String>.from(map['availableSizes'] ?? []),
      description: map['description'] ?? '',
      isFavorite: map['isFavorite'] ?? false,
    );
  }

  // Create Product from Firestore document snapshot
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product.fromMap(data);
  }

  // Create a copy with updated fields
  Product copyWith({
    String? id,
    String? imagePath,
    String? name,
    String? category,
    double? currentPrice,
    double? oldPrice,
    String? discount,
    List<String>? availableSizes,
    String? description,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      name: name ?? this.name,
      category: category ?? this.category,
      currentPrice: currentPrice ?? this.currentPrice,
      oldPrice: oldPrice ?? this.oldPrice,
      discount: discount ?? this.discount,
      availableSizes: availableSizes ?? this.availableSizes,
      description: description ?? this.description,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
