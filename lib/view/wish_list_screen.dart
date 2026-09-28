import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/cart_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../Utils/app_colors.dart';
import '../models/product.dart';
import '../widgets/state_views.dart';
import '../widgets/product_image.dart';
import '../widgets/app_toast.dart';

/// Saved-items list, matching the mockup's Wishlist tab: a count badge,
/// a card per item with Move-to-Cart / Remove actions, and an empty state
/// with a heart icon and an "Explore Products" CTA into Shopping.
class WishlistTab extends StatelessWidget {
  const WishlistTab({super.key});

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wishlistController = WishlistController.instance;
    final cartController = CartController.instance;

    if (wishlistController.wishlistItems.isEmpty && !wishlistController.isLoading.value) {
      wishlistController.fetchWishlistItems();
    }

    return Obx(() {
      final items = wishlistController.wishlistItems;
      final hasItems = items.isNotEmpty;
      final loading = wishlistController.isLoading.value;

      return SafeArea(
        child: loading && items.isEmpty
            ? const LoadingView(asGrid: false)
            : !hasItems
            ? EmptyStateView(
                icon: Icons.favorite_border,
                title: 'Wishlist is empty',
                message: 'Tap the heart icon on any product to save it here.',
                ctaLabel: 'Explore Products',
                onCta: () => MainTabController.instance.goToShopping(),
              )
            : RefreshIndicator(
                onRefresh: wishlistController.fetchWishlistItems,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SAVED ITEMS',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'Your personal wishlist collection',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${items.length} Items',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ...items.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _WishlistRow(
                          product: product,
                          priceLabel: _formatPrice(product.currentPrice),
                          onMoveToCart: () {
                            cartController.addToCart(
                              product: product,
                              selectedSize: product.availableSizes.isNotEmpty
                                  ? product.availableSizes.first
                                  : 'One Size',
                            );
                            wishlistController.removeFromWishlist(product.id);
                            AppToast.show('Moved "${product.name}" to cart');
                          },
                          onRemove: () {
                            wishlistController.removeFromWishlist(product.id);
                            AppToast.show(
                              'Removed from wishlist',
                              onUndo: () => wishlistController.addToWishlist(product),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      );
    });
  }
}

class _WishlistRow extends StatelessWidget {
  const _WishlistRow({
    required this.product,
    required this.priceLabel,
    required this.onMoveToCart,
    required this.onRemove,
  });

  final Product product;
  final String priceLabel;
  final VoidCallback onMoveToCart;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductImage(path: product.imagePath, width: 48, height: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  priceLabel,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onMoveToCart,
            style: TextButton.styleFrom(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Move to Cart', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.coral),
          ),
        ],
      ),
    );
  }
}
