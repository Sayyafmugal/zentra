import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import 'product_details_screen.dart';
import 'product_model.dart';
import 'wish_list_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  static const Color primaryColor = Color(0xFFFF5200);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  static const Color primaryColor = HomeTab.primaryColor;

  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;

  String _selectedCategory = 'All';

  List<String> _buildCategories(List<Product> products) {
    final cats = <String>{};
    for (final p in products) {
      if (p.category.isNotEmpty) {
        cats.add(p.category);
      }
    }
    return ['All', ...cats.toList()..sort()];
  }

  List<Product> _filtered(List<Product> products) {
    if (_selectedCategory == 'All') return products;
    return products.where((p) => p.category == _selectedCategory).toList();
  }

  // Navigate to details
  void _navigateToProductDetails(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  // Add to wishlist
  void _toggleFavorite(BuildContext context, Product product) {
    _wishlistController.toggleWishlist(product);
  }

  // Category button widget
  Widget _buildCategoryButton(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedCategory = text;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primaryColor : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      ),
    );
  }

  // Product card
  Widget _buildProductCard(BuildContext context, Product product) {
    String formatPrice(double price) => '\$${price.toStringAsFixed(2)}';

    return GestureDetector(
      onTap: () => _navigateToProductDetails(context, product),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        elevation: 0,
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                  child: Image.asset(
                    product.imagePath,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 36),
                      ),
                    ),
                  ),
                  if (product.discount != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          product.discount!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
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
                        onTap: () => _toggleFavorite(context, product),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            _wishlistController.isInWishlist(product.id)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _wishlistController.isInWishlist(product.id)
                                ? Colors.red
                                : Colors.grey,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(product.category,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(formatPrice(product.currentPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor)),
                  if (product.oldPrice != null) ...[
                    const SizedBox(width: 8),
                    Text(formatPrice(product.oldPrice!),
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build method
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = _productController.products;
      final isLoading = _productController.isLoading.value;
      final categories = _buildCategories(products);
      final filtered = _filtered(products);

      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: primaryColor, borderRadius: BorderRadius.circular(12)),
                    child: IconButton(
                      icon: const Icon(Icons.filter_list, color: Colors.white),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Buttons
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: categories
                      .map((cat) => _buildCategoryButton(
                          cat, _selectedCategory == cat))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Banner
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get Your',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text('Special Sale',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24)),
                        Text('Up to 40%',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      child: const Text('Shop Now',
                          style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Products section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Products',
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  TextButton(
                      onPressed: () {},
                      child: const Text('See All',
                          style:
                          TextStyle(color: primaryColor, fontSize: 16))),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading && products.isEmpty)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No products found'),
                  ),
                )
              else
                GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                  children: filtered
                      .map((product) => _buildProductCard(context, product))
                      .toList(),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    });
  }
}
