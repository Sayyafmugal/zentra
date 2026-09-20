import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_method.dart';

/// Wraps all Firestore access for the `paymentMethods` collection.
class PaymentMethodRepository {
  PaymentMethodRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('paymentMethods');

  String newPaymentMethodId() => _collection.doc().id;

  Future<void> addPaymentMethod(PaymentMethod method) async {
    await _collection.doc(method.id).set(method.toMap());
  }

  Future<List<PaymentMethod>> fetchPaymentMethods(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList();
  }

  Stream<List<PaymentMethod>> watchPaymentMethods(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PaymentMethod.fromFirestore(doc)).toList());
  }

  Future<void> updatePaymentMethod(String paymentId, Map<String, dynamic> updates) async {
    await _collection.doc(paymentId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsetDefaults(List<String> paymentIds) async {
    if (paymentIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in paymentIds) {
      batch.update(_collection.doc(id), {'isDefault': false});
    }
    await batch.commit();
  }

  Future<void> deletePaymentMethod(String paymentId) async {
    await _collection.doc(paymentId).delete();
  }
}
