import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controllers/product_controller.dart';
import '../Controllers/wishlist_controller.dart';
import '../Controllers/category_controller.dart';
import '../Controllers/main_tab_controller.dart';
import '../routes/app_routes.dart';
import '../Utils/responsive.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';
import '../widgets/section_header.dart';

/// Home is the discovery/landing experience: a promo banner, category
/// shortcuts, and a couple of curated product rails — every "View All" and
/// category tap hands off to the Shopping tab (see MainTabController),
/// which owns search/filtering/pagination over the full catalog. Home never
/// re-implements that browsing logic itself; it only reads the same
/// storefront feed ProductController already keeps loaded.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final ProductController _productController = ProductController.instance;
  final WishlistController _wishlistController = WishlistController.instance;
  final CategoryController _categoryController = CategoryController.instance;

  static const int _railLimit = 8;

  @override
  void initState() {
    super.initState();
    _productController.fetchStorefrontFirstPage();
  }

  void _navigateToProductDetails(Product product) {
    Get.toNamed(AppRoutes.productDetails, arguments: product);
  }

  /// Newest-first — the storefront feed is already ordered by createdAt
  /// descending (see ProductRepository.fetchProductsPage), so this is a
  /// real "recently added" ordering, not an invented one.
  List<Product> _newArrivals(List<Product> products) => products.take(_railLimit).toList();

  /// Real user ratings only — a product with no reviews yet contributes no
  /// signal here rather than being ranked by a meaningless default rating,
  /// and the section itself is hidden below if nothing qualifies (see
  /// Phase 15/"no fake analytics" in the demo-readiness brief this follows).
  List<Product> _popular(List<Product> products) {
    final rated = products.where((p) => p.reviewCount > 0).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return rated.take(_railLimit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Obx(() {
      final products = _productController.publishedStorefrontProducts;
      final isLoading = _productController.isLoading.value;
      final error = _productController.errorMessage.value;
      final categories = _categoryController.categoryNames;
      final newArrivals = _newArrivals(products);
      final popular = _popular(products);

      return RefreshIndicator(
        onRefresh: _productController.fetchStorefrontFirstPage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.isDesktop(context) ? 32 : 16,
            vertical: 16,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Responsive.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero / promo banner
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Get Your', style: TextStyle(color: Colors.white, fontSize: 16)),
                          Text(
                            'Special Sale',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                          Text('Up to 40%', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () => MainTabController.instance.goToShopping(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.colorScheme.primary,
                        ),
                        child: const Text('Shop Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                if (categories.isNotEmpty) ...[
                  SectionHeader(
                    title: 'Categories',
                    actionLabel: 'View All',
                    onAction: () => MainTabController.instance.goToShopping(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        return _CategoryTile(
                          label: category,
                          onTap: () => MainTabController.instance.goToShopping(category: category),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                if (isLoading && products.isEmpty)
                  const LoadingView(asGrid: false, itemCount: 3)
                else if (error.isNotEmpty && products.isEmpty)
                  ErrorStateView(
                    message: error,
                    onRetry: _productController.fetchStorefrontFirstPage,
                  )
                else if (products.isEmpty)
                  const EmptyStateView(
                    icon: Icons.storefront_outlined,
                    title: 'No products yet',
                    message: 'Check back soon — new arrivals show up here first.',
                  )
                else ...[
                  _ProductRail(
                    title: 'New Arrivals',
                    products: newArrivals,
                    onSeeAll: () => MainTabController.instance.goToShopping(),
                    onProductTap: _navigateToProductDetails,
                    onToggleWishlist: _wishlistController.toggleWishlist,
                    isWishlisted: _wishlistController.isInWishlist,
                  ),
                  if (popular.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    _ProductRail(
                      title: 'Popular Picks',
                      products: popular,
                      onSeeAll: () => MainTabController.instance.goToShopping(),
                      onProductTap: _navigateToProductDetails,
                      onToggleWishlist: _wishlistController.toggleWishlist,
                      isWishlisted: _wishlistController.isInWishlist,
                    ),
                  ],
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 84,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.title,
    required this.products,
    required this.onSeeAll,
    required this.onProductTap,
    required this.onToggleWishlist,
    required this.isWishlisted,
  });

  final String title;
  final List<Product> products;
  final VoidCallback onSeeAll;
  final void Function(Product) onProductTap;
  final void Function(Product) onToggleWishlist;
  final bool Function(String) isWishlisted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, actionLabel: 'View All', onAction: onSeeAll),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 160,
                child: ProductCard(
                  product: product,
                  onTap: () => onProductTap(product),
                  onToggleWishlist: () => onToggleWishlist(product),
                  isWishlisted: isWishlisted(product.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
