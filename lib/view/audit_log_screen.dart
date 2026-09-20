import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Controllers/audit_log_controller.dart';
import '../widgets/state_views.dart';

/// Read-only viewer for the `auditLogs` collection — admin-only, per
/// firestore.rules. See AuditLogEntry's doc comment for what this is (and
/// isn't) a guarantee of.
class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy · h:mm a').format(date);

  @override
  Widget build(BuildContext context) {
    final controller = AuditLogController.instance;

    if (controller.logs.isEmpty && !controller.isLoading.value) {
      controller.fetchFirstPage();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: const Text('Audit Log'),
        centerTitle: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.logs.isEmpty) {
          return const LoadingView(asGrid: false);
        }

        if (controller.logs.isEmpty) {
          return const EmptyStateView(
            icon: Icons.history,
            title: 'No activity yet',
            message: 'Sensitive admin actions will show up here as they happen.',
          );
        }

        return RefreshIndicator(
          onRefresh: controller.fetchFirstPage,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.logs.length + (controller.hasMore.value ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index >= controller.logs.length) {
                return Center(
                  child: controller.isLoadingMore.value
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        )
                      : OutlinedButton(onPressed: controller.loadMore, child: const Text('Load More')),
                );
              }
              return _AuditLogCard(entry: controller.logs[index], formatDate: _formatDate);
            },
          ),
        );
      }),
    );
  }
}

class _AuditLogCard extends StatelessWidget {
  const _AuditLogCard({required this.entry, required this.formatDate});

  final AuditLogEntry entry;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.summary,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.action,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.actorEmail} · ${formatDate(entry.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }
}
