import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/cart_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/state_views.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/product_image.dart';

class MyCartScreen extends StatelessWidget {
  const MyCartScreen({super.key});

  String _formatPrice(double v) => '\$${v.toStringAsFixed(2)}';

  void _checkout(CartController cartController) {
    if (cartController.cartItems.isEmpty) {
      return;
    }
    Get.toNamed(
      AppRoutes.checkout,
      arguments: {'items': cartController.cartItems, 'isBuyNow': false},
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = CartController.instance;
    final theme = Theme.of(context);

    if (cartController.cartItems.isEmpty && !cartController.isLoading.value) {
      cartController.fetchCartItems();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        title: const Text('My Cart'),
        centerTitle: false,
      ),
      body: Obx(() {
        if (cartController.isLoading.value && cartController.cartItems.isEmpty) {
          return const LoadingView(asGrid: false);
        }

        if (cartController.cartItems.isEmpty) {
          return const EmptyStateView(
            icon: Icons.shopping_cart_outlined,
            title: 'Your cart is empty',
            message: 'Items you add to your cart will show up here.',
          );
        }

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: cartController.fetchCartItems,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: cartController.cartItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cartController.cartItems[index];
                    return _CartRow(
                      item: item,
                      onRemove: () => cartController.removeFromCart(item.id),
                      onMinus: () =>
                          cartController.updateCartItemQuantity(item.id, item.quantity - 1),
                      onPlus: () =>
                          cartController.updateCartItemQuantity(item.id, item.quantity + 1),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total (${cartController.totalItems} items)',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          _formatPrice(cartController.totalPrice),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 54,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _checkout(cartController),
                        child: const Text('Proceed to Checkout'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _CartRow extends StatelessWidget {
  const _CartRow({
    required this.item,
    required this.onRemove,
    required this.onMinus,
    required this.onPlus,
  });

  final CartItem item;
  final VoidCallback onRemove;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  String _price(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductImage(path: item.product.imagePath, width: 88, height: 88),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.selectedSize}',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 8),
                Text(
                  _price(item.product.currentPrice),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Remove',
          ),
          const SizedBox(width: 4),
          QuantitySelector(quantity: item.quantity, onIncrement: onPlus, onDecrement: onMinus),
        ],
      ),
    );
  }
}
