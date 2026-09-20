import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';

/// Wraps all Firestore access for the `addresses` collection.
class AddressRepository {
  AddressRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('addresses');

  String newAddressId() => _collection.doc().id;

  Future<void> addAddress(Address address) async {
    await _collection.doc(address.id).set(address.toMap());
  }

  Future<List<Address>> fetchAddresses(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList();
  }

  Stream<List<Address>> watchAddresses(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Address.fromFirestore(doc)).toList());
  }

  Future<void> updateAddress(String addressId, Map<String, dynamic> updates) async {
    await _collection.doc(addressId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unsetDefaults(List<String> addressIds) async {
    if (addressIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in addressIds) {
      batch.update(_collection.doc(id), {'isDefault': false});
    }
    await batch.commit();
  }

  Future<void> deleteAddress(String addressId) async {
    await _collection.doc(addressId).delete();
  }
}
