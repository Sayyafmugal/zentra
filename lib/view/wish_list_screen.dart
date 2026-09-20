import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/cart_controller.dart';
import '../models/product.dart';
import '../widgets/state_views.dart';
import '../widgets/product_image.dart';

class WishlistTab extends StatelessWidget {
  const WishlistTab({super.key, this.initialProduct});

  final Product? initialProduct;

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool shouldShowAppBar = ModalRoute.of(context)?.canPop ?? false;
    final wishlistController = WishlistController.instance;
    final cartController = CartController.instance;

    if (initialProduct != null && !wishlistController.isInWishlist(initialProduct!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        wishlistController.addToWishlist(initialProduct!);
      });
    }

    if (wishlistController.wishlistItems.isEmpty && !wishlistController.isLoading.value) {
      wishlistController.fetchWishlistItems();
    }

    return Obx(() {
      final items = wishlistController.wishlistItems;
      final bool hasItems = items.isNotEmpty;
      final loading = wishlistController.isLoading.value;

      return Scaffold(
        appBar: shouldShowAppBar ? AppBar(title: const Text('My Wishlist')) : null,
        body: SafeArea(
          child: loading && items.isEmpty
              ? const LoadingView(asGrid: false)
              : !hasItems
              ? EmptyStateView(
                  icon: Icons.favorite_border,
                  title: 'Your Wishlist is Empty',
                  message: 'Tap the heart icon on any product to save it here for later!',
                  ctaLabel: shouldShowAppBar ? 'Continue Shopping' : null,
                  onCta: shouldShowAppBar ? () => Get.back() : null,
                )
              : RefreshIndicator(
                  onRefresh: wishlistController.fetchWishlistItems,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.favorite, color: theme.colorScheme.primary, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${items.length} saved',
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final product = items[index];
                            return Card(
                              clipBehavior: Clip.antiAlias,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12.0),
                                      child: ProductImage(
                                        path: product.imagePath,
                                        width: 100,
                                        height: 100,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  product.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: theme.textTheme.bodyLarge?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: 'Remove',
                                                onPressed: () => wishlistController
                                                    .removeFromWishlist(product.id),
                                                icon: const Icon(Icons.close),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            product.category,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: theme.hintColor,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Text(
                                                _formatPrice(product.currentPrice),
                                                style: theme.textTheme.bodyLarge?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.primary,
                                                ),
                                              ),
                                              if (product.oldPrice != null) ...[
                                                const SizedBox(width: 8),
                                                Text(
                                                  _formatPrice(product.oldPrice!),
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.hintColor,
                                                    decoration: TextDecoration.lineThrough,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
                                                  onPressed: () => wishlistController
                                                      .removeFromWishlist(product.id),
                                                  icon: const Icon(Icons.delete_outline),
                                                  label: const Text('Remove'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    if (product.availableSizes.isNotEmpty) {
                                                      cartController.addToCart(
                                                        product: product,
                                                        selectedSize: product.availableSizes.first,
                                                        quantity: 1,
                                                      );
                                                      wishlistController.removeFromWishlist(
                                                        product.id,
                                                      );
                                                    }
                                                  },
                                                  icon: const Icon(Icons.shopping_bag_outlined),
                                                  label: const Text('Move to Cart'),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      );
    });
  }
}
