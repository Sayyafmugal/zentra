import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller.dart';

/// Wraps all Firestore access for the `sellers` collection. A document here
/// only ever gets created by [createFromApproval] (called after an admin
/// approves a [SellerApplication]) — there is no client-facing "create my
/// own seller doc" path, matching the rule that a user cannot self-grant
/// seller privileges.
class SellerRepository {
  SellerRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('sellers');

  Future<void> createFromApproval(Seller seller) async {
    await _collection.doc(seller.id).set(seller.toMap());
  }

  Future<Seller?> getSellerById(String sellerId) async {
    final doc = await _collection.doc(sellerId).get();
    if (doc.exists) return Seller.fromFirestore(doc);
    return null;
  }

  Stream<Seller?> watchSeller(String sellerId) {
    return _collection
        .doc(sellerId)
        .snapshots()
        .map((doc) => doc.exists ? Seller.fromFirestore(doc) : null);
  }

  Future<List<Seller>> fetchAllSellers() async {
    final snapshot = await _collection.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Seller.fromFirestore(doc)).toList();
  }

  Future<void> updateStatus(String sellerId, SellerStatus status, {String? reason}) async {
    await _collection.doc(sellerId).update({
      'status': status.name,
      'suspendedAt': status == SellerStatus.suspended ? FieldValue.serverTimestamp() : null,
      'suspensionReason': reason,
    });
  }
}
