import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/order_controller.dart';
import '../Controllers/auth_controller.dart';
import '../Controllers/seller_controller.dart';
import '../Controllers/category_controller.dart';
import '../Controllers/coupon_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/product_image.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _sellerController = SellerController.instance;
  final _categoryController = CategoryController.instance;
  final _orderController = OrderController.instance;
  final _couponController = CouponController.instance;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  void _fetchAll() {
    _sellerController.fetchPendingApplications();
    _sellerController.fetchAllSellers();
    // The customer storefront pages through products in small batches (see
    // ProductController.fetchStorefrontFirstPage), so the admin's full
    // catalog view needs its own explicit fetch of everything it manages.
    ProductController.instance.fetchProducts();
    // OrderController.orders is always scoped to the signed-in user's own
    // order history — that's the wrong number for a platform stat card, so
    // these fetch the real, platform-wide data separately.
    _orderController.fetchPlatformOrderCount();
    _orderController.fetchAllOrders();
    _categoryController.fetchCategories();
    _couponController.fetchAllCoupons();
  }

  static int _responsiveColumns(double width, double minTileWidth) =>
      (width / minTileWidth).floor().clamp(2, 4);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productController = ProductController.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => AuthController.instance.logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchAll(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final statColumns = _responsiveColumns(constraints.maxWidth, 240);
            final actionColumns = _responsiveColumns(constraints.maxWidth, 200);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Overview',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    // Summary cards
                    Obx(() {
                      final totalProducts = productController.products.length;
                      final totalOrders = _orderController.platformOrderCount.value;
                      final pendingApplications = _sellerController.pendingApplications.length;
                      final activeCoupons = _couponController.coupons
                          .where((c) => c.isCurrentlyValid)
                          .length;

                      return GridView.count(
                        crossAxisCount: statColumns,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.6,
                        children: [
                          _StatCard(
                            title: 'Products',
                            value: '$totalProducts',
                            icon: Icons.shopping_bag_outlined,
                            color: Colors.blue,
                            onTap: () => _showManageProductsSheet(context, productController),
                          ),
                          _StatCard(
                            title: 'Orders',
                            value: '$totalOrders',
                            icon: Icons.receipt_long_outlined,
                            color: Colors.green,
                            onTap: () => _showManageOrdersSheet(context, _orderController),
                          ),
                          _StatCard(
                            title: 'Seller Apps',
                            value: '$pendingApplications',
                            icon: Icons.person_add_alt_outlined,
                            color: Colors.orange,
                            onTap: () => _showSellerApplicationsSheet(context, _sellerController),
                          ),
                          _StatCard(
                            title: 'Active Coupons',
                            value: '$activeCoupons',
                            icon: Icons.local_offer_outlined,
                            color: Colors.purple,
                            onTap: () => _showManageCouponsSheet(context, _couponController),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 28),
                    Text(
                      'Quick Actions',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: actionColumns,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _ActionTile(
                          icon: Icons.add_circle_outline,
                          label: 'Add Product',
                          onTap: () => Get.toNamed(AppRoutes.addProduct),
                        ),
                        _ActionTile(
                          icon: Icons.edit_outlined,
                          label: 'Manage Products',
                          onTap: () => _showManageProductsSheet(context, productController),
                        ),
                        _ActionTile(
                          icon: Icons.receipt_long_outlined,
                          label: 'Manage Orders',
                          onTap: () => _showManageOrdersSheet(context, _orderController),
                        ),
                        Obx(() {
                          final count = _sellerController.pendingApplications.length;
                          return _ActionTile(
                            icon: Icons.storefront_outlined,
                            label: 'Seller Applications',
                            badge: count > 0 ? '$count' : null,
                            onTap: () => _showSellerApplicationsSheet(context, _sellerController),
                          );
                        }),
                        _ActionTile(
                          icon: Icons.storefront,
                          label: 'Manage Sellers',
                          onTap: () => _showManageSellersSheet(context, _sellerController),
                        ),
                        _ActionTile(
                          icon: Icons.category_outlined,
                          label: 'Manage Categories',
                          onTap: () => _showManageCategoriesSheet(context, _categoryController),
                        ),
                        _ActionTile(
                          icon: Icons.local_offer_outlined,
                          label: 'Manage Coupons',
                          onTap: () => _showManageCouponsSheet(context, _couponController),
                        ),
                        _ActionTile(
                          icon: Icons.history,
                          label: 'Audit Log',
                          onTap: () => Get.toNamed(AppRoutes.auditLog),
                        ),
                      ],
                    ),

                    Obx(() {
                      final needsProductSeed = productController.products.isEmpty;
                      final needsCategorySeed = _categoryController.categories.isEmpty;
                      if (!needsProductSeed && !needsCategorySeed) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(top: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Getting Started',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (needsCategorySeed)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _categoryController.seedDefaultCategories(),
                                    icon: const Icon(Icons.auto_awesome_outlined),
                                    label: const Text('Seed default categories'),
                                  ),
                                ),
                              ),
                            if (needsProductSeed)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => productController.seedDemoCatalog(),
                                  icon: const Icon(Icons.auto_awesome_outlined),
                                  label: const Text('Seed sample catalog data'),
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showSellerApplicationsSheet(BuildContext context, SellerController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final applications = controller.pendingApplications;
              if (applications.isEmpty) {
                return const Center(child: Text('No pending seller applications.'));
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: applications.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final application = applications[index];
                  return _SellerApplicationCard(application: application, controller: controller);
                },
              );
            });
          },
        );
      },
    );
  }

  void _showManageSellersSheet(BuildContext context, SellerController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final sellers = controller.allSellers;
              if (sellers.isEmpty) {
                return const Center(child: Text('No approved sellers yet.'));
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: sellers.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  return _SellerManagementCard(seller: sellers[index], controller: controller);
                },
              );
            });
          },
        );
      },
    );
  }

  void _showManageCategoriesSheet(BuildContext context, CategoryController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCategoryDialog(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Category'),
                    ),
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final categories = controller.categories;
                    if (categories.isEmpty) {
                      return const Center(child: Text('No categories yet.'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return ListTile(
                          title: Text(category.name),
                          trailing: IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Delete category?'),
                                  content: Text(
                                    '"${category.name}" will no longer be selectable for new '
                                    'products. Existing products keep their category unchanged.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogContext, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      onPressed: () => Navigator.pop(dialogContext, true),
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await controller.deleteCategory(category.id);
                              }
                            },
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCategoryDialog(BuildContext context, CategoryController controller) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Sportswear'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await controller.createCategory(nameCtrl.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showManageProductsSheet(BuildContext context, ProductController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Obx(() {
              final products = controller.products;
              if (products.isEmpty) {
                return const Center(child: Text('No products yet.'));
              }
              return ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: products.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final product = products[index];
                  final needsReview = product.status == ProductStatus.pendingApproval;
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ProductImage(path: product.imagePath, width: 44, height: 44),
                    ),
                    title: Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${product.currentPrice.toStringAsFixed(2)} · ${product.category}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.status != ProductStatus.published) ...[
                          const SizedBox(width: 6),
                          _StatusChip(status: product.status),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (needsReview) ...[
                          IconButton(
                            tooltip: 'Approve',
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                            onPressed: () =>
                                controller.updateProductStatus(product.id, ProductStatus.published),
                          ),
                          IconButton(
                            tooltip: 'Reject',
                            icon: const Icon(Icons.cancel_outlined, color: Colors.orange),
                            onPressed: () =>
                                controller.updateProductStatus(product.id, ProductStatus.rejected),
                          ),
                        ],
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => Get.toNamed(AppRoutes.editProduct, arguments: product),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Delete product?'),
                                content: Text('This will permanently remove "${product.name}".'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                    onPressed: () => Navigator.pop(dialogContext, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              await controller.deleteProduct(product.id);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            });
          },
        );
      },
    );
  }

  void _showManageOrdersSheet(BuildContext context, OrderController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return _OrdersManagementView(controller: controller, scrollController: scrollController);
          },
        );
      },
    );
  }

  void _showManageCouponsSheet(BuildContext context, CouponController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Manage Coupons',
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (dialogContext) => _AddCouponDialog(controller: controller),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    final coupons = controller.coupons;
                    if (coupons.isEmpty) {
                      return const Center(child: Text('No coupons yet.'));
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: coupons.length,
                      separatorBuilder: (_, __) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        return _CouponCard(coupon: coupons[index], controller: controller);
                      },
                    );
                  }),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OrdersManagementView extends StatefulWidget {
  const _OrdersManagementView({required this.controller, required this.scrollController});

  final OrderController controller;
  final ScrollController scrollController;

  @override
  State<_OrdersManagementView> createState() => _OrdersManagementViewState();
}

class _OrdersManagementViewState extends State<_OrdersManagementView> {
  OrderStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final all = widget.controller.allOrders;
      final orders = _filter == null ? all : all.where((o) => o.status == _filter).toList();

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Manage Orders',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All (${all.length})',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                const SizedBox(width: 8),
                for (final status in OrderStatus.values) ...[
                  Builder(
                    builder: (context) {
                      final count = all.where((o) => o.status == status).length;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: '${orderStatusLabel(status)} ($count)',
                          selected: _filter == status,
                          onTap: () => setState(() => _filter = status),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('No orders in this view.'))
                : ListView.separated(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      return _OrderManagementCard(order: orders[index], controller: widget.controller);
                    },
                  ),
          ),
        ],
      );
    });
  }
}

class _OrderManagementCard extends StatelessWidget {
  const _OrderManagementCard({required this.order, required this.controller});

  final Order order;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nextOptions = kValidOrderStatusTransitions[order.status] ?? const <OrderStatus>{};
    final itemCount = order.items.fold<int>(0, (sum, item) => sum + item.quantity);

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
            children: [
              Expanded(
                child: Text(
                  '#${order.id.substring(0, order.id.length >= 8 ? 8 : order.id.length)}',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusString,
                  style: TextStyle(color: order.statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$itemCount item${itemCount == 1 ? '' : 's'} · \$${order.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('MMM dd, yyyy · h:mm a').format(order.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.toNamed(AppRoutes.orderDetails, arguments: order),
                  child: const Text('View Details'),
                ),
              ),
              if (nextOptions.isNotEmpty) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: PopupMenuButton<OrderStatus>(
                    onSelected: (status) => controller.updateOrderStatus(order.id, status),
                    itemBuilder: (context) => nextOptions
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Text('Mark as ${orderStatusLabel(status)}'),
                          ),
                        )
                        .toList(),
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Update Status',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Mirrors Order.statusString — needed as a standalone function here because
/// the "Mark as ..." menu must label transition targets that don't
/// necessarily belong to any [Order] instance currently in memory.
String orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pendingPayment:
      return 'Pending Payment';
    case OrderStatus.paid:
      return 'Paid';
    case OrderStatus.processing:
      return 'Processing';
    case OrderStatus.packed:
      return 'Packed';
    case OrderStatus.shipped:
      return 'Shipped';
    case OrderStatus.outForDelivery:
      return 'Out for Delivery';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
    case OrderStatus.returnRequested:
      return 'Return Requested';
    case OrderStatus.returned:
      return 'Returned';
    case OrderStatus.refunded:
      return 'Refunded';
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : theme.textTheme.bodyMedium?.color,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.coupon, required this.controller});

  final Coupon coupon;
  final CouponController controller;

  String get _valueLabel => coupon.type == CouponType.percentage
      ? '${coupon.value.toStringAsFixed(0)}% off'
      : '\$${coupon.value.toStringAsFixed(2)} off';

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete coupon?'),
        content: Text('"${coupon.id}" will no longer be redeemable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteCoupon(coupon.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = <String>[
      if (coupon.minOrderAmount > 0) 'Min order \$${coupon.minOrderAmount.toStringAsFixed(2)}',
      if (coupon.maxDiscount != null) 'Max \$${coupon.maxDiscount!.toStringAsFixed(2)}',
      if (coupon.expiresAt != null) 'Expires ${DateFormat('MMM dd, yyyy').format(coupon.expiresAt!)}',
      coupon.usageLimit != null
          ? 'Used ${coupon.usedCount}/${coupon.usageLimit}'
          : 'Used ${coupon.usedCount} times',
    ];

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
            children: [
              Expanded(
                child: Text(
                  coupon.id,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Switch(
                value: coupon.isActive,
                onChanged: (value) => controller.setActive(coupon.id, value),
              ),
            ],
          ),
          Text(
            _valueLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details.join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (coupon.isExpired || coupon.isExhausted) ...[
            const SizedBox(height: 4),
            Text(
              coupon.isExpired ? 'Expired' : 'Usage limit reached',
              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _confirmDelete(context),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCouponDialog extends StatefulWidget {
  const _AddCouponDialog({required this.controller});

  final CouponController controller;

  @override
  State<_AddCouponDialog> createState() => _AddCouponDialogState();
}

class _AddCouponDialogState extends State<_AddCouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxDiscountCtrl = TextEditingController();
  final _usageLimitCtrl = TextEditingController();
  CouponType _type = CouponType.percentage;
  DateTime? _expiresAt;
  bool _isSaving = false;
  String? _errorText;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _usageLimitCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final normalizedCode = Coupon.normalize(_codeCtrl.text);
    if (widget.controller.coupons.any((c) => c.id == normalizedCode)) {
      setState(() => _errorText = 'A coupon with this code already exists.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final coupon = Coupon(
      id: normalizedCode,
      type: _type,
      value: double.parse(_valueCtrl.text),
      minOrderAmount: double.tryParse(_minOrderCtrl.text) ?? 0,
      maxDiscount: _type == CouponType.percentage && _maxDiscountCtrl.text.trim().isNotEmpty
          ? double.tryParse(_maxDiscountCtrl.text)
          : null,
      expiresAt: _expiresAt,
      usageLimit: _usageLimitCtrl.text.trim().isNotEmpty ? int.tryParse(_usageLimitCtrl.text) : null,
      createdAt: DateTime.now(),
    );

    final error = await widget.controller.createCoupon(coupon);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      setState(() => _errorText = error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Coupon'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(labelText: 'Code (e.g. SAVE20)'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Code is required' : null,
                ),
                const SizedBox(height: 12),
                SegmentedButton<CouponType>(
                  segments: const [
                    ButtonSegment(value: CouponType.percentage, label: Text('% Off')),
                    ButtonSegment(value: CouponType.fixed, label: Text('\$ Off')),
                  ],
                  selected: {_type},
                  onSelectionChanged: (selection) => setState(() => _type = selection.first),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valueCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: _type == CouponType.percentage ? 'Percentage (0-100)' : 'Amount off (\$)',
                  ),
                  validator: (v) {
                    final value = double.tryParse(v ?? '');
                    if (value == null || value <= 0) return 'Enter a valid amount';
                    if (_type == CouponType.percentage && value > 100) return 'Must be 100 or less';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minOrderCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Minimum order amount (optional)'),
                ),
                if (_type == CouponType.percentage) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _maxDiscountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Max discount cap (optional)'),
                  ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usageLimitCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Usage limit (optional, blank = unlimited)',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _expiresAt == null
                            ? 'No expiry date'
                            : 'Expires ${DateFormat('MMM dd, yyyy').format(_expiresAt!)}',
                      ),
                    ),
                    TextButton(onPressed: _pickExpiry, child: const Text('Pick date')),
                    if (_expiresAt != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expiresAt = null),
                      ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add'),
        ),
      ],
    );
  }
}

class _SellerApplicationCard extends StatelessWidget {
  const _SellerApplicationCard({required this.application, required this.controller});

  final SellerApplication application;
  final SellerController controller;

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
          Text(
            application.businessName,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(application.businessDescription, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(
            '${application.contactEmail} · ${application.contactPhone}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    await controller.rejectApplication(application);
                  },
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await controller.approveApplication(application);
                  },
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerManagementCard extends StatelessWidget {
  const _SellerManagementCard({required this.seller, required this.controller});

  final Seller seller;
  final SellerController controller;

  Future<void> _confirmSuspend(BuildContext context) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Suspend seller?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${seller.businessName} will immediately lose the ability to list or edit products.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Suspend', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final reason = reasonController.text.trim();
      await controller.suspendSeller(seller.id, reason: reason.isEmpty ? null : reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isActive = seller.isActive;
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
            children: [
              Expanded(
                child: Text(
                  seller.businessName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.red).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Suspended',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${seller.contactEmail} · ${seller.contactPhone}',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
          if (!isActive && seller.suspensionReason != null) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${seller.suspensionReason}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: isActive
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _confirmSuspend(context),
                    child: const Text('Suspend'),
                  )
                : ElevatedButton(
                    onPressed: () async {
                      await controller.reactivateSeller(seller.id);
                    },
                    child: const Text('Reactivate'),
                  ),
          ),
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
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.badge});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: theme.colorScheme.primary, size: 26),
                  const SizedBox(height: 10),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              if (badge != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

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

  String _label() {
    switch (status) {
      case ProductStatus.pendingApproval:
        return 'Pending';
      case ProductStatus.draft:
        return 'Draft';
      case ProductStatus.rejected:
        return 'Rejected';
      case ProductStatus.archived:
        return 'Archived';
      case ProductStatus.outOfStock:
        return 'Out of Stock';
      case ProductStatus.published:
        return 'Published';
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
        _label(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
