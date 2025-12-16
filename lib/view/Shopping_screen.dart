import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import 'product_model.dart';
import 'Wish_list_screen.dart';
import 'product_details_screen.dart';

class ShoppingTab extends StatefulWidget {
  const ShoppingTab({super.key});

  @override
  State<ShoppingTab> createState() => _ShoppingTabState();
}

class _ShoppingTabState extends State<ShoppingTab> {
  static const Color primaryColor = Color(0xFFFF5200);

  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;

  int _selectedCategoryIdx = 0;

  String _formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

  void _onCategoryTap(int index) {
    setState(() {
      _selectedCategoryIdx = index;
    });
  }

  List<String> _computeCategories(List<Product> products) {
    final set = <String>{};
    for (final p in products) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    final cats = ['All', ...set.toList()..sort()];
    return cats;
  }

  List<Product> _filteredProducts(List<Product> products, String selectedCategory) {
    if (selectedCategory == 'All') return products;
    return products.where((p) => p.category == selectedCategory).toList();
  }

  void _onSearchPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search pressed')),
    );
  }

  void _onFilterPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter pressed')),
    );
  }

  void _onLikePressed(Product product) {
    _wishlistController.toggleWishlist(product);
  }

  void _onProductTapped(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = _productController.products;
      final loading = _productController.isLoading.value;

      // Build categories based on current products (no setState here)
      final categories = _computeCategories(products);
      final clampedIndex =
          categories.isEmpty ? 0 : _selectedCategoryIdx.clamp(0, categories.length - 1);
      final selectedCategory = categories.isEmpty ? 'All' : categories[clampedIndex];
      final filtered = _filteredProducts(products, selectedCategory);

      return SafeArea(
        child: Column(
          children: [
            // Header Row (title + icons)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Shopping',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.black),
                    onPressed: _onSearchPressed,
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.black),
                    onPressed: _onFilterPressed,
                  ),
                ],
              ),
            ),

            // Category chips
            SizedBox(
              height: 48,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final selected = index == clampedIndex;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _onCategoryTap(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? primaryColor : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            if (selected) ...[
                              const Icon(Icons.check, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              categories[index],
                              style: TextStyle(
                                color: selected ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Product Grid
            if (loading && products.isEmpty)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (filtered.isEmpty)
              const Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No products found'),
                  ),
                ),
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return _ProductCard(
                        product: product,
                        onTap: () => _onProductTapped(product),
                        onLike: () => _onLikePressed(product),
                        formatPrice: _formatPrice,
                        isWishlisted:
                            _wishlistController.isInWishlist(product.id),
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

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onLike,
    required this.formatPrice,
    this.isWishlisted = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onLike;
  final String Function(double) formatPrice;
  final bool isWishlisted;

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: Image.asset(
                      product.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 36),
                      ),
                    ),
                  ),
                ),
                if (product.discount != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: primaryColor, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        product.discount!,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onLike,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            isWishlisted ? Icons.favorite : Icons.favorite_border,
                            color: isWishlisted ? Colors.red : Colors.grey,
                            size: 18,
                          ),
                        ),
                    ),
                  ),
                ),
              ],
            ),

            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(product.category, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(formatPrice(product.currentPrice), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (product.oldPrice != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          formatPrice(product.oldPrice!),
                          style: const TextStyle(color: Colors.grey, fontSize: 12, decoration: TextDecoration.lineThrough),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
