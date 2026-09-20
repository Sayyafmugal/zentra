// audit_log_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/audit_log_entry.dart';
import '../repositories/audit_log_repository.dart';

export '../models/audit_log_entry.dart';

/// Purely a viewer for the admin's "Audit Log" screen — paginated the same
/// way the product/order lists are, since this collection is append-only
/// and only ever grows. The controllers that actually *write* log entries
/// (SellerController, UserProfileController) depend on [AuditLogRepository]
/// directly rather than on this controller, so their tests don't need a
/// GetX-registered singleton to mock around.
class AuditLogController extends GetxController {
  AuditLogController({AuditLogRepository? repository})
    : _repository = repository ?? AuditLogRepository();

  static AuditLogController get instance => Get.find();

  final AuditLogRepository _repository;
  static const int _pageSize = 20;

  final RxList<AuditLogEntry> logs = <AuditLogEntry>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasMore = true.obs;
  final RxBool isLoadingMore = false.obs;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  Future<void> fetchFirstPage() async {
    try {
      isLoading.value = true;
      final page = await _repository.fetchLogsPage(limit: _pageSize);
      logs.value = page.entries;
      _cursor = page.lastDocument;
      hasMore.value = page.hasMore;
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (!hasMore.value || isLoadingMore.value) return;
    try {
      isLoadingMore.value = true;
      final page = await _repository.fetchLogsPage(limit: _pageSize, startAfter: _cursor);
      logs.addAll(page.entries);
      _cursor = page.lastDocument;
      hasMore.value = page.hasMore;
      isLoadingMore.value = false;
    } catch (e) {
      isLoadingMore.value = false;
    }
  }
}
