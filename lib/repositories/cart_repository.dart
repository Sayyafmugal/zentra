import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';

/// Wraps all Firestore access for the `cart` collection.
class CartRepository {
  CartRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('cart');

  String newCartItemId() => _collection.doc().id;

  Future<void> addCartItem(CartItem item) async {
    await _collection.doc(item.id).set({
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<CartItem>> fetchCartItems(String userId) async {
    final snapshot = await _collection.where('userId', isEqualTo: userId).get();
    return snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList();
  }

  Stream<List<CartItem>> watchCartItems(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => CartItem.fromFirestore(doc)).toList());
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    await _collection.doc(cartItemId).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSize(String cartItemId, String size) async {
    await _collection.doc(cartItemId).update({
      'selectedSize': size,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeCartItem(String cartItemId) async {
    await _collection.doc(cartItemId).delete();
  }

  Future<void> clearCart(List<String> cartItemIds) async {
    final batch = _firestore.batch();
    for (final id in cartItemIds) {
      batch.delete(_collection.doc(id));
    }
    await batch.commit();
  }
}
