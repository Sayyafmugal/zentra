import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/seller_application.dart';

/// Wraps all Firestore access for the `sellerApplications` collection.
class SellerApplicationRepository {
  SellerApplicationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('sellerApplications');

  String newApplicationId() => _collection.doc().id;

  Future<void> submitApplication(SellerApplication application) async {
    await _collection.doc(application.id).set(application.toMap());
  }

  Future<SellerApplication?> getApplicationById(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) return SellerApplication.fromFirestore(doc);
    return null;
  }

  /// A user should only ever have at most one pending application at a
  /// time — used to block duplicate submissions rather than trusting the
  /// client not to spam "Become a Seller".
  Future<SellerApplication?> getPendingApplicationForUser(String userId) async {
    final snapshot = await _collection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: SellerApplicationStatus.pending.name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return SellerApplication.fromFirestore(snapshot.docs.first);
  }

  Future<List<SellerApplication>> fetchPendingApplications() async {
    final snapshot = await _collection
        .where('status', isEqualTo: SellerApplicationStatus.pending.name)
        .orderBy('submittedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => SellerApplication.fromFirestore(doc)).toList();
  }

  Future<void> reviewApplication({
    required String applicationId,
    required SellerApplicationStatus status,
    required String reviewedBy,
    String? rejectionReason,
  }) async {
    await _collection.doc(applicationId).update({
      'status': status.name,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    });
  }
}
