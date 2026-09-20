import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final String id;
  final Product product;
  final int quantity;
  final String selectedSize;
  final String userId;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.selectedSize,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': product.id,
      'product': product.toMap(),
      'quantity': quantity,
      'selectedSize': selectedSize,
      'userId': userId,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map, Product product) {
    return CartItem(
      id: map['id'] ?? '',
      product: product,
      quantity: map['quantity'] ?? 1,
      selectedSize: map['selectedSize'] ?? '',
      userId: map['userId'] ?? '',
    );
  }

  factory CartItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final product = Product.fromMap(data['product'] as Map<String, dynamic>);
    return CartItem.fromMap(data, product);
  }

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    String? selectedSize,
    String? userId,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      selectedSize: selectedSize ?? this.selectedSize,
      userId: userId ?? this.userId,
    );
  }

  double get totalPrice => product.currentPrice * quantity;

  @override
  List<Object?> get props => [id, product, quantity, selectedSize, userId];
}
