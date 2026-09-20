import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Controllers/order_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/state_views.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final orderController = OrderController.instance;

    if (orderController.orders.isEmpty && !orderController.isLoading.value) {
      orderController.fetchOrders();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: const Text('My Orders'),
        centerTitle: false,
      ),
      body: Obx(() {
        if (orderController.isLoading.value && orderController.orders.isEmpty) {
          return const LoadingView(asGrid: false);
        }

        if (orderController.orders.isEmpty) {
          return const EmptyStateView(
            icon: Icons.shopping_bag_outlined,
            title: 'No orders yet',
            message: 'Your placed orders will show up here.',
          );
        }

        return RefreshIndicator(
          onRefresh: orderController.fetchOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orderController.orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orderController.orders[index];
              return _OrderCard(order: order, formatDate: _formatDate, formatPrice: _formatPrice);
            },
          ),
        );
      }),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.formatDate, required this.formatPrice});

  final Order order;
  final String Function(DateTime) formatDate;
  final String Function(double) formatPrice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length)}',
                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.statusString,
                  style: TextStyle(
                    color: order.statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatDate(order.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Text(
            'Items: ${order.items.map((item) => item.productName).join(', ')}',
            style: theme.textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${formatPrice(order.totalAmount)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: () => Get.toNamed(AppRoutes.orderDetails, arguments: order),
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
