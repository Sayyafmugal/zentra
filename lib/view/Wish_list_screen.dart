import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/cart_controller.dart';
import 'product_model.dart';

class WishlistTab extends StatelessWidget {
  const WishlistTab({super.key, this.initialProduct});

  final Product? initialProduct;

  static const Color primaryColor = Color(0xFFFF5200);

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final bool shouldShowAppBar = ModalRoute.of(context)?.canPop ?? false;
    final wishlistController = WishlistController.instance;
    final cartController = CartController.instance;

    // Add initial product if provided
    if (initialProduct != null && !wishlistController.isInWishlist(initialProduct!.id)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        wishlistController.addToWishlist(initialProduct!);
      });
    }

    // Fetch wishlist on first load
    if (wishlistController.wishlistItems.isEmpty && !wishlistController.isLoading.value) {
      wishlistController.fetchWishlistItems();
    }

    return Obx(() {
      final items = wishlistController.wishlistItems;
      final bool hasItems = items.isNotEmpty;

      if (wishlistController.isLoading.value && items.isEmpty) {
        return Scaffold(
          appBar: shouldShowAppBar
              ? AppBar(
                  title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  centerTitle: false,
                )
              : null,
          backgroundColor: Colors.white,
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      return Scaffold(
        // Show AppBar only when pushed (prevents duplicate title when used under MainScreen)
        appBar: shouldShowAppBar
            ? AppBar(
                title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.bold)),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                centerTitle: false,
              )
            : null,
        backgroundColor: Colors.white,
        body: SafeArea(
          child: hasItems
              ? Column(
                  children: [
                    // Themed header chip showing count
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.favorite, color: primaryColor, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${items.length} saved',
                                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final product = items[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                            elevation: 0,
                            color: Colors.grey[50],
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12.0),
                                    child: Image.asset(
                                      product.imagePath,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        alignment: Alignment.center,
                                        child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
                                      ),
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
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              tooltip: 'Remove',
                                              onPressed: () {
                                                wishlistController.removeFromWishlist(product.id);
                                              },
                                              icon: const Icon(Icons.close, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(product.category, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text(
                                              _formatPrice(product.currentPrice),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: primaryColor,
                                              ),
                                            ),
                                            if (product.oldPrice != null) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatPrice(product.oldPrice!),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (product.discount != null) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                            child: Text(
                                              product.discount!,
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                        ],
                                        if (product.availableSizes.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          SizedBox(
                                            height: 30,
                                            child: ListView.separated(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: product.availableSizes.length,
                                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                                              itemBuilder: (_, i) {
                                                final size = product.availableSizes[i];
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: Colors.grey.shade300),
                                                  ),
                                                  child: Text(size, style: const TextStyle(fontSize: 12)),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: OutlinedButton.icon(
                                                onPressed: () {
                                                  wishlistController.removeFromWishlist(product.id);
                                                },
                                                style: OutlinedButton.styleFrom(
                                                  side: BorderSide(color: Colors.grey.shade300),
                                                  foregroundColor: Colors.black87,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
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
                                                    wishlistController.removeFromWishlist(product.id);
                                                  } else {
                                                    Get.snackbar('Error', 'No sizes available');
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                ),
                                                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                                                label: const Text('Move to Cart', style: TextStyle(color: Colors.white)),
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
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite, size: 40, color: primaryColor),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Your Wishlist is Empty',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tap the heart icon on any product to save it here for later!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                            ),
                            child: const Text(
                              'Continue Shopping',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      );
    });
  }
}
