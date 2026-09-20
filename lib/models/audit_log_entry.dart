import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// A record of a sensitive admin action taken through this app — role
/// changes, seller approval/suspension, and similar accountability-relevant
/// events (see the call sites in SellerController/UserProfileController).
///
/// IMPORTANT LIMITATION: this is best-effort application-level logging, not
/// a tamper-proof audit trail. Without a server (Cloud Functions, which —
/// like Storage — would require Blaze billing this project deliberately
/// doesn't assume), there is no way to *guarantee* every matching action was
/// logged, or that a log entry wasn't fabricated independently of a real
/// action: the write happens as a second, separate call from the same
/// client that performed the real mutation, not as an atomic server-side
/// side effect of it. Good enough to show what admins did through this UI;
/// not a substitute for a real audit system if that's ever a hard
/// requirement.
class AuditLogEntry extends Equatable {
  final String id;
  final String actorId;
  final String actorEmail;
  final String action; // short machine tag, e.g. 'seller.approved'
  final String summary; // human-readable one-liner for the log viewer
  final String? targetId;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorEmail,
    required this.action,
    required this.summary,
    this.targetId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actorId': actorId,
      'actorEmail': actorEmail,
      'action': action,
      'summary': summary,
      'targetId': targetId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] ?? '',
      actorId: map['actorId'] ?? '',
      actorEmail: map['actorEmail'] ?? '',
      action: map['action'] ?? '',
      summary: map['summary'] ?? '',
      targetId: map['targetId'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory AuditLogEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AuditLogEntry.fromMap(data);
  }

  @override
  List<Object?> get props => [id, actorId, actorEmail, action, summary, targetId, createdAt];
}
