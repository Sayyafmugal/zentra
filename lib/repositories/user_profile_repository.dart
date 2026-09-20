import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

/// Wraps all Firestore access for the `users` collection.
class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore.collection('users');

  Future<void> createProfile(UserProfile profile) async {
    await _collection.doc(profile.uid).set(profile.toMap());
  }

  Future<UserProfile?> fetchProfile(String uid) async {
    final doc = await _collection.doc(uid).get();
    if (doc.exists) return UserProfile.fromFirestore(doc);
    return null;
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _collection
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    await _collection.doc(uid).update({...updates, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteProfile(String uid) async {
    await _collection.doc(uid).delete();
  }
}
