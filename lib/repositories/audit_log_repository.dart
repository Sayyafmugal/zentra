import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/audit_log_entry.dart';

/// One page of a cursor-paginated audit log fetch — same shape/reasoning as
/// ProductRepository.ProductPage: an append-only, ever-growing collection
/// must never be loaded all at once.
class AuditLogPage {
  const AuditLogPage({required this.entries, required this.lastDocument, required this.hasMore});

  final List<AuditLogEntry> entries;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;
}

/// Wraps all Firestore access for the `auditLogs` collection.
class AuditLogRepository {
  AuditLogRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('auditLogs');

  String newLogId() => _collection.doc().id;

  Future<void> logAction(AuditLogEntry entry) async {
    await _collection.doc(entry.id).set(entry.toMap());
  }

  Future<AuditLogPage> fetchLogsPage({
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    // startAfterDocument must be chained before limit — see the identical
    // note on ProductRepository.fetchProductsPage, which is where this bug
    // was first caught by a test.
    Query<Map<String, dynamic>> query = _collection.orderBy('createdAt', descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    query = query.limit(limit);
    final snapshot = await query.get();
    return AuditLogPage(
      entries: snapshot.docs.map((doc) => AuditLogEntry.fromFirestore(doc)).toList(),
      lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
      hasMore: snapshot.docs.length == limit,
    );
  }
}
