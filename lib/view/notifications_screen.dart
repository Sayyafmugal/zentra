import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Controllers/order_controller.dart';
import '../widgets/state_views.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  ({IconData icon, Color Function(BuildContext) color, String title, String body}) _describe(
    Order order,
  ) {
    final shortId = order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length);
    switch (order.status) {
      case OrderStatus.pendingPayment:
        return (
          icon: Icons.shopping_bag_outlined,
          color: (ctx) => Theme.of(ctx).colorScheme.primary,
          title: 'Order Placed!',
          body: 'Your order #$shortId has been placed and is awaiting payment confirmation.',
        );
      case OrderStatus.paid:
        return (
          icon: Icons.check_circle_outline,
          color: (_) => const Color(0xFF00897B),
          title: 'Payment Received',
          body: 'Payment for order #$shortId was received.',
        );
      case OrderStatus.processing:
        return (
          icon: Icons.autorenew,
          color: (_) => const Color(0xFF1976D2),
          title: 'Order Processing',
          body: 'Order #$shortId is being prepared for shipment.',
        );
      case OrderStatus.packed:
        return (
          icon: Icons.inventory_2_outlined,
          color: (_) => const Color(0xFF3F51B5),
          title: 'Order Packed',
          body: 'Order #$shortId has been packed and is ready to ship.',
        );
      case OrderStatus.shipped:
        return (
          icon: Icons.local_shipping_outlined,
          color: (_) => const Color(0xFF9C27B0),
          title: 'Order Shipped',
          body: 'Order #$shortId has shipped.',
        );
      case OrderStatus.outForDelivery:
        return (
          icon: Icons.delivery_dining_outlined,
          color: (_) => const Color(0xFF673AB7),
          title: 'Out for Delivery',
          body: 'Order #$shortId is on its way to you.',
        );
      case OrderStatus.delivered:
        return (
          icon: Icons.check_circle_outline,
          color: (_) => const Color(0xFF4CAF50),
          title: 'Delivered',
          body: 'Order #$shortId has been delivered. Enjoy!',
        );
      case OrderStatus.cancelled:
        return (
          icon: Icons.cancel_outlined,
          color: (_) => const Color(0xFFD32F2F),
          title: 'Order Cancelled',
          body: 'Order #$shortId was cancelled.',
        );
      case OrderStatus.returnRequested:
        return (
          icon: Icons.assignment_return_outlined,
          color: (_) => const Color(0xFFF9A825),
          title: 'Return Requested',
          body: 'A return has been requested for order #$shortId.',
        );
      case OrderStatus.returned:
        return (
          icon: Icons.keyboard_return_outlined,
          color: (_) => const Color(0xFF795548),
          title: 'Order Returned',
          body: 'Order #$shortId has been returned.',
        );
      case OrderStatus.refunded:
        return (
          icon: Icons.currency_exchange_outlined,
          color: (_) => const Color(0xFF757575),
          title: 'Refund Processed',
          body: 'Your refund for order #$shortId has been processed.',
        );
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM dd, yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final orderController = OrderController.instance;

    if (orderController.orders.isEmpty && !orderController.isLoading.value) {
      orderController.fetchOrders();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications'), centerTitle: false),
      body: Obx(() {
        final orders = orderController.orders;
        if (orderController.isLoading.value && orders.isEmpty) {
          return const LoadingView(asGrid: false);
        }
        if (orders.isEmpty) {
          return const EmptyStateView(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            message: 'Updates about your orders will appear here.',
          );
        }

        return RefreshIndicator(
          onRefresh: orderController.fetchOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final info = _describe(order);
              final color = info.color(context);
              final theme = Theme.of(context);
              final isLatest = index == 0;

              return Container(
                decoration: BoxDecoration(
                  color: isLatest
                      ? theme.colorScheme.primary.withValues(alpha: 0.08)
                      : theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(info.icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              info.title,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              info.body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.hintColor,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _relativeTime(order.updatedAt ?? order.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                      ),
                      if (isLatest)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
