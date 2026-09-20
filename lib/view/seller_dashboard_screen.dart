import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/auth_controller.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/user_profile_controller.dart';
import '../models/order.dart';
import '../routes/app_routes.dart';
import '../widgets/product_image.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  late final String _sellerId;

  @override
  void initState() {
    super.initState();
    _sellerId = UserProfileController.instance.currentUserId ?? '';
    OrderController.instance.fetchSellerOrders(_sellerId);
    // The customer storefront pages through products in small batches (see
    // ProductController.fetchStorefrontFirstPage), so a seller's own product
    // list needs its own explicit fetch of the full catalog to filter from.
    ProductController.instance.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    final productController = ProductController.instance;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Seller Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Orders'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Logout',
              icon: const Icon(Icons.logout),
              onPressed: () => AuthController.instance.logout(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ProductsTab(sellerId: _sellerId, productController: productController),
            _OrdersTab(sellerId: _sellerId),
          ],
        ),
      ),
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.sellerId, required this.productController});

  final String sellerId;
  final ProductController productController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      final myProducts = productController.products.where((p) => p.sellerId == sellerId).toList();
      final published = myProducts.where((p) => p.isPublished).length;
      final pending = myProducts.where((p) => p.status == ProductStatus.pendingApproval).length;

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Published',
                    value: '$published',
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Pending Review',
                    value: '$pending',
                    icon: Icons.hourglass_top_outlined,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.addProduct),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'My Products',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: myProducts.isEmpty
                  ? Center(
                      child: Text(
                        'You haven\'t listed any products yet.',
                        style: TextStyle(color: theme.hintColor),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: productController.fetchProducts,
                      child: ListView.separated(
                        itemCount: myProducts.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = myProducts[index];
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ProductImage(path: product.imagePath, width: 44, height: 44),
                            ),
                            title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text(
                              '\$${product.currentPrice.toStringAsFixed(2)} · '
                              '${product.stockQuantity ?? "untracked"} in stock',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StatusBadge(status: product.status),
                                IconButton(
                                  tooltip: 'Edit',
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () =>
                                      Get.toNamed(AppRoutes.editProduct, arguments: product),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.sellerId});

  final String sellerId;

  // An order still sitting at pendingPayment hasn't actually been paid for
  // yet, and a cancelled one never will be — neither counts as a real sale.
  // Every other status (paid onward) represents money the seller is owed.
  static const _excludedFromStats = {OrderStatus.pendingPayment, OrderStatus.cancelled};

  @override
  Widget build(BuildContext context) {
    final orderController = OrderController.instance;
    final theme = Theme.of(context);

    return Obx(() {
      final orders = orderController.sellerOrders;
      if (orderController.isLoading.value && orders.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      if (orders.isEmpty) {
        return Center(
          child: Text('No orders yet.', style: TextStyle(color: theme.hintColor)),
        );
      }

      final countedOrders = orders.where((o) => !_excludedFromStats.contains(o.status));
      final orderCount = countedOrders.length;
      final revenue = countedOrders.fold<double>(
        0.0,
        (sum, o) => sum + o.itemsForSeller(sellerId).fold(0.0, (s, i) => s + i.subtotal),
      );

      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Orders',
                    value: '$orderCount',
                    icon: Icons.receipt_long_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Revenue',
                    value: '\$${revenue.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => orderController.fetchSellerOrders(sellerId),
                child: ListView.separated(
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _SellerOrderCard(order: order, sellerId: sellerId);
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SellerOrderCard extends StatelessWidget {
  const _SellerOrderCard({required this.order, required this.sellerId});

  final Order order;
  final String sellerId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Only this seller's line items — never the full multi-seller list.
    final myItems = order.itemsForSeller(sellerId);
    final isSingleSellerOrder = order.sellerIds.length == 1;
    final nextOptions = kSellerAllowedOrderTransitions[order.status];
    final nextStatus = (nextOptions != null && nextOptions.isNotEmpty) ? nextOptions.first : null;

    return Container(
      padding: const EdgeInsets.all(14),
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
          for (final item in myItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${item.quantity}× ${item.productName} (${item.selectedSize})',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          if (!isSingleSellerOrder) ...[
            const SizedBox(height: 4),
            Text(
              'This order also includes other sellers\' items — only an admin can change its status.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else if (nextStatus != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => OrderController.instance.updateOrderStatusAsSeller(
                  order.id,
                  nextStatus,
                  sellerId,
                ),
                child: Text('Mark as ${nextStatus.name}'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ProductStatus status;

  Color _color() {
    switch (status) {
      case ProductStatus.pendingApproval:
        return Colors.orange;
      case ProductStatus.draft:
        return Colors.grey;
      case ProductStatus.rejected:
        return Colors.red;
      case ProductStatus.archived:
        return Colors.blueGrey;
      case ProductStatus.outOfStock:
        return Colors.brown;
      case ProductStatus.published:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.name,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
